package Plack::App::DRMVC::Base::Model;
use strict;
use warnings;

# this need to dispatching
my $cache__short_name = {};

my $ns = join ('|', map {(ref $_ || $_).'::'} 'Plack::App::DRMVC::Model', @{Plack::App::DRMVC->instance->ini_conf->section('mvc')->{'model.namespace'}});

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    
    ($cache__short_name->{$class} = $class) =~ s/^(Plack::App::DRMVC::Model::|$ns)//;
    
    return $cache__short_name->{$class};
}


=head1 SEE ALSO

L<Plack::App::DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
