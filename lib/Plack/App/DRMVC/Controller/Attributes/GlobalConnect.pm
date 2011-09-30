package Plack::App::DRMVC::Controller::Attributes::GlobalConnect;
use strict;
use warnings;

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? $value : '';
}



1;
__END__
