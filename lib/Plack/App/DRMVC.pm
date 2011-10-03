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

my $self = undef;
sub instance {$self}

sub new {
    $DB::signal = 1;
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    
    # load config    
    my $cnf = Config::Tiny->read(delete $param->{conf_path});
    croak "'conf_path'can't loaded" unless $cnf;
    
    # create object
    my $self = $class->SUPER::new(conf => $cnf);

    # custom request package
    $self->{__request_package} = $self->conf->{_}->{app_name}.'::Extend::Request';
    load $self->{__request_package};
    unless ($self->{__request_package}->isa('Plack::Request')) {
        carp "'$self->{__request_package}' isn't Plack::Request child. Plack::Request set as default class for request";
        $self->{__request_package} = 'Plack::Request';
        load $self->{__request_package};
    };
    # custom response package
    $self->{__response_package} = $self->conf->{_}->{app_name}.'::Extend::Response';
    load $self->{__response_package};
    unless ($self->{__response_package}->isa('Plack::Response')) {
    	carp "'$self->{__response_package}' isn't Plack::Response child. Plack::Response set as default class for response";
        $self->{__response_package} = 'Plack::Response';
        load $self->{__response_package};
    };
    
    # custom exception
    $self->{__exception_manager} = Plack::App::DRMVC::ExceptionManager->new();
    # custom exception
    Module::Pluggable->import(search_path => [$self->conf->{_}->{app_name}.'::HttpExceptions'], sub_name => '_plu');
    for (__PACKAGE__->_plu) {
        load $_;
        $self->{__exception_manager}->_add_exception($_) if $_->isa('Plack::App::DRMVC::Base::Exception');
    };
    
    # router
    $self->{__router} = Router::PathInfo->new(
        static => {
            allready => {
                path => $self->conf->{router}->{'static.allready.path'},
                first_uri_segment => $self->conf->{router}->{'static.allready.first_uri_segment'}
            },
            on_demand => {
                path => $self->conf->{router}->{'static.on_demand.path'},
                first_uri_segment => $self->conf->{router}->{'static.on_demand.first_uri_segment'}
            },
        }
    );

    # dispatcher
    my $dispatcher_package = $self->conf->{_}->{app_name}.'::Extend::Dispatcher';
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
	    Module::Pluggable->import(search_path => [$self->conf->{mvc}->{$x.'.namespace'}], sub_name => '_plu');
	    for (__PACKAGE__->_plu) {
	        load $_;
	        if ($_ ne 'model' and not $_->isa('Plack::App::DRMVC::Base::'.ucfirst $_)) {
	        	# we haven't base class for model
	        	carp "$x '$_' isn't Plack::App::DRMVC::Base::".ucfirst $_." child. skip";
	        	next;
	        }
	        my $ns = $self->conf->{mvc}->{$x.'.namespace'}.'::';
	        (my $shot_name = $_) =~ s/^$ns//;
	        
	        # add shot_name as method to class (знание о том, какое место в неймспейсе занимет этот класс в приложении важно для собственной идентификации)
	        no strict 'refs';
                *{"${_}::__short_name"} = sub {$shot_name};
            use strict 'refs';
	        
	        my $meth = '_add_'.$x;
	        $self->{__dispatcher}->$meth($_);
	    };
    }
    
    my $app_class = $self->conf->{_}->{app_name};
    load $app_class;
    croak "'$app_class' doesn't have parent 'Plack::App::DRMVC::Base::Application'" unless $app_class->isa('Plack::App::DRMVC::Base::Application');
    $self->{__app_class} = $app_class;
    
    return $self;
}

sub conf {$_[0]->{conf}}
sub disp {$_[0]->{__dispatcher}}
sub app_class {$_[0]->{__app_class}}
sub exception   {$_[0]->{__exception_manager}}

#sub init_app {
#    my $self   = shift;
#    my $env    = shift;
#    
#    my $app = $self->app_class->new($env);
#    
#    $singletone->{view} = undef;
#    $singletone->{__bi_res}     = $singletone->{__bi_response_package}->new();
#    if ($singletone->_access->is_denied($env)) {
#        $singletone->{__bi_match} = {
#            type => 'error',
#            code => 403,
#            desc  => 'Global denied access to client with '.join(',', map {$env->{$_} ? $_.'='.$env->{$_} : "$_=undef"} qw(REMOTE_HOST REMOTE_ADDR))
#        };
#    } else {
#        # application is case sensetive
#        # $env->{PATH_INFO} = lc $env->{PATH_INFO};
#        $singletone->{__bi_match}   = $singletone->router->match($env);
#        # check permission
#        if ($singletone->{__bi_match}->{type} eq 'controller') {
#            my $forbidden = 0;
#            my $class      = $singletone->{__bi_match}->{action}->[0];
#            my $sub_name   = $singletone->{__bi_match}->{action}->[1];
#            my $msg;
#            if ($class::_attr->{$sub_name}->{denied}) {
#                for (@{$class::_attr->{$sub_name}->{denied}}) {
#                    if ($singletone->_access->is_denied($env, $_)) {
#                        $forbidden = 1;
#                        $msg = "Access denied to ${class}::$sub_name to client with ".join(',', map {$env->{$_} ? $_.'='.$env->{$_} : "$_=undef"} qw(REMOTE_HOST REMOTE_ADDR));
#                        last;
#                    }
#                }
#            }
#            if (not $forbidden and $class::_attr->{$sub_name}->{allow}) {
#                $forbidden = 1;
#                $msg = "Access not allowed to ${class}::$sub_name for client with ".join(',', map {$env->{$_} ? $_.'='.$env->{$_} : "$_=undef"} qw(REMOTE_HOST REMOTE_ADDR));
#                for ('', @{$class::_attr->{$sub_name}->{allow}}) {
#                    if ($singletone->_access->is_allow($env, $_)) {
#                        $forbidden = 0;
#                        last;
#                    }
#                }
#            }
#            
#            if ($forbidden) {
#                $singletone->{__bi_match} = {
#                    type => 'error',
#                    code => 403,
#                    desc  => $msg
#                };
#            }
#        }
#        
#        # we not needed in request when found match with error type
#        $singletone->{__bi_req}     = $singletone->{__bi_request_package}->new($env) unless $singletone->{__bi_match}->{type} eq 'error';
#        
#        # load session for controller (after request was parsed)
#        # after this, you can $bi->session
#        $singletone->_session_manager->load_session() if $singletone->{__bi_match}->{type} eq 'controller';
#    }
#    
#    return undef;
#}


sub app {$_[0]->{__app}}

sub call {
      my ($self, $env) = @_;
      eval {
          $self->{__app} = $self->app_class->new($env);
          $self->disp->process;
          return $self->app->res->finalize;
      };
      if ($@) {
          $DB::signal = 1;
          return $self->exception->500($@);
      };
}

sub response_cb {
    my $self = shift;
    undef $self->{__app};
}

1;
__END__
