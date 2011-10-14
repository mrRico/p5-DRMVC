package Plack::App::DRMVC::Base::Controller;
use strict;
use warnings;

=head1 NAME

Plack::App::DRMVC::Base::Controller

=head1 DESCRIPTION

Base class for all Plack::App::DRMVC's controllers.
When controller load, all Plack::App::DRMVC-attributes save in pacakges variables.
You can find them in C<$class::_attr>.

=cut

use Carp qw();
use Plack::App::DRMVC::Controller::AttributesResolver;

my $cache__short_name = {};
my $ns;

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    $ns ||= join ('|', map {(ref $_ || $_).'::'} 'Plack::App::DRMVC::Controller', @{Plack::App::DRMVC->instance->ini_conf->section('mvc')->{'controller.namespace'}});
    ($cache__short_name->{$class} = $class) =~ s/^$ns//;
    
    return $cache__short_name->{$class};
}

# for create local path
sub current_local_path_description {
    my $class = shift;
    lc [split '::', $class]->[-1];
}

sub MODIFY_CODE_ATTRIBUTES {    
    my ($class, $code, @attrs) = @_;
    return () unless @attrs;
    
    my $att_resolver = Plack::App::DRMVC::Controller::AttributesResolver->new();
    
    my @unknown_att = ();
    
    no strict 'refs';
    my $pv = ${"${class}::_attr"} ||= {};
    use strict 'refs';
    
    $pv->{$code}->{code} = $code;
    
    for (@attrs) {
        /(\w+)(\((['"]?))?/;
        next unless $1;
        my $name = $1;
        my $quote = $3 || '';
        /(\w+)(\($quote(.*)$quote\))?/;
        my $value = $3 || '';
        
        my $ret = $att_resolver->init(name => $name, value => $value);
        if (defined $ret) {
            $pv->{$code}->{$name} = $ret; 
        } else {
            push @unknown_att, $_;
        }
    }
    
    Carp::carp "Unknown attributes ".join(', ',@unknown_att)." found in $class" if @unknown_att;
    return @unknown_att;
}

=head1 SEE ALSO

L<Plack::App::DRMVC>, MODIFY_CODE_ATTRIBUTES

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
