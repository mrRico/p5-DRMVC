package Plack::App::DRMVC::Exception::304;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Exception';

sub process {
	my $self = shift;
	my $app = Plack::App::DRMVC->instance;
    
    $app->res->status(304);
    $app->res->content_type("text/plain; charset=utf-8");
    my $mess = 'Not Modified';
    $app->res->content_length(length $mess);
    $app->res->body($mess);
    
    return;	
}



1;
__END__
