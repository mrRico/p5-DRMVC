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
    return Module::Util::find_installed($module, grep {! ref $_} (@_ || @INC));
}

sub Module::Util::devel_find_installed_dir {
    my $module = shift;
    my $abs_path = Module::Util::devel_find_installed($module, @_);
    return unless $abs_path;
    my $path = Module::Util::module_fs_path($module);
    return File::Spec->catdir( substr($abs_path, 0, -length($path)) ); 
}

sub Module::Util::devel_find_in_namespace {
    my $module = shift;
    my @ret = ();
    if (Module::Util::module_is_loaded('Devel::SearchINC')) {
        my $relative_name = Module::Util::module_fs_path($module);
        $relative_name = substr($relative_name, 0, -3).'/';
        @ret = map {Module::Util::path_to_module($_)} grep {index($_, $relative_name) == 0} keys %Devel::SearchINC::cache;
    }
    push @ret, Module::Util::find_in_namespace($module, grep {! ref $_} (@_ || @INC));
    return wantarray ? @ret : \@ret;
}

1;
__END__
