package Plack::App::DRMVC::Controller::Attributes::Methods;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::AttributeDescription';

sub init {
    my $class = shift;
    my $value = shift;
    
    return defined $value ? [map {uc $_} split(/\s*,\s*/, $value)] : undef;
}

sub call_description_coerce {
    my $class   = shift;
    my $desc    = shift;
    my $value   = shift || '';
    return unless $value;
    
    my @add_methods = map {uc $_} split(/\s*,\s*/,$value);    
    my @methods = $desc->http_methods;
    $desc->http_methods(@methods,@add_methods);
    
    return 1;   
}

1;
__END__
