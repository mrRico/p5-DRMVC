package Plack::App::DRMVC;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Plack::Component);

use Carp;
use Config::Tiny;
use Module::Pluggable;
use Module::Load;
use Router::PathInfo;

use Plack::App::DRMVC::ExceptionManager;
use Plack::Util::Accessor qw(ini_conf);

my $self = undef;
sub instance {$self}

sub mk_env_accessors {
    my $class = shift;
    return if (not @_ or @_ % 2);
    my %meth  = @_;
    no strict 'refs';
    foreach my $name (keys %meth) {
        *{$package.'::'.$name} = sub {
        	return $_[0]->instance->env->{$meth{$name}} if @_ == 1;
            return $_[0]->instance->env->{$meth{$name}}  = @_ == 2 ? $_[1] : [ @_[1..$#_] ];
        };
    }
    use strict 'refs';
}

sub new {
    $DB::signal = 1;
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    
    # load config    
    my $cnf = Config::Tiny->read(delete $param->{conf_path});
    croak "'conf_path'can't loaded" unless $cnf;
    
    # create object
    my $self = $class->SUPER::new(ini_conf => $cnf);

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
    # custom exception
    Module::Pluggable->import(search_path => [$self->ini_conf->{_}->{app_name}.'::HttpExceptions'], sub_name => '_plu');
    for (__PACKAGE__->_plu) {
        load $_;
        $self->{__exception_manager}->_add_exception($_) if $_->isa('Plack::App::DRMVC::Base::Exception');
    };
    
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
	    Module::Pluggable->import(search_path => [$self->ini_conf->{mvc}->{$x.'.namespace'}], sub_name => '_plu');
	    for (__PACKAGE__->_plu) {
	        load $_;
	        if ($_ ne 'model' and not $_->isa('Plack::App::DRMVC::Base::'.ucfirst $_)) {
	        	# we haven't base class for model
	        	carp "$x '$_' isn't Plack::App::DRMVC::Base::".ucfirst $_." child. skip";
	        	next;
	        }
	        my $ns = $self->ini_conf->{mvc}->{$x.'.namespace'}.'::';
	        (my $shot_name = $_) =~ s/^$ns//;
	        
	        # add shot_name as method to class (знание о том, какое место в неймспейсе занимет этот класс в приложении важно для собственной идентификации)
	        no strict 'refs';
                *{"${_}::__short_name"} = sub {$shot_name};
            use strict 'refs';
	        
	        my $meth = '_add_'.$x;
	        $self->{__dispatcher}->$meth($_);
	    };
    }
    
    my $app_class = $self->ini_conf->{_}->{app_name};
    load $app_class;
    croak "'$app_class' doesn't have parent 'Plack::App::DRMVC::Base::Application'" unless $app_class->isa('Plack::App::DRMVC::Base::Application');
    $self->{__app_class} = $app_class;
    
    return $self;
}

sub ini_conf    {$_[0]->{__ini_conf}}
sub disp        {$_[0]->{__dispatcher}}
sub app_class   {$_[0]->{__app_class}}
sub exception   {$_[0]->{__exception_manager}}
sub router      {$_[0]->{__router}}

sub env         {$_[0]->{env}} # this is important for middleware to access CLASS->instance->env
# only on demand
sub match       {$_[0]->{match} ||= $self->router->match($self->env)}
sub req         {$_[0]->{req}   ||= $self->{__request_package}->new($self->env)}
sub res         {$_[0]->{req}   ||= $self->{__response_package}->new}
sub stash       {$_[0]->{stash} ||= {}}


sub call {
      my $self     = shift;
      $self->{env} = shift;
      eval {
          $self->disp->process;
      };
      if ($@) {
          $self->exception(ref $@ ? $@ : '__500');
      };
      # clear all reqest-dependence attributes
      my $res = $self->res;
      $self->{$_} = undef for grep {/^__/} keys %$self;
      return $res->finalize;
}


1;
__END__
