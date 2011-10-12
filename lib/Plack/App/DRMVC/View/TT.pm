package Plack::App::DRMVC::View::TT;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::View';
use Template;
use Carp;

sub new {
	my $class = shift;
    bless {tt => Template->new(@_)}, $class;
}

sub process {
    my $self = shift;
    
    my $app = Plack::App::DRMVC->instance;
    
    $app->res->status(200);
    $app->res->content_type($app->stash->{content_type} || 'text/html; charset=utf-8') unless $app->res->content_type;
    my $tmpl = $app->stash->{template};
    my $out = '';
    $self->{tt}->process($tmpl,$app->stash, \$out) || croak $self->{tt}->error();
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    # clear memory
    undef $out;
    
    return;
}


1;
__END__

