package DRMVC::View::TextXslate;
use strict;
use warnings;

use base qw(DRMVC::Singleton DRMVC::Base::View);
use Text::Xslate;
use Encode;
use File::Find;
use File::Spec;
use Carp qw(croak);

sub new {
	my $class  = shift;
	my $app = DRMVC->instance;
    my $param = $app->ini_conf->section('addition.view.'.$class->__short_name);
    my %params = map { $_ => $param->{$_} } grep { !/^_/ } keys %$param;
    
    for (qw(path cache_dir)) {
        next unless $params{$_};
        next if -d $params{$_};
        my $new_inc = File::Spec->catdir($app->ini_conf->get('general', 'root_dir'), $params{$_});
        $params{$_} = $new_inc;
        $app->ini_conf->set('addition.view.'.$class->__short_name, $_, $new_inc);
    }
	
	# exception handler has been added
	$params{warn_handler} = sub {
	    my $warn = shift;
	    DRMVC->instance->log('warn', $warn);
	};
	$params{die_handler} = sub {
	    my $error = shift;
        DRMVC->instance->exception(500, error => $error);
	};
	
    my $tx = Text::Xslate->new(%params);
    
    if ($params{path}) {
        # it's important before prefork
        my $path = $params{path};
        find sub {
            if(/\.tx$/) {
                my $file = $File::Find::name;
                $file =~ s/\Q$path\E .//xsm;
                $tx->load_file($file);
            }
        }, $path; 
    }
    
    bless {tx => $tx}, $class;
}


sub process {
    my $self = shift;
    
    my $app = DRMVC->instance;
    $app->res->status(200);
    $app->res->content_type($app->stash->{content_type} || 'text/html; charset=utf-8') unless $app->res->content_type;
    my $tmpl = $app->stash->{template};
    my $out = $self->{tx}->render($tmpl, $app->stash);
    Encode::_utf8_off($out);
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    undef $out;
    
    return;
}

1;
__END__

