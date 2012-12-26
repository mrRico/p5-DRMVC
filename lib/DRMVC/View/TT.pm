package DRMVC::View::TT;
use strict;
use warnings;

use base 'DRMVC::Base::View';
use Template;
use File::Spec;
use Carp;

sub new {
	my $class = shift;
	my $app = DRMVC->instance;
	my $param = $app->ini_conf->section('addition.view.'.$class->__short_name);
	my %param = map { $_ => $param->{$_} } grep { !/^_/ } keys %$param;
	if ($param{LOCAL_PATH}) {
	    my $new_inc = File::Spec->catdir($app->ini_conf->get('general', 'root_dir'), delete $param{LOCAL_PATH});
    	$param{INCLUDE_PATH} = $new_inc;
    	$app->ini_conf->set('addition.view.'.$class->__short_name, 'INCLUDE_PATH', $new_inc);
	}
    bless {tt => Template->new(%param)}, $class;
}

sub process {
    my $self = shift;
    
    my $app = DRMVC->instance;
    
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

