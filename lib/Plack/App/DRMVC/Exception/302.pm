package DRMVC::Exception::302;
use strict;
use warnings;

use base 'DRMVC::Base::Exception';

sub url   {$_[0]->{url}}

# see DRMVC::redirect
sub process {
    my $self = shift;
    die "url isn't defined" unless $self->url;
    my $app = DRMVC->instance;
    $app->res->redirect($self->url);
    $app->log('info', 'redirect found: url => '.$self->url.' code => 302');
    return;
}



1;
__END__
