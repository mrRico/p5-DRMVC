#!/usr/bin/perl
use strict;
use warnings;  

package DRMVCreator;

use File::Path qw(mkpath);
use File::Spec;
use Cwd;
use Carp;
use MIME::Base64 qw();

my $vars = {
    drmvc => 'DRMVC',
    catfile => sub {File::Spec->catfile(@_)},
    catdir => sub {File::Spec->catdir(@_)},
    xx => '@@',
    lx => '{{',
    rx => '}}'
};

sub process_file {
    my ($class, $content, $param, $file) = @_;
    
    my $bin = $file =~ /\.(ico|jpg|png)$/;
    
    if ($bin) {
        chomp $content;
        $content = MIME::Base64::decode($content); 
    } else {
        $content =~ s!{{\s*([^\s\\]*?)\s*}}!
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
    	        $param->{$f} || ''
            }
        !gmex;
    }
    open(F, ">$file") or croak $!;
        binmode F if $bin;
        print F $content; 
    close(F);
    print STDERR "file  $file\n";
    
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
        	if (-f $_) {
		        carp "'$_' already exists. it has been skipped.";
		        return;
		    };
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
            File::Spec->catdir($c_dir, 'static', 'img') => undef,
            File::Spec->catfile($c_dir, 'static', 'favicon.ico') => get_data_section('favicon.ico')
        },
        File::Spec->catdir($c_dir, 'on_demand') => undef,
        File::Spec->catdir($c_dir, 'conf') => {
            File::Spec->catdir($c_dir, 'conf', 'access') => {
                File::Spec->catfile($c_dir, 'conf', 'access', 'AllowTo.mini') => get_data_section('AllowTo.mini'),
                File::Spec->catfile($c_dir, 'conf', 'access', 'DenyTo.mini')  => get_data_section('DenyTo.mini'),
            },
            File::Spec->catfile($c_dir, 'conf', 'conf.mini') => get_data_section('conf.mini')
        },
        File::Spec->catfile($c_dir, "${app}.psgi") => get_data_section('app.psgi'),
        File::Spec->catdir($c_dir, 'tmpl') => {
            File::Spec->catdir($c_dir, 'tmpl', 'xslate') => undef,
            File::Spec->catdir($c_dir, 'tmpl', 'tt') => undef
        },
        File::Spec->catdir($c_dir, 'tmp') => {
            File::Spec->catdir($c_dir, 'tmp', 'xslate_cache') => undef
        },
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
static.allready.root_folder         = static
static.allready.first_uri_segment   = static
static.on_demand.path               = on_demand
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
log_dir     = log
error_file  = error.log.%year_%month_%day
flock       = 1

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
DenyTo_conf  = conf/access/DenyTo.mini
AllowTo_conf = conf/access/AllowTo.mini
ttl = 300
disabled = 1

[addition.view.TT]
# some trick
LOCAL_PATH = tmpl/tt

[addition.view.TextXslate]
syntax     = TTerse
path       = tmpl/xslate
cache      = 1
cache_dir  = tmp/xslate_cache
suffix     = .tx
verbose    = 2

[addition.view.JSON]


@@ AllowTo.mini
[only_me]
@IPv4 = 127.0.0.1

@@ DenyTo.mini
# hidden [general] section
# @IPv4 = 127.0.0.1

@@ app.psgi
#!/usr/bin/perl
use strict;
use warnings;

use File::Spec;
use Cwd 'abs_path';

use lib File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); $_[1]}->(),'lib');

use Plack::Builder;
use {{app}};

