package Plack::App::DRMVC::Controller::Attributes::LocalConnect;
use strict;
use warnings;

sub init {
    my $class = shift;
    my $value = shift;
    
    return (defined $value and $value ne '/') ? $value : '';
}

sub call_description_coerce {
    my $class   = shift;
    my $desc    = shift;
    
    my $connect_prefix = $desc->action_class->__shot_name; 
    unless ($connect_prefix eq 'Root') {
        $connect_prefix =~ s!:{2}!/!g;
        $connect_prefix = '/' . lc $connect_prefix;
    } else {
        $connect_prefix = '';
    }
    
    $desc->connect(join('/',$connect_prefix,$subinfo->{$_}->{LocalConnect}));

    return 1;    
}

1;
__END__
