package Plack::App::DRMVC::Exception::403;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Exception';
sub error {$_[0]->{error} || 'Forbidden'}

sub process {
    my $self = shift;
    my $app = Plack::App::DRMVC->instance;
    
    $app->res->status(403);
    $app->res->content_type("text/plain; charset=utf-8");
    my $mess = $self->error;
    $app->res->content_length(length $mess);
    $app->res->body($mess);
    
    return;    
}


1;
__END__
