package DRMVC::Controller::Attributes::LocalPath;
use strict;
use warnings;

use base 'DRMVC::Base::AttributeDescription';
use Carp;
use Module::Util qw(module_is_loaded);

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
        my $cns = DRMVC->instance->app_name_space.'::Controller';
        my @class_chunk = map {
            my $ckeck_controller_class = join('::', $cns, $_);
            if (module_is_loaded($ckeck_controller_class)) {
                # $ckeck_controller_class real controller
                $ckeck_controller_class->current_local_path_description
            } else {
                # $ckeck_controller_class - is only namespace
                lc $_;
            }
        } split ('::', $connect_prefix);
        $connect_prefix = '/' . join('/', @class_chunk);
    } else {
        $connect_prefix = '';
    }
    
    $desc->connect(join('/', $connect_prefix, $value));

    return 1;   
}

1;
__END__
