package DRMVC::Util;
use strict;
use warnings;

use File::Spec;

use DRMVC::Patch;

sub app_dir {
    my $app = @_ ? shift : ref DRMVC->instance;
    my $dir = Module::Util::devel_find_installed_dir($app);
    return File::Spec->catdir( sub{local @_ = File::Spec->splitdir($dir); $#_--; @_}->() );
}

1;
__END__
