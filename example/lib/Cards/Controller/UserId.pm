package Cards::Controller::UserId;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Controller';

sub current_local_path_description {
    ':name(user_id):re(^\d{1,15}$)';
}

sub root :Index {
    my $class = shift;
    my $match = shift;
    my $app = Cards->instance;
    $DB::signal = 1;
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = "<h4>namespace for user with id ".$match->{user_id}."</h4>";
    $app->res->content_length(length $body);
    $app->res->body($body);
    $app->log('error', 'sdfsdfsdf');
        
    return;
}

1;
__END__
