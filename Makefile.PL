use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires;
use Module::Install::CheckConflicts;
use Module::Install::AuthorTests;

perl_version '5.010001';

name 'DRMVC';
all_from 'lib/DRMVC.pm';
no_index directory => 't';
no_index directory => 'inc';
no_index directory => 'script';

# allready exists in core
# http://perldoc.perl.org/index-modules-A.html
# http://perldoc.perl.org/5.10.0/index-modules-S.html
#requires 'Carp'            => '0';
#requires 'Cwd'             => '0';
#requires 'Data::Dumper'    => '0';
#requires 'Encode'          => '0';
#requires 'Fcntl '          => '0';
#requires 'File::Find'      => '0';
#requires 'File::Spec'      => '0';
#requires 'IO::File'        => '0';
#requires 'Module::Load'    => '0';
#requires 'Scalar::Util'    => '0';

requires 'Config::Mini'         => '0';
requires 'Data::Util'           => '0';
requires 'Date::Manip::Date'    => '0';
requires 'HTTP::Date'           => '0';
requires 'JSON'                 => '0';
requires 'Module::Util'         => '0';
requires 'Net::IP'              => '0';
requires 'Net::IP::Match::Trie' => '0';
requires 'Plack::Util'          => '0';
requires 'Router::PathInfo'     => '0.05';
requires 'Template'             => '0';
requires 'Text::Xslate'         => '0';

resources(
    'license'    => 'http://dev.perl.org/licenses/',
    'repository' => 'git@github.com:mrRico/p5-DRMVC.git',
);

install_script glob('script/*.pl');
auto_install;
WriteAll;

print <<"EOF";

    Now, you can start with:

        perl /some/path/drmvc.pl --app MyApp

    Have fun!
 
EOF
