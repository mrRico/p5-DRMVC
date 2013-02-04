package DRMVC::Singleton;
use strict;
use warnings;

# basic implementation singeton mode for MVC classes

my $singls = {};

sub instance {
    my $proto = shift;
    $proto = ref($proto) || $proto;
    unless (exists $singls->{$proto}) {
        if ($proto->can('new')) {
            $singls->{$proto} = $proto->new(@_);
        } elsif (@_ == 1) {
            $singls->{$proto} = $_[0];
        } else {
            # singletone is a self-name
            $singls->{$proto} = $proto;
        }
    }
    return $singls->{$proto};
}

1;
__END__
