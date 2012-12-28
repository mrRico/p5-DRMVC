package DRMVC;
use strict;
use warnings;

our $VERSION = '0.01_01';

use parent qw(Plack::Component);

=head1 NAME

DRMVC

=head1 DESCRIPTION

DRMVC isn't framework. 

It's only B<D>ispatcher, B<R>outer, B<M>odel, B<V>iew and B<C>ontroller with implementation under L<Plack>.

=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 NOTE

Betta version.

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<Plack>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

use Carp;
use Module::Util qw();
use Module::Load;
use Router::PathInfo;
use Scalar::Util qw();
use File::Spec;

use DRMVC::Config;
use DRMVC::ExceptionManager;
use DRMVC::Util;
use DRMVC::Logger;

my $self = undef;
sub instance {$self}

sub get_app {
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    # check additional
    $param->{addition} ||= {};

    # load config
    my $cnf = DRMVC::Config->new(delete $param->{conf_path});
    croak "'conf_path'can't loaded" unless $cnf;
    
    # load custom application
    my $app_name = $cnf->get('general', 'app_name');
    load $app_name;
    croak "'$app_name' doesn't have parent 'DRMVC'" unless $app_name->isa('DRMVC');
    
    # trick with create object
    $self = $app_name->new(__ini_conf => $cnf);
    
    $self->ini_conf->set('general', 'root_dir', DRMVC::Util::app_dir());
    
    # save namespace our application
    $self->{__app_name_space} = $app_name;
    
    # custom request package    
    $self->{__request_package} = $app_name.'::Extend::Request';
    load $self->{__request_package};
    unless ($self->{__request_package}->isa('Plack::Request')) {
        carp "'$self->{__request_package}' isn't Plack::Request child. Plack::Request set as default class for request";
        $self->{__request_package} = 'Plack::Request';
        load $self->{__request_package};
    };
    # custom response package
    $self->{__response_package} = $app_name.'::Extend::Response';
    load $self->{__response_package};
    unless ($self->{__response_package}->isa('Plack::Response')) {
    	carp "'$self->{__response_package}' isn't Plack::Response child. Plack::Response set as default class for response";
        $self->{__response_package} = 'Plack::Response';
        load $self->{__response_package};
    };
    
    # custom exception
    $self->{__exception_manager} = DRMVC::ExceptionManager->new();
    # custom exception override default
    for (
        # default exception
        (map {'DRMVC::Exception::'.$_} qw(200 302 304 403 404 500)),
        # addition.exception
        (map {'DRMVC::Exception::'.$_} grep {$self->ini_conf->section('addition.exception')->{$_}} keys %{$self->ini_conf->section('addition.exception')} ),
        # custom exception
        Module::Util::find_in_namespace($app_name.'::Exception')
    ) {
        $_ ? load $_ : next;
        (my $shot_name = $_) =~ s/^(DRMVC::Exception::|${app_name}::Exception::)//;
        $self->{__exception_manager}->_add_exception($_, $shot_name) if $_->isa('DRMVC::Base::Exception');
    }
    
    # router
    $self->{__router} = Router::PathInfo->new(
        static => {
            allready => {
                path => 
                    $self->ini_conf->get('router', 'static.allready.path') ||
                    # only folder name exists in conf file
                    File::Spec->catdir(
                        $self->ini_conf->get('general', 'root_dir'), 
                        $self->ini_conf->getset('router', 'static.allready.root_folder', 'static')
                    ),
                first_uri_segment => $self->ini_conf->getset('router', 'static.allready.first_uri_segment', 'static')
            },
            on_demand => {
                path => 
                    $self->ini_conf->get('router', 'static.on_demand.path') || 
                    File::Spec->catdir(
                            $self->ini_conf->get('general', 'root_dir'),
                            $self->ini_conf->getset('router', 'static.on_demand.root_folder', 'on_demand')
                    ),
                first_uri_segment   => $self->ini_conf->getset('router', 'static.on_demand.first_uri_segment', 'on_demand')
            },
        },
        cache_limit => $self->ini_conf->section('router')->{'cache_limit'}
    );

    # dispatcher
    my $dispatcher_package = $app_name.'::Extend::Dispatcher';
    load $dispatcher_package;
    unless ($dispatcher_package->isa('DRMVC::Base::Dispatcher')) {
    	carp "'$dispatcher_package' isn't DRMVC::Base::Dispatcher child. DRMVC::Base::Dispatcher set as default class for dispatching";
        $dispatcher_package = 'DRMVC::Base::Dispatcher';
        load $dispatcher_package;
    };
    $self->{__dispatcher} = $dispatcher_package->new();
    
    # we're loading MVC trash now
    # order is very important (you can call model from view and controller in compile time)
    for my $x (qw(model view controller)) {        
	    # note: load sortered! important for 'loacal_path' in controller
	    my $ucx = ucfirst $x;
	    for my $proto (
	       sort {my @as = split '::', (ref $a || $a); my @bs = split '::', (ref $b || $b); $#as <=> $#bs}
	       # retirve from config
	       (
	           map {
	               if (Scalar::Util::blessed($self->ini_conf->section("addition.${x}.${_}"))) {
	                   $self->ini_conf->section("addition.${x}.${_}");
	               } else {
    	               /^DRMVC::${ucx}::/ ? $_ : "DRMVC::${ucx}::".$_;
	               }
	           } 
	           (
	               grep {$_} map {/addition\.${x}\.(.*)?/ ? $1 : undef} $self->ini_conf->sections
	           )
           ),
           # retrive from namespace
	       map {Module::Util::find_in_namespace($_)} @{$self->ini_conf->section('mvc')->{$x.'.namespace'}}
	    ) {
	    	# из конфиг DRMVC::Config может вернуться объект в секции
	    	next unless $proto;
	    	my $proto_class = undef;
	    	unless (Scalar::Util::blessed($proto)) {
    	    	# $proto is a class
    	        load $proto;
	    	    $proto_class = $proto;
	    	    # задав перменную call_as_class, можем запретить хранение и создание объекта
	    	    # все обращения будут через имя класса
	    	    # актуально, когда модели наследуют друг-друга, как в случае с ObjectDB
	    	    if ($proto_class->can('_call_as_class') and not $proto_class->_call_as_class and $proto_class->can('new')) {
	    	        $proto  = $proto_class->new();
	    	    }
	    	} else {
	    	    # $proto is a object from DRMVC::Config 
	    	    $proto_class = ref $proto;
	    	}
	        unless ($proto_class->isa('DRMVC::Base::'.$ucx)) {
	        	# we haven't base class for model
	        	carp "$x '${proto_class}' isn't DRMVC::Base::".$ucx." child. It was skipped.";
	        	next;
	        }
	        my $meth = '_add_'.$x;
	        $self->{__dispatcher}->$meth($proto_class, $proto);
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

# dispatching between controllers
sub forward {$_[0]->disp->forward($_[1])}
sub detach  {$_[0]->disp->detach($_[1])}
# model access
sub model   {
    my $ret = $_[0]->disp->{m}->{$_[1]};
    if (ref $ret eq 'CODE') {
        $ret = $ret->();
        $_[0]->disp->{m}->{$_[1]} = $ret; 
    }
    return $ret; 
}
# view access
sub view  {
    my $self = shift;
    if (@_) { 
       my $view_class = $self->disp->{v}->{$_[0]};
       $self->{view} = $view_class;
       return 1;
    } else {
        return $self->{view} || $self->disp->{v}->{$self->ini_conf->get('default', 'view', 'TT')};
    }
}

sub env         {$_[0]->{env} || {}} # this is important for middleware to access CLASS->instance->env
# only on demand
sub match       {$_[0]->{match} ||= $self->router->match($self->env)}
sub req         {$_[0]->{req}   ||= $self->{__request_package}->new($self->env)}
sub res         {$_[0]->{res}   ||= $self->{__response_package}->new(200)}
sub stash       {$_[0]->{stash} ||= {}}

sub log {
    my $self = shift;
    $self->env->{'psgix.logger'} ? $self->env->{'psgix.logger'}->(@_) : ($self->{__logger} ||= DRMVC::Logger->new)->(@_); 
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
          if (not Scalar::Util::blessed($ex) or not $ex->isa('DRMVC::Base::Exception')) {
              $self->exception_manager->_create(500, error => $ex)->process;
          } else {
              eval {$ex->process};
              $self->exception_manager->_500($ex.' => '.$@) if $@;
          };
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
