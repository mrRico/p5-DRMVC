package DRMVC::Config;
use strict;
use warnings;

use Carp;
use File::Spec;
use Fcntl;
use base qw(Config::Mini);

my $instance = undef;
sub instance { $instance }

sub section {
    my $self = shift->instance();
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
    my $self = shift->instance();
    my ($section, $key, $val) = @_;
    my $s = $self->section($section);
    $s->{$key} = $val;
    unshift @{$s->{'__'.$key}}, $val; 
    return 1;
}

sub get {
    my $self = shift->instance();
    my ($section, $key, $default) = @_;
    my $ret = $self->_get_set($section, $key);
    return (defined $default and not defined $ret) ? $default : $ret; 
}

sub getset {
    my $self = shift;
    return $self->instance()->_get_set(@_);
}

sub _get_set {
    my $self = shift->instance();
    my ($section, $key, $default) = @_;
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
    unless ($cnf_file) {
        my @private = getpwuid($<);
        my $dir = File::Spec->catfile($private[7], '.drmvc');
        mkdir($dir) unless -d $dir;
        $cnf_file = File::Spec->catfile($dir, 'config');
        if ( sysopen(my $dummy, $cnf_file, O_RDWR|O_NONBLOCK|O_CREAT) ) {
            $dummy->close;
        }
    }
    $instance = $class->SUPER::new($cnf_file);
}


1;
__END__
