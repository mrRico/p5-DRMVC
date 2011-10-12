package Plack::App::DRMVC::View::TextXslate;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::View';
use Text::Xslate;
use Encode;
use File::Find;
use Carp qw(croak);

sub new {
	my $class  = shift;
	my %params = @_;
	$params{warn_handler} = \&cb;
	$params{die_handler} = \&cb;
    $tx = Text::Xslate->new(%params); 
    find sub {
        if(/\.tx$/) {
            my $file = $File::Find::name;
            $file =~ s/\Q$path\E .//xsm; # fix path names
            $tx->load_file($file);
        }
    }, @{$params{path}};   
}


sub process {
    my $class = shift;
    
    my $app = Plack::App::DRMVC->instance;
    $app->res->status(200);
    $app->res->content_type($app->stash->{content_type} || 'text/html; charset=utf-8') unless $app->res->content_type;
    my $tmpl = $app->stash->{template};
    my $out = $tx->render($tmpl, $app->stash);
    Encode::_utf8_off($out);
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    undef $out;
    
    return;
}

1;
__END__

