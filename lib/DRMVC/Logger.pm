package DRMVC::Logger;
use strict;
use warnings;

use Carp;
use Fcntl ':flock';
use IO::File;
use File::Spec;
use Scalar::Util qw();
use Data::Dumper;

my $n = 0;
my $LEVEL = { map { $_ => $n++ } qw(debug info warn error fuck) }; 

# don't used in DRMVC because psgix.logger
sub debug       { shift->_log('error', 'debug', @_) }
sub info        { shift->_log('error', 'info', @_)  }
sub warn        { shift->_log('error', 'warn', @_)  }
sub error       { shift->_log('error', 'error', @_) }
sub fuck        { shift->_log('error', 'fuck', @_)  }

sub new {
    my $class = shift;
    my $app = DRMVC->instance;
    
    if ($app->ini_conf->get('logger', 'log_dir')) {
        unless (-d $app->ini_conf->get('logger', 'log_dir')) {
            # relative path
            $app->ini_conf->add('logger', 'log_dir', File::Spec->catdir(
                $app->ini_conf->get('general', 'root_dir'),
                $app->ini_conf->get('logger', 'log_dir')
            ));
        }
    }
    
    unless (exists $LEVEL->{ $app->ini_conf->get('logger', 'log_level', '') }) {
        carp "Not found 'log_level' in 'logger' section. Set 'debug' level as default.";
        $app->ini_conf->set('logger', 'log_level', 'debug');
    }

    my $self = bless {
      error  => undef,
      error_file_pattern => $app->ini_conf->get('logger', 'error_file'),
      dir    => $app->ini_conf->get('logger', 'log_dir'),
      level  => $app->ini_conf->get('logger', 'log_level'),
      lock   => $app->ini_conf->get('logger', 'flock', 0)
    }, $class;

    unless (
        $app->ini_conf->get('logger', 'error_file')
        and $app->ini_conf->get('logger', 'log_dir') 
        and -d $app->ini_conf->get('logger', 'log_dir')
    ) {
        carp ("Not found 'logger' section in conf.ini. Set Carp::carp as default logger.");
    } else {
        $self->_reinit(time);
    }
    
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

    # skip access
    next unless $self->{'error_file_pattern'};         
    if (Scalar::Util::blessed($self->{error})) {
        $self->{error}->close;
        $self->{error} = undef;
    };
    $self->{error} = IO::File->new;
    my $name = $self->{'error_file_pattern'};
    $name =~ s/%year/$year/;
    $name =~ s/%month/$mon/;
    $name =~ s/%day/$mday/;
    my $path = File::Spec->catfile($self->{dir}, $name);
    $self->{error}->open(">> $path") or croak qq/Can't open log file "$path": $!/;
    binmode $self->{error};

    $self->{reinit_time} = $time - ($time % 86400) + 86400;
    
    return;
}

sub _log {
    my $self = shift;
    my $type = shift;
    my $level = shift;
    
    return if $LEVEL->{$self->{level}} > $LEVEL->{$level};
    
    # Caller # BUG with default logger
    my ($pkg, $line) = (caller())[0, 2];
    ($pkg, $line) = (caller(1))[0, 2] if $pkg eq ref $self;

    # check route
    my $time = time;
    if ($self->{reinit_time} and $self->{reinit_time} < $time) {
        $self->_reinit($time);
    }

    local $Data::Dumper::Indent = 0;
    my $log_str = sprintf(
        '%s [%d:%s] %s (%s line %d)%s',
        scalar(localtime $time),
        $$,
        $level,
        join(' ', map { ref $_ ? Dumper($_) : (defined $_ ? $_ : 'undef') } @_),
        $pkg,
        $line,
        "\n"
    );

    
    my $handle = $self->{$type};
    unless ($handle) {
        print STDERR $log_str;
    } else {
        # lock
        flock $handle, LOCK_EX if $self->{lock};
        # write
        $handle->syswrite($log_str);
        # unlock
        flock $handle, LOCK_UN if $self->{lock};
    }
    
    $self;
}

sub DESTROY {
    my $self = shift;
    
    if (Scalar::Util::blessed($self->{error})) {
        $self->{error}->close;
        undef $self->{error};
    };
    
    undef $self;
    return;
}

1;
__END__
