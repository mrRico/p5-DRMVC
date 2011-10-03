package Plack::App::DRMVC::Controller::Attributes::DeniedTo;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::AttributeDescription';

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? [split(/\s*,\s*/, $value)] : undef;
}



1;
__END__
