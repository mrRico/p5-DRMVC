package Plack::App::DRMVC::Base::Model;
use strict;
use warnings;

# this need to dispatching
my $cache__short_name = {};

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    
    my $bi = Plack::App::DRMVC->instance;
    my $ns = $bi->ini_conf->{mvc}->{'model.namespace'}.'::';
    ($cache__short_name->{$class} = $class) =~ s/^$ns//;
    
    return $cache__short_name->{$class};
}


=head1 SEE ALSO

L<Plack::App::DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
