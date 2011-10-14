#!/usr/bin/perl
use strict;
use warnings;  

use File::Path qw(mkpath);
use File::Spec;
use Cwd;

sub create_folder_structure {
    my $class = shift;
    my $app = shift;
    my $structure = $class->get_folder_structure($app);
    
    $class->_create_folder_structure($structure);
    
    return;
}

sub _create_folder_structure {
    my $class = shift;
    my $dir_hash = shift;
    
    for (keys %$dir_hash) {
        
    }
    
}

# возвращает структуру папок и файлов для апп
sub get_folder_structure {
    my $class = shift;
    my $APP = shift;
    my $app = lc $APP;
    $app =~ s/::/_/g;
    my $c_path = cwd;
    my $st = {
        File::Spec->catdir($c_path, 'lib') => {
            
        },
        File::Spec->catdir($c_path, 'log') => undef,
        File::Spec->catdir($c_path, 'static') => {
            File::Spec->catdir($c_path, 'static', 'js')  => undef,
            File::Spec->catdir($c_path, 'static', 'img') => undef 
        },
        File::Spec->catdir($c_path, 'conf') => {
            File::Spec->catdir($c_path, 'conf', 'access') => {
                File::Spec->catfile($c_path, 'conf', 'access', 'AllowTo.mini') => 'AllowTo.mini',
                File::Spec->catfile($c_path, 'conf', 'access', 'DenyTo.mini')  => 'DenyTo.mini',
            },
            File::Spec->catfile($c_path, 'conf', 'conf.mini') => 'conf.mini'
        },
        File::Spec->catfile($c_path, "${app}.psgi") => 'app.psgi' 
    };
    
    my $lst = $st->{lib};
    my $last;
    for $last (split('::', $APP)) {
        $lst->{$_} = {};
        $lst = $lst->{$_};
    };
    
    %$lst = (
        'Controller' => {
            'Root.pm' => 'Root.pm' 
        },
        'Model' => undef,
        'View'  => undef,
        'Exception' => undef,
        'Extend' => {
            'Controller' => {
                'Attributes' => undef
            },
            'Request.pm' => 'Request.pm',
            'Response.pm' => 'Response.pm',
            'Dispatcher.pm' => 'Dispatcher.pm'
        },
        "${last}.pm" => 'DRMVC.child'
    );
    
    return $st;
}


package Helper;

sub help {
    my ($class, $reson) = @_;
    print "    Error: ",$reson,"\n\n" if $reson;
    print <<END;
    Create your xxxxx application:
            perl drmvc.pl --app Foo::Bar
END
exit;
}

1;
#-----------------------------------------------------------------
package SimpleStash;

my $s_param = {};

sub param {
	my $class = shift;
	if (@_) {
		my $key = shift;
		if (@_) {
			$s_param->{$key} = $_[0];
			1;
		} else {
			$s_param->{$key};
		}
	} else {
		$s_param;
	}
}

1;
# ----------------------------------------------------------------
package Creator;

require Bicycle;
use File::Spec;
use File::Path qw(make_path);
use Module::Util qw(find_installed);
use Template;

# путь к папке с шаблонами для Template в absolute
my $tmp_path = File::Spec->catdir([File::Spec->splitpath( find_installed('Bicycle') )]->[1],'Bicycle','tmpl');
my $tt = Template->new(
    INCLUDE_PATH => $tmp_path,
    ABSOLUTE => 0,
    RELATIVE => 1
);

sub create_file {
    my ($class, $dir, $file, $new_name) = @_;
    
    my $target = File::Spec->catfile($dir, $file);
    if (-e $target) {
        # файл найден, перезаписывать не будем
        warn("file $target already exists");
    } elsif (-e File::Spec->catfile($tmp_path, $file)) {
        # если файла нет, а шаблон есть, то рендерим
        $target = File::Spec->catfile($dir, $new_name) if $new_name;
        my $META = {};
        $tt->process($file, { META => $META, %{SimpleStash->param} }, $target) || die $tt->error;
        if ($META->{chmod}) {
            chmod $META->{chmod}, $target;
        }
    } else {
        # если шаблона нет, просто создаём
        open(FAKE,">".$target) or die $!;
        close(FAKE);
    }
    
    return;    
}

sub create_dir {
    my ($class, @dir) = @_;
    
    my $dir = File::Spec->catdir(@dir); 
    #make_path($dir,{mode => 0664});
    make_path($dir);
    
    return $dir;
}

1;
# ----------------------------------------------------------------
package main;

use Getopt::Long;
use Cwd;
use File::Spec;
use Date::Manip;

my ($help,$app_name) = ();

GetOptions(
    'help|h=i'      => \$help,
    'app=s'       => \$app_name
);

# check param
Helper->help() if $help;
Helper->help("app name '".$app_name."' not valid") if (not $app_name or $app_name !~ /^\w+$/);
$app_name = ucfirst $app_name;

my $main_dir = Creator->create_dir(cwd,$app_name);

my $app_folder = {
    lib => {
        $app_name => {
            Model => undef,
            Controller => ['Root.pm'],
            # !!!TextXslate
            View => ['TextXslate.pm', 'TT.pm'],
            Exception => ['500.pm','404.pm','400.pm', '403.pm'],         
            Extend => {
                single_file => ['Request.pm','Response.pm', 'Dispatcher.pm']
            }
        },
        my_app_file => [$app_name.'.pm']
    },
    script => ['main.psgi', 'creator.pl','session_cleanup.sh'],
    log => [],
    files => {
        static => undef,
        webcached => undef
    },
    conf => ['main.xml'],
    data => {
        session => undef,
        tmp     => undef
    },
    tmpl => ['test.tx']
};

# переменные для шаблона
SimpleStash->param('CATFILE', sub{File::Spec->catfile(@_)});
SimpleStash->param('CATDIR',  sub{File::Spec->catdir(@_)});

SimpleStash->param('app_name', $app_name);
SimpleStash->param('app_dir', $main_dir);
SimpleStash->param('timezone', Date::Manip::Date_TimeZone());
SimpleStash->param('lbr', '[');
SimpleStash->param('rbr', ']');

create($app_folder, $main_dir);

# рекурсивно создаём каталог с файлами
sub create {
   my ($el, $folder) = @_;
   
   # skip - empty folder
   return unless $el;
   
   if (ref $el eq 'ARRAY') {
       Creator->create_file($folder, $_) for @$el;
   } elsif (ref $el eq 'HASH') {
       for (keys %$el) {
           if ($_ eq 'single_file') {
               if (ref $el->{$_} eq 'ARRAY') {
                Creator->create_file($folder, $_) for @{$el->{$_}};
               }
           } elsif ($_ eq 'my_app_file') {
               Creator->create_file($folder, 'MyApp.pm' => $app_name.'.pm');
           } else {
               my $dir = Creator->create_dir($folder, $_);
               create($el->{$_}, $dir);
           }
       }
   }
   
   return;
}

exit;
