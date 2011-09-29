package Plack::App::DRMVC;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Plack::Component);
# use Plack::Util::Accessor qw(conf_path);

use Carp;
use Config::Tiny;

my $s = undef;
sub instance {$s}

sub new {
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    my $cnf = Config::Tiny->read(delete $param->{conf_path});
    croak "'conf_path'can't loaded" unless $cnf; 
        
    my $self = bless {cnf => $cnf}, $class;
    
    $self = $s;
}

sub cnf {$_[0]->{cnf}}


sub call {
      my $env = shift;
      
      $DB::signal = 1;
      
      return [
          '200',
          [ 'Content-Type' => 'text/plain' ],
          [ "Hello World" ], # or IO::Handle-like object
      ];
}


1;
__END__
