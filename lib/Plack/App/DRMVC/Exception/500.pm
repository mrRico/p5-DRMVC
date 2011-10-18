package DRMVC::Exception::500;
use strict;
use warnings;

use base 'DRMVC::Base::Exception';

sub error {$_[0]->{error} || 'unknown'}

sub process {
    my $self = shift;

    my $app = DRMVC->instance;    
    $app->res->status(500);
    $app->res->content_type('text/plain; charset=utf-8');
    my $message = "Internal error";
    $app->res->content_length(length $message);
    $app->res->body($message);
    $app->log('error',$self->error);
    
    return;
}



1;
__END__
