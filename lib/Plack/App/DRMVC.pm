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
    unless ($self->{__request_package} and UNIVERSAL::isa($self->{__request_package},'Plack::Request')) {
        carp "'$self->{__request_package}' isn't Plack::Request child. Plack::Request set as default class for request";
        $self->{__request_package} = 'Plack::Request';
        load $self->{__request_package};
    };
    # custom response package
    $self->{__response_package} = $self->conf->{_}->{app_name}.'::Extend::Response';
    load $self->{__response_package};
    unless (UNIVERSAL::isa($self->{__response_package},'Plack::Response')) {
    	carp "'$self->{__response_package}' isn't Plack::Response child. Plack::Response set as default class for response";
        $self->{__response_package} = 'Plack::Response';
        load $self->{__response_package};
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
    unless (UNIVERSAL::isa($dispatcher_package,'Plack::App::DRMVC::Base::Dispatcher')) {
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
	        if ($_ ne 'model' and not UNIVERSAL::isa($_,'Plack::App::DRMVC::Base::'.ucfirst $_)) {
	        	# we haven't base class for model
	        	carp "$x '$_' isn't Plack::App::DRMVC::Base::".ucfirst $_." child. skip";
	        	next;
	        }
	        my $ns = $self->conf->{mvc}->{$x.'.namespace'}.'::';
	        (my $shot_name = $_) =~ s/^$ns//;
	        my $meth = '_add_'.$x;
	        $self->{__dispatcher}->$meth($shot_name, $_);
	    };
    }
   
    
    
    
    return $self;
}

sub conf {$_[0]->{conf}}


sub call {
      my ($self, $env) = @_;
      
      $DB::signal = 1;
      
      return [
          '200',
          [ 'Content-Type' => 'text/plain' ],
          [ "Hello World" ], # or IO::Handle-like object
      ];
}


1;
__END__
