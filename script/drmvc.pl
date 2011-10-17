#!/usr/bin/perl
use strict;
use warnings;  

package DRMVCreator;

use File::Path qw(mkpath);
use File::Spec;
use Cwd;
use Carp;

my $vars = {
    app => 'dedededede'
};

sub process_file {
    my ($class, $content, $param, $file) = @_;

    $content =~ s/{{\s*([^\s]*)?\s*}}/$param->{$1}/gme;
    
    open(F, ">$file") or croak $!;
        print F $content; 
    close(F);
    
    return;
}

=head3 get_data_section($name)

Read DATA section from main package and will be returned sub-section $name.
There's something like Data::Section::Simple 

=cut
my $data = undef;
sub get_data_section {    
    my $name = shift;
    return unless $name;
    unless ($data) {
        my ($key, $val) = ('','');
        while (<main::DATA>) {
            if (/\s*\@{2}\s*(.*)?\s*/) {
                if ($key) {
                   chomp $val;
                   $data->{$key} = $val;
                   $val = ''; 
                }
                $key = $1;
            } else {
                $val .= $_;
            }
        }
        chomp $val;
        $data->{$key} = $val if $key;
    }
    return $data->{$name};
}

sub create_folder_structure {
    my $class = shift;
    my $app = shift;
    
    $vars->{app} = $app; 
    
    my $structure = $class->get_folder_structure($app);
    
    $class->_create_folder_structure($structure);
    
    return;
}

sub _create_folder_structure {
    my $class = shift;
    my $dir_hash = shift;
    
    for (keys %$dir_hash) {
        unless (defined $dir_hash->{$_}) {
            # skip
            1;
        } elsif (ref $dir_hash->{$_} eq 'HASH') {
            mkpath($_, {verbose => 1});
            $class->_create_folder_structure($dir_hash->{$_});            
        } elsif (not ref $dir_hash->{$_}) {
            $class->process_file($dir_hash->{$_}, $vars, $_);
        } else {
            croak "something wrong";
        }
    }
    
}

# возвращает структуру папок и файлов для апп
sub get_folder_structure {
    my $class = shift;
    my $APP = shift;
    my $app = lc $APP;
    $app =~ s/::/_/g;
    my $c_path = cwd;
    
    my $st = {}; 
    my $c_dir = File::Spec->catdir($c_path);
    my $lst = $st;
    my @app = split('::', $APP);
    for (@app) {
        $c_dir = File::Spec->catdir($c_dir, $_);
        $lst->{$c_dir} = {};
        $lst = $lst->{$c_dir};
    };
    
    %$lst = (
        File::Spec->catdir($c_dir, 'lib') => {},
        File::Spec->catdir($c_dir, 'log') => undef,
        File::Spec->catdir($c_dir, 'static') => {
            File::Spec->catdir($c_dir, 'static', 'js')  => undef,
            File::Spec->catdir($c_dir, 'static', 'img') => undef 
        },
        File::Spec->catdir($c_dir, 'conf') => {
            File::Spec->catdir($c_dir, 'conf', 'access') => {
                File::Spec->catfile($c_dir, 'conf', 'access', 'AllowTo.mini') => get_data_section('AllowTo.mini'),
                File::Spec->catfile($c_dir, 'conf', 'access', 'DenyTo.mini')  => get_data_section('DenyTo.mini'),
            },
            File::Spec->catfile($c_dir, 'conf', 'conf.mini') => get_data_section('conf.mini')
        },
        File::Spec->catfile($c_dir, "${app}.psgi") => get_data_section('app.psgi') 
    );
    
    $c_dir = File::Spec->catdir($c_dir, 'lib');
    $lst = $lst->{$c_dir};
    for (@app) {
        $c_dir = File::Spec->catdir($c_dir, $_);
        $lst->{$c_dir} = {};
        $lst = $lst->{$c_dir};
    };
    
    %$lst = (
        File::Spec->catdir($c_dir, 'Controller') => {
            File::Spec->catfile($c_dir, 'Controller', 'Root.pm') => get_data_section('Root.pm') 
        },
        File::Spec->catdir($c_dir, 'Model') => undef,
        File::Spec->catdir($c_dir, 'View')  => undef,
        File::Spec->catdir($c_dir, 'Exception') => undef,
        File::Spec->catdir($c_dir, 'Extend') => {
            File::Spec->catdir($c_dir, 'Extend','Controller') => {
                File::Spec->catdir($c_dir, 'Extend','Controller','Attributes') => undef
            },
            File::Spec->catfile($c_dir, 'Extend','Request.pm') => get_data_section('Request.pm'),
            File::Spec->catfile($c_dir, 'Extend','Response.pm') => get_data_section('Response.pm'),
            File::Spec->catfile($c_dir, 'Extend','Dispatcher.pm') => get_data_section('Dispatcher.pm')
        },
        File::Spec->catfile($c_dir, $app[-1].".pm") => get_data_section('DRMVC.child')
    );
    
    return $st;
}

1;

package Helper;

sub help {
    my ($class, $reson) = @_;
    print "    Error: ",$reson,"\n\n" if $reson;
    print <<END;
    Create your application:
            perl /some/path/drmvc.pl --app Foo::Bar
END
exit;
}

1;


package main;
use Getopt::Long;

my ($help, $app_name) = ();

GetOptions(
    'help|h=i'      => \$help,
    'app=s'         => \$app_name
);

# check param
Helper->help() if $help;
Helper->help("app name '".$app_name."' not valid") if (not $app_name or $app_name !~ /^\w+(:{2}\w+)+$/);
$app_name =~ s/^\s+//;
$app_name =~ s/\s+$//;

DRMVCreator->create_folder_structure($app_name);

exit;
 __DATA__
@@ conf.mini
conf.mini
{{ app }}

@@ AllowTo.mini
AllowTo.mini

@@ DenyTo.mini
DenyTo.mini

@@ app.psgi
app.psgi

@@ DRMVC.child
DRMVC.child

@@ Root.pm
Root.pm

@@ Request.pm
Request.pm

@@ Response.pm
Response.pm

@@ Dispatcher.pm
Dispatcher.pm

