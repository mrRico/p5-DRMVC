package Cards::Controller::Root;
use strict;
use warnings;

=head1 NAME

Cards::Controller::Root

=head1 DESCRIPTION

Root controller

=cut
use base 'Plack::App::DRMVC::Base::Controller';

sub root :Index :M('GET') {
    my $class = shift;
    my $app = Cards->instance;
    $DB::signal = 1;
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = "<h4>Hello, word!</h4>";
    $app->res->content_length(length $body);
    $app->res->body($body);
    $app->log('error', 'sdfsdfsdf');
        
    return;
}

sub json_example :LocalPath(json) :M(GET) :AllowTo(only_me) {
    my $class = shift;
    my $app = Cards->instance;
    $app->view('JSON');
    
    $app->stash->{msg} = 'Hello, Word!';
        
    return;
}

1;
__END__
