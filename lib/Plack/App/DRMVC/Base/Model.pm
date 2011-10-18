package DRMVC::Base::Model;
use strict;
use warnings;

# this need to dispatching
my $cache__short_name = {};

my $ns;

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    
    $ns ||= join ('|', map {(ref $_ || $_).'::'} 'DRMVC::Model', @{DRMVC->instance->ini_conf->section('mvc')->{'model.namespace'}});
    ($cache__short_name->{$class} = $class) =~ s/^(DRMVC::Model::|$ns)//;
    
    return $cache__short_name->{$class};
}


=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
