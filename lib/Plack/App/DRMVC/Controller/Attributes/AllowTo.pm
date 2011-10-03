package Plack::App::DRMVC::Controller::Attributes::AllowTo;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::AttributeDescription';

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? [split(/\s*,\s*/, $value)] : undef;
}

sub call_description_coerce {
    my $class       =  shift;
    my $call_desc   =  shift;
    
    
    
    return 1;
}



1;
__END__
