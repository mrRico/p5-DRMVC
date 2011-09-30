package Plack::App::DRMVC::Controller::Attributes::DeniedTo;
use strict;
use warnings;

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? [split(/\s*,\s*/, $value)] : undef;
}



1;
__END__
