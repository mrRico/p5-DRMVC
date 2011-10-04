package Plack::App::DRMVC::Exception::302;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Exception';

sub url   {$_[0]->{url}}

sub process {
    my $self = shift;
    die "url isn't defined" unless $self->url;
    my $app = Plack::App::DRMVC->instance;
    $app->res->redirect($self->url);
    $app->log('info', 'redirect found: url => '.$self->url.' code => 302')
    return;
}



1;
__END__
