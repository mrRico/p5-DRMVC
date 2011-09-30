package Plack::App::DRMVC::Controller::Attributes::Methods;
use strict;
use warnings;

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? [map {uc $_} split(/\s*,\s*/, $value)] : undef;
}



1;
__END__
