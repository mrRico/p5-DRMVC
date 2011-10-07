package Plack::App::DRMVC::View::TT;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::View';
use Template;

my $tt = Template->new(%{Plack::App::DRMVC->instance->ini_conf->{'View.TT'} || {}});

sub process {
    my $class = shift;
    
    my $app = $bi = Plack::App::DRMVC->instance;
    
    my $tmpl = $app->stash->{template};
    my $out = '';
    $tt->process($tmpl,$app->stash, \$out);
    $app->res->status(200);
    $app->stash->{content_type} ||= 'text/html; charset=utf-8';
    $app->res->content_type($app->stash->{content_type} || 'text/html; charset=utf-8') unless $app->res->content_type;
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    # clear memory
    undef $out;
    
    return;
}


1;
__END__

