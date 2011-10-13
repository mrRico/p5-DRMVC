package Plack::App::DRMVC::Base::View;
use strict;
use warnings;

my $cache__short_name = {};

my $ns = join ('|', map {(ref $_ || $_).'::'} 'Plack::App::DRMVC::View', @{Plack::App::DRMVC->instance->ini_conf->section('mvc')->{'view.namespace'}});
    
sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};    
    
    ($cache__short_name->{$class} = $class) =~ s/^($ns)//;
    
    return $cache__short_name->{$class};
}

sub process {die "Not implemented!"}

=head1 SEE ALSO

L<Plack::App::DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
