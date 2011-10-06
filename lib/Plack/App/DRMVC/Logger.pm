package Plack::App::DRMVC::Logger;
use strict;
use warnings;

use Carp;
use Fcntl ':flock';
use IO::File;
use File::Spec;
use Date::Manip::Date;
use Scalar::Util qw();

my $n = 0;
my $LEVEL = { 
    (map { $_ => $n++ } qw(debug info notice warning error critical alert emergency)),
    fatal   => 5,
    admin   => 6
}; 

sub debug       { shift->_log('error', 'debug', @_) }
sub info        { shift->_log('error', 'info', @_) }
sub notice      { shift->_log('error', 'notice', @_) }
sub warn        { shift->_log('error', 'warning', @_) }
sub warning     { shift->_log('error', 'warning', @_) }
sub error       { shift->_log('error', 'error', @_) }
sub err         { shift->_log('error', 'error', @_) }
sub critical    { shift->_log('error', 'critical', @_) }
sub crit        { shift->_log('error', 'critical', @_) }
sub fatal       { shift->_log('error', 'fatal', @_) }
sub alert       { shift->_log('error', 'alert', @_) }
sub admin       { shift->_log('error', 'admin', @_) }
sub emergency   { shift->_log('error', 'emergency', @_) }
sub emerg       { shift->_log('error', 'emergency', @_) }


sub access      { shift->_log('access', 'emergency', @_) }

sub new {
    my $class = shift;
    my $app = Plack::App::DRMVC->instance;
    unless (
        $app->ini_conf->{logger} and 
        $app->ini_conf->{logger}->{log_dir} and
        -d $app->ini_conf->{logger}->{log_dir} and
        -w _ and
        $app->ini_conf->{logger}->{error_file}
    ) {
        carp "Not found 'logger' section in conf.ini. Set Carp::carp as default logger.";
        return sub {Carp::carp(join ', ', @_)};
    };
    
    my $level = $app->ini_conf->{logger}->{log_level} || '';
    unless (exists $LEVEL->{$level}) {
        carp "Not found 'log_level' in 'logger' section. Set 'debug' level as default.";
        $level = 'debug';
    }
    
    my $hash = {
      error  => undef,
      error_file_pattern => $app->ini_conf->{logger}->{error_file},
      dir    => $app->ini_conf->{logger}->{log_dir},
      level  => $level,
    };
    if ($app->ini_conf->{logger}->{access_file}) {
        $hash->{access} = undef;
        $hash->{access_file_pattern} = $app->ini_conf->{logger}->{access_file};
    };
    
    my $self = bless $hash, $class;
    $self->_reinit(time);
    return sub {$self->log(@_)};
}

sub log {
    my $self = shift;
    my ($level, $msg) = @_ == 1 ? ('error', $_[0]) : ($_[0], $_[1]);   
    $level = 'error' unless $LEVEL->{$level};
    $self->$level($msg);
    return;
}

sub _reinit {
    my $self = shift;
    my $time = shift;
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime $time;
    $year += 1900; $mon = sprintf('%02d',$mon+1); $mday = sprintf('%02d',$mday);
    for ('error', 'access') {
        # skip access
        next unless $self->{$_.'_file_pattern'};         
        if (Scalar::Util::blessed($self->{$_})) {
            $self->{$_}->close;
            $self->{$_} = undef;
        };
        $self->{$_} = IO::File->new;
        my $name = $self->{$_.'_file_pattern'};
        $name =~ s/%year/$year/;
        $name =~ s/%month/$mon/;
        $name =~ s/%day/$mday/;
        my $path = File::Spec->catfile($self->{dir}, $name);
        $self->{$_}->open(">> $path") or croak qq/Can't open log file "$path": $!/;
        binmode $self->{$_};
    }
    $self->{reinit_time} = Date::Manip::Date->new('tomorrow')->secs_since_1970_GMT;    
    
    return;
}

sub _log {
    my $self = shift;
    my $type = shift;
    my $level = shift;
    
    return if $LEVEL->{$self->{level}} > $LEVEL->{$level};
    
    # Caller
    my ($pkg, $line) = (caller())[0, 2];
    ($pkg, $line) = (caller(1))[0, 2] if $pkg eq ref $self;

    # check route
    my $time = time;
    unless ($self->{reinit_time} > $time) {
        $self->_reinit($time);
    }

    my $log_str = sprintf(
        '%s%s [%d:%s] %s (%s line %d)',
        "\n",
        scalar localtime $time,
        $$,
        $level,
        join("\n\t", (@_ ? @_ : '')),
        $pkg,
        $line
    );

    
    my $handle = $self->{$type};
    unless ($handle) {
        carp $log_str;
    } else {
        # lock
        flock $handle, LOCK_EX;
        # write
        $handle->syswrite($log_str);
        # unlock
        flock $handle, LOCK_UN;
    }
    
    $self;
}

sub DESTROY {
    my $self = shift;
    
    for ('error', 'access') {
        if (Scalar::Util::blessed($self->{$_})) {
            $self->{$_}->close;
            $self->{$_} = undef;
        };
    }
    
    undef $self;
    return;
}

1;
__END__
