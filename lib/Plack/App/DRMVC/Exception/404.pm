package Plack::App::DRMVC::Exception::404;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Exception';

sub msg {$_[0]->{msg}}

sub process {
    my $self = shift;

    my $app = Plack::App::DRMVC->instance;    
    $app->res->status(404);
    $app->res->content_type('text/plain; charset=utf-8');
    my $message = "Not found";
    $app->res->content_length(length $message);
    $app->res->body($message);
    $app->log('error', $self->msg) if $self->msg;
    
    return;
}



1;
__END__