builder {
      {{app}}->get_app(
            conf_path => File::Spec->catfile(sub{
                local @_ = File::Spec->splitpath(abs_path(__FILE__));
                @_ = File::Spec->splitdir($_[1]);
                $_[$#_] = 'conf';
                push @_,'conf.mini'; 
                @_
            }->())
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
    my $body = '<h4>Dr.MVC says "Hello, word!"</h4>';
    $app->res->content_length(length $body);
    $app->res->body($body);
        
    return;
}

# http://my-site.com/json + methods GET + allow to "only_me" sections from conf/access.allow.mini
sub json_example :LocalPath(json) :Methods(GET) :AllowTo(only_me) {
    my $class = shift;
    my $app = {{app}}->instance;
    $app->view('JSON');
    
    $app->stash->{msg} = 'Dr.MVC says "Hello, Word!"';
        
    return;
}

# http://my-site.com/forbidden/example + methods GET + deny to "general" sections from conf/access.deny.mini
sub forbidden_example :LocalPath(forbidden/example) :Methods(GET) :DenyTo {
    my $class = shift;
    my $app = {{app}}->instance;
    $app->view('JSON');
    
    $app->stash->{msg} = 'Dr.MVC says "You are lucky!"';
        
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

use File::Spec;
use Cwd 'abs_path';
use lib File::Spec->catdir(sub {local @_ = File::Spec->splitpath(abs_path(__FILE__)); @_ = File::Spec->splitdir($_[1]); $#_-=2; @_ }->(),'lib');
use DRMVC::Util;

package CurCreator;
use File::Path qw(mkpath);
use File::Spec;
use Carp;

my $vars = {
    drmvc => '{{drmvc}}',
    catfile => sub {File::Spec->catfile(@_)},
    catdir => sub {File::Spec->catdir(@_)}
};

sub process_file {
    my ($class, $content, $param, $file) = @_;
    if (-f $file) {
        carp "'$file' already exists. it has been skipped.";
        return;
    };
    $content =~ s!{{\s*([^\s\\]*?)\s*}}!
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
            $param->{$f} || ''
        }
    !gmex;
    open(F, ">$file") or croak $!;
        print F $content; 
    close(F);
    print $file, "\n";
    return;
}

my $data = undef;
sub get_data_section {
	my $class = shift;   
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

sub create {
    my $class = shift;
    my $param = shift;
    for my $type (keys %$param) {
        next unless $param->{$type};
        $vars->{$type} = $param->{$type};
        my @name = split('::', $param->{$type});
        my $dir = File::Spec->catdir(DRMVC::Util::app_dir('{{app}}'), 'lib', split('::', '{{app}}'),($type eq 'attribute' ? ('Extend','Controller','Attributes') : ucfirst $type), @name[0..$#name-1]);
        mkpath $dir; 
        my $file = File::Spec->catfile($dir, $name[$#name].'.pm');
        $class->process_file($class->get_data_section($type), $vars, $file);
    }
    
    return;
}

1;

package Helper;

sub help {
    my $class = shift;
    my $reson = shift;
    print "    $reson\n" if $reson;
    my $path = File::Spec->catfile(DRMVC::Util::app_dir('{{app}}'), 'script', 'creator.pl');
    print "
    you can call this script with parametrs:
        
        $path --some_type Some::Name
        
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

CurCreator->create($param);

__DATA__
{{xx}} controller
package {{app}}::Controller::{{lx}}controller{{rx}};
use strict;
use warnings;

use base '{{drmvc}}::Base::Controller';

=head1 NAME

{{app}}::Controller::{{lx}}controller{{rx}}

=head1 DESCRIPTION


=cut

sub index :Index {
    my $class = shift;
    my $app = {{app}}->instance;
    $app->res->status(200);
    $app->res->content_type('text/html; charset=utf-8');
    my $body = "<h4>{{app}}::Controller::{{lx}}controller{{rx}}</h4>";
    $app->res->content_length(length $body);
    $app->res->body($body);
        
    return;
}



1;
__END__

{{xx}} model
package {{app}}::Model::{{lx}}model{{rx}};
use strict;
use warnings;

use base '{{drmvc}}::Base::Model';

=head1 NAME

{{app}}::Model::{{lx}}model{{rx}}

=head1 DESCRIPTION


=cut

#sub new {
#    my $class = shift;
#    ...
#    return $self;
#}


1;
__END__

{{xx}} view
package {{app}}::View::{{lx}}view{{rx}};
use strict;
use warnings;

use base '{{drmvc}}::Base::View';

=head1 NAME

{{app}}::View::{{lx}}view{{rx}}

=head1 DESCRIPTION


=cut

#sub new {
#    my $class = shift;
#    ...
#    return $self;
#}

sub process {
    # my $self = shift;
    my $class = shift;
    
    my $app = {{app}}->instance;
    
    $app->res->status(200);
    $app->res->content_type($app->stash->{content_type} || 'text/html; charset=utf-8') unless $app->res->content_type;
    my $out = 'You need change {{app}}::View::{{lx}}view{{rx}}::process';
    $app->res->content_length(length $out);
    $app->res->body($out);
    
    # clear memory
    undef $out;
    
    return;
}

1;
__END__

{{xx}} exception
package {{app}}::Exception::{{lx}}exception{{rx}};
use strict;
use warnings;

use base '{{drmvc}}::Base::Exception';

=head1 NAME

{{app}}::Exception::{{lx}}exception{{rx}}

=head1 DESCRIPTION


=cut

sub process {
    my $self = shift;
    my $app = {{app}}->instance;
    
    # See: DRMVC::Exception::* for example
    
    $app->res->status({{exception}});
    $app->res->content_type("text/plain; charset=utf-8");
    my $mess = 'Exception: {{exception}}';
    $app->res->content_length(length $mess);
    $app->res->body($mess);
    
    return; 
}

1;
__END__

{{xx}} attribute
package {{app}}::Extend::Controller::Attributes::{{lx}}attribute{{rx}};
use strict;
use warnings;

use base '{{drmvc}}::Base::AttributeDescription';

=head1 NAME

{{app}}::Extend::Controller::Attributes::{{lx}}attribute{{rx}}

=head1 DESCRIPTION

Now, you can used {{lx}}attribute{{rx}} as attirbute in controllers.
For example:

    package {{app}}::Controller::Some;
    ....
    sub foo :LocalPath('foo') :{{lx}}attribute{{rx}}(....) { ... }

=cut

sub init {
    my $class = shift;
    my $value = shift;
    
    # ....
    
    # undef == this attribute has been ignored 
    return undef;
}

sub call_description_coerce {
    my $class   = shift;
    my DRMVC::Controller::CallDescription $desc    = shift;
    my $value   = shift;
    
    # .....
    
    return 1;
}

1;
__END__

@@ favicon.ico
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAABmJLR0T///////8JWPfcAAAACXBI
WXMAAABIAAAASABGyWs+AAAA1klEQVRIx+VUOw6EIBCdMRtKjVewwlBxB1dP4CX1LsSCBBo9hBeY
LXb9REPAT7KFrwPy5r03DAA8HQgA0DRERER1vTpAxLbdE4wxpqoAGMvzJFn2s4yIyM1z1Y9cglvC
WfiCRVvCXUamTvk6GrkKnDUyCXPOeRy7hWcd+uFowmFARFzW0wwcBfb9N99x6j2Irpe4hr9fwcs3
JNuhstbacQRgLDChp77zCrTWuizDp9kl6Hs9OwNKKVUUAEIIsf7pjiLUyGyg67ru/QaQUso0DW/h
3R15Hj6ZeIuFFsO1ZwAAAABJRU5ErkJggg==