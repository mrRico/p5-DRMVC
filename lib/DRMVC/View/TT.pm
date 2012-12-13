package DRMVC::View::TT;
use strict;
use warnings;

use base 'DRMVC::Base::View';
use Template;
use Carp;

sub new {
	my $class = shift;
	my %param = %{$_[0]};
	%param = map { $_ => $param{$_} } grep { !/^_/ } keys %param;
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

