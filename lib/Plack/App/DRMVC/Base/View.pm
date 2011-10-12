package Plack::App::DRMVC::Base::View;
use strict;
use warnings;

my $cache__short_name = {};

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    
    my $bi = Plack::App::DRMVC->instance;
    my $ns = join ('|', map {$_.'::'} @{$bi->ini_conf->section('mvc')->{'view.namespace'}});
    ($cache__short_name->{$class} = $class) =~ s/^(Plack::App::DRMVC::View::|$ns)//;
    
    return $cache__short_name->{$class};
}

# очь юзабельно для Config::Mini
sub new {
	my $class = shift;
	bless ref $_[0] ? $_[0] : {@_}, $class; 
}

sub process {die "Not implemented!"}

=head1 SEE ALSO

L<Plack::App::DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
