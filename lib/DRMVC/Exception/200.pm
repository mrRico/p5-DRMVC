package DRMVC::Exception::200;
use strict;
use warnings;

use base 'DRMVC::Base::Exception';

sub process {
	my $self = shift;
    my $app = DRMVC->instance;
	
	$app->res->status(200);	
	$app->res->content_type("text/html; charset=utf-8") unless $app->res->content_type;
    $app->res->content_length(length $app->res->body) unless $app->res->content_length;
    
    return;
}



1;
__END__
