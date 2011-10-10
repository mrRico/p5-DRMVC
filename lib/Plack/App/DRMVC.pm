package Plack::App::DRMVC;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Plack::Component);

use Carp;
use Config::Tiny;
use Module::Util qw();
use Module::Load;
use Router::PathInfo;
use Scalar::Util qw();

# TODO: добавить чейн по простому

use Plack::App::DRMVC::ExceptionManager;
use Plack::App::DRMVC::Logger;

my $self = undef;
sub instance {$self}

# дополняем список методов из хэша запроса
sub mk_env_accessors {
    my $class = shift;
    return if (not @_ or @_ % 2);
    my %meth  = @_;
    # TODO: добавить проверку на наличие метода в классе
    no strict 'refs';
    foreach my $name (keys %meth) {
        *{$class.'::'.$name} = sub {
        	return $_[0]->instance->env->{$meth{$name}} if @_ == 1;
            return $_[0]->instance->env->{$meth{$name}}  = @_ == 2 ? $_[1] : [ @_[1..$#_] ];
        };
    }
    use strict 'refs';
}

sub get_app {
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    # check additional
    $param->{addition} ||= {};

    # load config
    my $cnf = Config::Tiny->read(delete $param->{conf_path});
    croak "'conf_path'can't loaded" unless $cnf;
    
    # load custom application
    my $app_class = $cnf->{_}->{app_name};
    load $app_class;
    croak "'$app_class' doesn't have parent 'Plack::App::DRMVC'" unless $app_class->isa('Plack::App::DRMVC');
    
    # create object
    $self = $app_class->SUPER::new(__ini_conf => $cnf);    
    
    # save namespace our application
    $self->{__app_name_space} = $self->ini_conf->{_}->{app_name};
    
    # custom request package    
    $self->{__request_package} = $self->ini_conf->{_}->{app_name}.'::Extend::Request';
    load $self->{__request_package};
    unless ($self->{__request_package}->isa('Plack::Request')) {
        carp "'$self->{__request_package}' isn't Plack::Request child. Plack::Request set as default class for request";
        $self->{__request_package} = 'Plack::Request';
        load $self->{__request_package};
    };
    # custom response package
    $self->{__response_package} = $self->ini_conf->{_}->{app_name}.'::Extend::Response';
    load $self->{__response_package};
    unless ($self->{__response_package}->isa('Plack::Response')) {
    	carp "'$self->{__response_package}' isn't Plack::Response child. Plack::Response set as default class for response";
        $self->{__response_package} = 'Plack::Response';
        load $self->{__response_package};
    };
    
    # custom exception
    $self->{__exception_manager} = Plack::App::DRMVC::ExceptionManager->new();
    # custom exception override default
    for my $ex_ns ('Plack::App::DRMVC::Exception', $self->ini_conf->{_}->{app_name}.'::HttpExceptions') {
        for (Module::Util::find_in_namespace($ex_ns)) {
            load $_;
            my $ns = $ex_ns.'::';
            (my $shot_name = $_) =~ s/^$ns//;
            $self->{__exception_manager}->_add_exception($_, $shot_name) if $_->isa('Plack::App::DRMVC::Base::Exception');
        };
    }
    
    # router
    $self->{__router} = Router::PathInfo->new(
        static => {
            allready => {
                path => $self->ini_conf->{router}->{'static.allready.path'},
                first_uri_segment => $self->ini_conf->{router}->{'static.allready.first_uri_segment'}
            },
            on_demand => {
                path => $self->ini_conf->{router}->{'static.on_demand.path'},
                first_uri_segment => $self->ini_conf->{router}->{'static.on_demand.first_uri_segment'}
            },
        }
    );

    # dispatcher
    my $dispatcher_package = $self->ini_conf->{_}->{app_name}.'::Extend::Dispatcher';
    load $dispatcher_package;
    unless ($dispatcher_package->isa('Plack::App::DRMVC::Base::Dispatcher')) {
    	carp "'$dispatcher_package' isn't Plack::App::DRMVC::Base::Dispatcher child. Plack::App::DRMVC::Base::Dispatcher set as default class for dispatching";
        $dispatcher_package = 'Plack::App::DRMVC::Base::Dispatcher';
        load $dispatcher_package;
    };
    $self->{__dispatcher} = $dispatcher_package->new();
    
    # we're loading MVC trash now
    # order is very important (you can call model from view and controller in compile time)
    for my $x (qw(model view controller)) {
	    # note: load sortered! important for 'loacal_path' in controller
	    my $ucx = ucfirst $x;
	    for (
	       sort {my @as = split('::', $a); my @bs = split('::', $b); $#as <=> $#bs}
	       (map {/^Plack::App::DRMVC::${ucx}::/ ? $_ : "Plack::App::DRMVC::${ucx}::".$_} @{$param->{addition}->{$x} || []}),
	       Module::Util::find_in_namespace($self->ini_conf->{mvc}->{$x.'.namespace'})
	    ) {
	    	next unless $_;
	        load $_;
	        unless ($_->isa('Plack::App::DRMVC::Base::'.$ucx)) {
	        	# we haven't base class for model
	        	carp "$x '$_' isn't Plack::App::DRMVC::Base::".$ucx." child. It was skipped.";
	        	next;
	        }
	        my $meth = '_add_'.$x;
	        $self->{__dispatcher}->$meth($_);
	    };
    }
    
    return $self;
}

sub ini_conf            {$_[0]->{__ini_conf}}
sub disp                {$_[0]->{__dispatcher}}
sub exception           {shift->exception_manager->make(@_)}
sub exception_manager   {$_[0]->{__exception_manager}}
sub router              {$_[0]->{__router}}
sub app_name_space      {$_[0]->{__app_name_space}}

sub redirect {
    my $self = shift;
    my $url  = shift;
    $self->exception(302, url => $url);
}

sub env         {$_[0]->{env}} # this is important for middleware to access CLASS->instance->env
# only on demand
sub match       {$_[0]->{match} ||= $self->router->match($self->env)}
sub req         {$_[0]->{req}   ||= $self->{__request_package}->new($self->env)}
sub res         {$_[0]->{res}   ||= $self->{__response_package}->new}
sub stash       {$_[0]->{stash} ||= {}}

sub log {
    my $self = shift;
    return $self->env->{'psgix.logger'}->(@_) if $self->env->{'psgix.logger'};
    unless ($self->{__logger}) {
        $self->{__logger} = Plack::App::DRMVC::Logger->new();
    }
    $self->{__logger}->(@_);
    return;
}

sub call {
      my $self     = shift;
      $self->{env} = shift;
      eval {
          $self->disp->process;
      };      
      if ($@) {
          my $ex = $@;
          eval {
              if (not Scalar::Util::blessed($ex) or not $ex->isa('Plack::App::DRMVC::Base::Exception')) {
                  $self->exception->_create(500, error => $ex)->process;
              } else {
                  $ex->process;
              };
          };
          $self->exception_manager->_500($@) if $@;      
      }
      
      # clear all reqest-dependence attributes
      my $res = $self->res;
      # never be
      $self->exception_manager->_500("Try response without response object or response object isn't Plack::Response") if (not Scalar::Util::blessed($res) or not $res->isa('Plack::Response'));
      # flush request-dependence fields      
      $self->{$_} = undef for grep {!/^__/} keys %$self;
      # our response
      return $res->finalize;
}


1;
__END__
