package Cards::Controller::UserId::Profile;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Controller';

sub root :Index {
    my $class = shift;
    my $app = Cards->instance;
    $DB::signal = 1;
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = "<h4>Profile for user ".$_[0]."</h4>";
    $app->res->content_length(length $body);
    $app->res->body($body);
    $app->log('error', 'sdfsdfsdf');
        
    return;
}

1;
__END__
