package DRMVC::Base::Controller;
use strict;
use warnings;

=head1 NAME

DRMVC::Base::Controller

=head1 DESCRIPTION

There is base Controller for you app.

=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<DRMVC>, MODIFY_CODE_ATTRIBUTES

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

use Carp qw();
use DRMVC::Controller::AttributesResolver;

my $cache__short_name = {};
my $ns;

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    $ns ||= join ('|', map {(ref $_ || $_).'::'} 'DRMVC::Controller', @{DRMVC->instance->ini_conf->section('mvc')->{'controller.namespace'}});
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
    
    my $att_resolver = DRMVC::Controller::AttributesResolver->new();
    
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

sub _call_as_class {0}

1;
__END__
