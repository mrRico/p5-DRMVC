package Plack::App::DRMVC::Controller::Attributes::GlobalPath;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::AttributeDescription';
use Carp;

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? $value : '';
}

sub call_description_coerce {
    my $class   = shift;
    my $desc    = shift;
    my $value   = shift;
    
    croak "connect allready exists in ".join('::', $desc->action_class, $desc->action_method) if $desc->connect;
    
    $desc->connect($value);

    return 1;   
}

1;
__END__
