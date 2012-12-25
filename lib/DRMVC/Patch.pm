package DRMVC::Patch;
use strict;
use warnings;

use Module::Util qw();
use File::Spec;

sub Module::Util::devel_find_installed {
    my $module = shift;
    if (Module::Util::module_is_loaded('Devel::SearchINC')) {
        my $path = Module::Util::module_fs_path($module);
        no warnings 'once';
        my $abs_path = $Devel::SearchINC::cache{$path};
        return $abs_path if $abs_path;
    }
    return Module::Util::find_installed($module, @_);
}

sub Module::Util::devel_find_installed_dir {
    my $module = shift;
    my $abs_path = Module::Util::devel_find_installed($module, @_);
    return unless $abs_path;
    my $path = Module::Util::module_fs_path($module);
    return File::Spec->catdir( substr($abs_path, 0, -length($path)) ); 
}

1;
__END__
