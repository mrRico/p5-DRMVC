package DRMVC::Config;
use strict;
use warnings;

use Carp;
use File::Spec;
use base qw(Config::Mini);

my $instance = undef;
sub instance { $instance }

sub section {
    my $self = shift;
    # Config::Mini return undefine value on unexists key in config
    my @ret = $self->SUPER::section(@_);
    if (@_ and not defined $ret[0]) {
        my $val = {};
        $self->{$_[0]} = $val;
        return $val;
    } else {
        return @ret; 
    };
}

sub add {
    my ($self, $section, $key, $val) = @_;
    my $s = $self->section($section);
    $s->{$key} = $val;
    unshift @{$s->{'__'.$key}}, $val; 
    return 1;
}

sub get {
    my ($self, $section, $key, $default) = @_;
    my $ret = $self->_get_set($section, $key);
    return (defined $default and not defined $ret) ? $default : $ret; 
}

sub getset {
    my $self = shift;
    return $self->_get_set(@_);
}

sub _get_set {
    my ($self, $section, $key, $default) = @_;
    my $s = $self->section($section);
    my $ret = $s->{$key};
    if (not defined $ret and defined $default) {
        $self->add($section, $key, $default);
        $ret = $default;
    }
    return $ret;
}

sub new {
    my $class = shift;
    my $cnf_file = shift || '';
    $instance = $class->SUPER::new($cnf_file);
    unless ($instance) {
        carp "file '$cnf_file' can't loaded";
        return;
    };
    
#    # important check
#    my $path = $instance->section('general')->{'path'};
#    my $data_path   = $instance->getset('data', 'dir', File::Spec->catdir($path, 'data'));
#    my $log_path    = $instance->getset('logger', 'dir', File::Spec->catdir($path, 'logger'));
#    for ($data_path, $log_path) {
#        unless (-e $_ and -d _) {
#            unless (mkdir $_) {
#                carp "$_ has error: $!";
#                return;
#            }
#        };
#    }
    
    return 1;
}


1;
__END__

# MANIFEST
