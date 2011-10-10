package Plack::App::DRMVC::View::TextXslate;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::View';
use Text::Xslate;
use Encode;
use File::Find;
use Carp qw(croak);

my $tx;
my $cache_i18n;

sub init {
	my %conf = %{Plack::App::DRMVC->instance->ini_conf->{'View.TextXslate'} || {}};
	$conf{path} = [delete $conf{path}];
    $tx = Text::Xslate->new(%conf); 
    # pre-load files
    my $path = $conf{path}->[0];
    croak __PACKAGE__." directory $path not found" unless -d $path;
    find sub {
        if(/\.tx$/) {
            my $file = $File::Find::name;
            $file =~ s/\Q$path\E .//xsm; # fix path names
            $tx->load_file($file);
        }
    }, $path;   
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

Plack::App::DRMVC::View::TextXslate->init;

1;
__END__

