package DRMVC::Base::View;
use strict;
use warnings;

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

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
