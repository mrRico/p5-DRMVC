package DRMVC::Base::View;
use strict;
use warnings;

=head1 NAME

DRMVC::Base::View

=head1 DESCRIPTION

There is base View for you app.

All yours views must have 'process' method.

If 'new' method is defined, 'process' could be invoked as objects method, otherwise as 'class' method.

=head1 SYNOPSIS

    my $app = MyApp->instance;
    
    # accessor for view 
    $app->view;
    $app->view('JSON');
    
=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

my $cache__short_name = {};
my $ns;
    
sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};    
    $ns ||= join ('|', map {(ref $_ || $_).'::'} 'DRMVC::View', @{DRMVC->instance->ini_conf->section('mvc')->{'view.namespace'}});
    ($cache__short_name->{$class} = $class) =~ s/^($ns)//;
    
    return $cache__short_name->{$class};
}

sub process {die "Not implemented!"}

1;
__END__
