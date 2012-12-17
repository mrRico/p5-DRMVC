package DRMVC::Config;
use strict;
use warnings;

use Carp;
use File::Spec;
use Fcntl;
use base qw(Config::Mini);

$DRMVC::Config::singletone = 0;

my $instance = undef;
sub instance { $instance }

sub section {
    my $self = $DRMVC::Config::singletone ? $_[0]->instance() : $_[0]; shift; 
    # Config::Mini return undefine value on unexists key in config
    my @ret = $self->SUPER::section(@_);
    if (@_ and not defined $ret[0]) {
        my $val = {};
        $self->{$_[0]} = $val;
        return $val;
    } else {
        return wantarray ? @ret : $ret[0];
    };
}

sub add {
    my $self = $DRMVC::Config::singletone ? $_[0]->instance() : $_[0]; shift;
    my ($section, $key, $val) = @_;
    my $s = $self->section($section);
    $s->{$key} = $val;
    unshift @{$s->{'__'.$key}}, $val; 
    return 1;
}

sub get {
    my $self = $DRMVC::Config::singletone ? $_[0]->instance() : $_[0]; shift;
    my ($section, $key, $default) = @_;
    my $ret = $self->_get_set($section, $key);
    return (defined $default and not defined $ret) ? $default : $ret; 
}

sub getset {
    my $self = $DRMVC::Config::singletone ? $_[0]->instance() : $_[0]; shift;
    return $self->_get_set(@_);
}

sub _get_set {
    my $self = shift;
    my $section = shift;
    my $s = $self->section($section);
    unless (defined $_[0]) {
        return $s;
    } else {
        my $key = shift;
        if (exists $s->{$key} and @_) {
            my $default = shift;
            $self->add($section, $key, $default);
            return $default;
        } else {
            return $s->{$key};
        }
    }
}

sub new {
    my $class = shift;
    my $cnf_file = shift || '';
    unless ($cnf_file) {
        my @private = getpwuid($<);
        my $dir = File::Spec->catfile($private[7], '.drmvc');
        mkdir($dir) unless -d $dir;
        $cnf_file = File::Spec->catfile($dir, 'config');
        if ( sysopen(my $dummy, $cnf_file, O_RDWR|O_NONBLOCK|O_CREAT) ) {
            $dummy->close;
        }
    }
    my $self = $class->SUPER::new($cnf_file);
    # $self->add('general', 'current_config_path', $cnf_file);
    $instance = $self if $DRMVC::Config::singletone;
    return $self;
}


1;
__END__
