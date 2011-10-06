package Plack::App::DRMVC::Controller::Attributes::LocalPath;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::AttributeDescription';
use Carp;

sub init {
    my $class = shift;
    my $value = shift;
    
    return (defined $value and $value ne '/') ? $value : '';
}

sub call_description_coerce {
    my $class   = shift;
    my $desc    = shift;
    my $value   = shift;
    
    croak "connect allready exists in ".join('::', $desc->action_class, $desc->action_method) if $desc->connect; 
    
    my $connect_prefix = $desc->action_class->__short_name; 
    unless ($connect_prefix eq 'Root') {
        $connect_prefix =~ s!:{2}!/!g;
        $connect_prefix = '/' . lc $connect_prefix;
    } else {
        $connect_prefix = '';
    }
    
    $desc->connect(join('/', $connect_prefix, $value));

    return 1;   
}

1;
__END__
