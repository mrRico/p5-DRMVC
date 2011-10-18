#!/usr/bin/perl
use strict;
use warnings;  

package DRMVCreator;

use File::Path qw(mkpath);
use File::Spec;
use Cwd;
use Carp;

my $vars = {
    drmvc => 'DRMVC',
    catfile => sub {File::Spec->catfile(@_)},
    catdir => sub {File::Spec->catdir(@_)},
    xx => '@@'
};

sub process_file {
    my ($class, $content, $param, $file) = @_;

    $content =~ s!{{\s*([^\s]*)?\s*}}!
        my $f = $1;
        if ($f =~ /(\w+)\((['"]?)/ and $1) {
        	my $name = $1;
            my $quote = $2 || '';
            if (ref $param->{$name} eq 'CODE') {
	            $f =~ /(\w+)(\($quote(.*)$quote\))?/;
	            my $value = $3 || '';
	            my @values = map {($_ and /^\$(.*)?/) ? $param->{$1} : $_} split(/\s*,\s*/, $value);
            	$param->{$name}->(@values);
            }
        } else {
	        $param->{$1}
        }
    !gmex;
    
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
    
    chmod 0755, $_ for (
        File::Spec->catfile($vars->{root_dir}, $vars->{prepare_app}.".psgi"),
        File::Spec->catfile($vars->{root_dir}, 'script', "creator.pl")
    );
    
    return;
}

sub _create_folder_structure {
    my $class = shift;
    my $dir_hash = shift;
    
    for (keys %$dir_hash) {
        unless (defined $dir_hash->{$_}) {
            mkpath($_, {verbose => 1});
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
    
    $vars->{prepare_app} = $app; 
    
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
        File::Spec->catdir($c_dir, 'lib') => {
            File::Spec->catfile($c_dir, 'lib', $app[-1].".pm") => get_data_section('DRMVC.child')
        },
        File::Spec->catdir($c_dir, 'log') => undef,
        File::Spec->catdir($c_dir, 'script') => {
            File::Spec->catfile($c_dir, 'script', 'creator.pl') => get_data_section('creator.pl'),
        },
        File::Spec->catdir($c_dir, 'static') => {
            File::Spec->catdir($c_dir, 'static', 'js')  => undef,
            File::Spec->catdir($c_dir, 'static', 'img') => undef 
        },
        File::Spec->catdir($c_dir, 'on_demand') => undef,
        File::Spec->catdir($c_dir, 'conf') => {
            File::Spec->catdir($c_dir, 'conf', 'access') => {
                File::Spec->catfile($c_dir, 'conf', 'access', 'AllowTo.mini') => get_data_section('AllowTo.mini'),
                File::Spec->catfile($c_dir, 'conf', 'access', 'DenyTo.mini')  => get_data_section('DenyTo.mini'),
            },
            File::Spec->catfile($c_dir, 'conf', 'conf.mini') => get_data_section('conf.mini')
        },
        File::Spec->catfile($c_dir, "${app}.psgi") => get_data_section('app.psgi') 
    );
    
    $vars->{root_dir} = $c_dir;
    $c_dir = File::Spec->catdir($c_dir, 'lib');
    $lst = $lst->{$c_dir};
    for (@app) {
        $c_dir = File::Spec->catdir($c_dir, $_);
        $lst->{$c_dir} ||= {};
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
        }        
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
Helper->help("app name '".$app_name."' not valid") if (not $app_name or $app_name !~ m/^[^\W\d]\w*(?:::\w+)*\z/s);
$app_name =~ s/^\s+//;
$app_name =~ s/\s+$//;

DRMVCreator->create_folder_structure($app_name);

exit;
 __DATA__
@@ conf.mini
app_name = {{app}}

[router]
static.allready.path                = {{catdir($root_dir,static)}}
static.allready.first_uri_segment   = static
static.on_demand.path               = {{catdir($root_dir,on_demand)}}
static.on_demand.first_uri_segment  = ondemand 
cache_limit                         = 300

[default]
view    = {{drmvc}}::View::TT

[mvc]
@controller.namespace = {{app}}::Controller
@model.namespace      = {{app}}::Model
@view.namespace       = {{app}}::View

[logger]
log_level   = debug
log_dir     = {{catdir($root_dir,log)}}
error_file  = error.log.%year%month%day
access_file = access.log.%year%month%day

############### Additional #####################
[addition.exception]
# здесь можно перечислить short-нейм ошибок, которые хочется импортировать по неймспейсу {{drmvc}}::Exception::*


[addition.attributes]
GlobalPath  = 1
LocalPath   = 1
Index       = 1
Methods     = 1
M           = 1
AllowTo     = 1
DenyTo      = 1

[addition.model.Access]
%package = {{drmvc}}::Model::Access
%constructor = new
DenyTo_conf  = {{catfile($root_dir,conf,access,DenyTo.mini)}}
AllowTo_conf = {{catfile($root_dir,conf,access,AllowTo.mini)}}

[addition.view.TT]

#[addition.view.TextXslate]
#path       = /temp/xslate
#cache      = 1
#cache_dir  = /temp/xslate_cache
#suffix     = .tx
#verbose    = 2

[addition.view.JSON]


@@ AllowTo.mini
[only_me]
@IPv4 = 127.0.0.1

@@ DenyTo.mini
# hidden [general] section
@IPv4 = 127.0.0.1

@@ app.psgi
#!/usr/bin/perl
use strict;
use warnings;

use File::Spec;
use Cwd 'abs_path';

use lib '/home/mrrico/Project/DRMVC/lib';
use lib File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); @_[0..$#_-1]}->(),'lib');

use Plack::Builder;
use {{drmvc}};

builder {
      {{drmvc}}->get_app(
            conf_path => File::Spec->catfile(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); $_[$#_] = 'conf'; push @_,'conf.mini'; @_}->())
      );
};

@@ DRMVC.child
package {{app}};
use strict;
use warnings;

use base '{{drmvc}}';




1;
__END__

@@ Root.pm
package {{app}}::Controller::Root;
use strict;
use warnings;

=head1 NAME

{{app}}::Controller::Root

=head1 DESCRIPTION

Root controller

=cut
use base '{{drmvc}}::Base::Controller';

# http://my-site.com/ + methods GET and DELETE
sub root :Index :Methods(GET,DELETE) {
    my $class = shift;
    my $app = {{app}}->instance;
    
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = '<h4>Dr.MVC say "Hello, word!"</h4>';
    $app->res->content_length(length $body);
    $app->res->body($body);
        
    return;
}

# http://my-site.com/json + methods GET + allow to "only_me" sections from {{catfile($root_dir,conf,access.allow.mini)}}
sub json_example :LocalPath(json) :Methods(GET) :AllowTo(only_me) {
    my $class = shift;
    my $app = {{app}}->instance;
    $app->view('JSON');
    
    $app->stash->{msg} = 'Dr.MVC say "Hello, Word!"';
        
    return;
}

# http://my-site.com/forbidden/example + methods GET + deny to "general" sections from {{catfile($root_dir,conf,access.deny.mini)}}
sub forbidden_example :LocalPath(forbidden/example) :Methods(GET) :DenyTo {
    my $class = shift;
    my $app = {{app}}->instance;
    $app->view('JSON');
    
    $app->stash->{msg} = 'Dr.MVC say "You are lucky!"';
        
    return;
}

1;
__END__

@@ Request.pm
package {{app}}::Extend::Request;
use strict;
use warnings;

use base 'Plack::Request';




1;
__END__

@@ Response.pm
package {{app}}::Extend::Response;
use strict;
use warnings;

use base 'Plack::Response';




1;
__END__

@@ Dispatcher.pm
package {{app}}::Extend::Dispatcher;
use strict;
use warnings;

use base '{{drmvc}}::Base::Dispatcher';




1;
__END__

@@ creator.pl
#!/usr/bin/perl
use strict;
use warnings;

package CurCreator;



1;

package Helper;

sub help {
    my $class = shift;
    my $reson = shift;
    print "    $reson\n" if $reson;
    print "
    you can call this script with parametrs:
        /home/mrrico/Project/Cards/creator.pl --some_type PACKAGE::NAME
        
    now avaliable follow type: \n".join("\n", map {"    - $_"} keys %{$main::Validator})."\n\n";
    exit;
}

1;

package main;
use Getopt::Long;

my ($help, $param) = (0, {});
GetOptions(
    'help|h=i'          => \$help,
    'controller|c=s'    => \$param->{controller},
    'model|m=s'         => \$param->{model},
    'view|v=s'          => \$param->{view},
    'exception|e=i'     => \$param->{exception},
    'attribute|a=s'     => \$param->{attribute},
);

$main::Validator = {
    controller  => \&_package_name,
    model       => \&_package_name,
    view        => \&_package_name,
    exception   => \&_int,
    attribute   => \&_att
};

sub _package_name {($_[0] and $_[0] =~ m/^[^\W\d]\w*(?:::\w+)*\z/s) ? 1 : 0}
sub _int {$_[0] =~ /^\d+$/ ? 1 : 0}
sub _att {($_[0] and $_[0] =~ /^[^\W]+$/) ? 1 : 0}

if ($help or not grep {$_} values %$param) {
  Helper->help();
}

for (keys %$param) {
    next unless $param->{$_};
    Helper->help("'$param->{$_}' is bad name for $_") unless $main::Validator->{$_}->($param->{$_}); 
}

#CurCreator->create($param);


__DATA__
{{xx}} controller
package Cards::[% type %]::[% name %];
use strict;
use warnings;
[% IF type == 'Controller' %]
use base 'Bicycle::Base::Controller';

sub index :LC('/') {
    my $class = shift;
    my $app = Cards->instance;
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = "<h4>Cards::[% type %]::[% name %]</h4>";
    $app->res->content_length(length $body);
    $app->res->body($body);
        
    return;
}
[% END %]


{{xx}} model

{{xx}} view

{{xx}} exception

{{xx}} attribute

