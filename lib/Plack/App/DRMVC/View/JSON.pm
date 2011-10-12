package Plack::App::DRMVC::View::JSON;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::View';
use JSON;

sub process {
    my $self = shift;
    
    my $app = Plack::App::DRMVC->instance;
    
    $app->res->status(200);
    $app->res->content_type(delete $app->stash->{content_type} || 'application/json; charset=utf-8') unless $app->res->content_type; 
    my $out = JSON->new->utf8->pretty->encode($app->stash);
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    # clear memory
    undef $out;
    
    return;
}


1;
__END__

