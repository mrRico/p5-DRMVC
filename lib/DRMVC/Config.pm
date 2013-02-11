package DRMVC::Config;
use strict;
use warnings;

use Carp qw();
our $DEBUG = 0; 
sub carp ($) { Carp::carp(@_) if $DEBUG }
sub croak ($) { Carp::croak(@_) }

use File::Spec;
use Cwd;
use Hash::Merge;
use List::Util qw(first);

sub PARENT      () {'PARENT_MERGE_BEHAVOIR'   }
sub CHILD       () {'CHILD_MERGE_BEHAVOIR'    }
sub RESOLVER    () {'RESOLVER_MERGE_BEHAVOIR' }

Hash::Merge::specify_behavior(
    # $_[0] - target, $_[1] - parent data
    # behavior as base class - add if not exists and override if not defined
    {
        SCALAR => {
                SCALAR => sub { $_[0] },
                ARRAY  => sub { $_[0] },
                HASH   => sub { $_[0] },
        },
        ARRAY => {
                SCALAR => sub { $_[0] },
                ARRAY  => sub { $_[0] },
                HASH   => sub { $_[0] }, 
        },
        HASH => {
                SCALAR => sub { $_[0] },
                ARRAY  => sub { $_[0] },
                HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
        },
    },  
    PARENT() 
);

Hash::Merge::specify_behavior(
    # $_[0] - target, $_[1] - child data
    # behavior as base class - add if not exists and override
    {
        SCALAR => {
                SCALAR => sub { $_[1] },
                ARRAY  => sub { $_[1] },
                HASH   => sub { $_[1] },
        },
        ARRAY => {
                SCALAR => sub { $_[1] },
                ARRAY  => sub { $_[1] },
                HASH   => sub { $_[1] }, 
        },
        HASH => {
                SCALAR => sub { $_[1] },
                ARRAY  => sub { $_[1] },
                HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
        },
    },  
    CHILD() 
);

my $rESOL = qr{};
my $vESOL = {};
sub _vesol {
    my $val = shift;
    $val =~ s/$rESOL/$vESOL->{$1}||'${'.$1.'}'/ge;
    return $val;  
}

sub strip {
    my $s = shift;
    $s =~ s/^\s*//;
    $s =~ s/\s*$//;
    return $s;
}

Hash::Merge::specify_behavior(
    # $_[0] - target, $_[1] - target
    # replace $tokens to similar value from 'general' section
    {
        SCALAR => {
                SCALAR => sub { _vesol($_[1]) },
                ARRAY  => sub { die "never happens!" },
                HASH   => sub { die "never happens!" },
        },
        ARRAY => {
                SCALAR => sub { die "never happens!" },
                ARRAY  => sub {  [map {_vesol($_)} @{$_[1]}] },
                HASH   => sub { die "never happens!" }, 
        },
        HASH => {
                SCALAR => sub { die "never happens!" },
                ARRAY  => sub { die "never happens!" },
                HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
        },
    },  
    RESOLVER() 
);

my $singletone = undef;
sub instance {
    my $proto = shift;
    my $self = ref $proto ? $proto : $singletone;  
}

sub new {
    my $class = shift;
    my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    unless ($param->{file}) {
        croak("argument 'file' is missed");
    }
    $param->{file} = Cwd::abs_path($param->{file});
    
    if ($class->instance) {
        if ($class->instance->file eq $param->{file}) {
            return $class->instance; 
        } else {
            croak("instance already exists");
        }
    }
    my $self = bless {
        file => $param->{file},
        sections => {
            general => {}
        },
        inlude_abspath => $param->{inlude_abspath} || 0 
    }, $class; 
    
    $self->{sections} = $self->init();
    
    if ($param->{singletone}) {
        $singletone = $self;
    }
    
    return $self;
}

sub file {
    my $proto = shift;
    my $self = $proto->instance || $proto;
    $self->{file}; 
}

sub _check_k_type {
    my $k = shift;
    if (my @found = $k =~ /([^\s]+)\s*({|\[)\s*([^\s]+)?\s*(?:\]|})$/o) {
        $found[1] = $found[1] eq '{' ? 'HASH' : 'ARRAY';
        return @found; 
    } else {
        # simple key
        return($k, 'SIMPLE');
    }
}

sub init {
    my ($self, $merge_strategy, $file, $ret, @myparents) = @_;
    $merge_strategy ||= PARENT;
    $file ||= $self->file;
    $ret  ||= $self->{sections};
    
    unless (-e $file and -f _) {
        croak("can't find file '$file'");
    }
    
    # PARSE
    my $sections = {};
    my (@parent, @child);
    my $cur_section = 'general';
    open(IN, "<$file") or croak("can't open '$file': $!");
        while (my $irow = <IN>) {
            chomp $irow;
            next if (not $irow or scalar $irow =~ /^\s*(#(^parent|myparent|child)\s+.*+)?$/o);
            $irow =~ s/^\s+//;
            my $r = index($irow, '#');
            if ($r > 0) {
                $irow = substr($irow, 0, $r);
            }
            
            if ($r == 0) {
                # pragma
                my ($type, $inc_file) = $irow =~ /^#(parent|myparent|child)\s+([\w\/\.]+)$/o;
                next unless defined $inc_file; 
                my $copy = $inc_file;
                unless ($self->{inlude_abspath}) {
                    my $dir = [File::Spec->splitpath($file)]->[1]; 
                    $inc_file = File::Spec->catfile($dir, $inc_file);
                }
                $inc_file = Cwd::abs_path($inc_file);
                unless ($inc_file) {
                    croak("[$file]: don't found file from directive: #$type $copy");
                }
                if ($type eq 'myparent') {
                    unless (first {$irow eq $inc_file} @myparents) {
                        croak("[$file]: directive is unsuccess: #$type $copy");
                    }
                } else {
                    $type eq 'parent' ? push(@parent, $inc_file) : push(@child, $inc_file);
                }                
            } elsif (index($irow, '[') == 0) {
                # new section
                my ($section_name) = $irow =~ /\[\s*([^\s]+)\s*]/o;
                next unless $section_name;
                $cur_section = $section_name;
                # check or create
                $sections->{$cur_section} ||= {};
            } else {
                # values
                my ($k, $v) = split('=', $irow, 2);
                unless (defined $v and length $k) {
                    carp("[$file]: skip row with: $irow");
                    next;
                }
                ($k, $v) = map {strip($_)} ($k, $v);
                my @key_info; ($k, @key_info) = _check_k_type($k);
                if ($key_info[0] eq 'SIMPLE') {
                    $sections->{$cur_section}->{$k} = $v;
                } elsif ($key_info[0] eq 'HASH') {
                    $sections->{$cur_section}->{$k}->{defined $key_info[1] ? $key_info[1] : '_default'} = $v;
                } else {
                    $sections->{$cur_section}->{$k} = [] unless ref $sections->{$cur_section}->{$k} eq 'ARRAY';
                    if (length $v) {
                        push @{$sections->{$cur_section}->{$k}}, defined $key_info[1] ? split(qr{$key_info[1]}, $v) : $v;
                    }
                }   
            }
        }
    close(IN);
    
    push @myparents, $file;
    
    # MERGE (join relationship)
    my $merge = Hash::Merge->new();
    
    if (@parent) {
        $merge->set_behavior(PARENT);
        $sections = $merge->merge($sections, $self->init(PARENT, $_, {}, @myparents)) for @parent;
    }
    
    if (@child) {
        $merge->set_behavior(CHILD);
        $sections = $merge->merge($sections, $self->init(CHILD, $_, {}, @myparents)) for @child;
    }
    
    # RESOLVE (all $tokens will be resolved of definition in general section)
    my @g_keys = keys %{$sections->{general} || {}};
    if (@g_keys) {
        my $re = '\${('.join('|', map {quotemeta($_)} @g_keys).')}';
        $rESOL = qr{$re};
        my $hash = {};
        $hash->{$_} = $sections->{general}->{$_} for @g_keys;
        $vESOL = $hash;
        $merge->set_behavior(RESOLVER);
        $sections = $merge->merge($sections, $sections);        
    }
    
    # MERGE (with income hash)
    $merge->set_behavior($merge_strategy);  
    $ret = $merge->merge($ret, $sections);
    
    undef $merge;
    undef $sections;
    
    return $ret;
}

sub sections {
    my $proto = shift;
    my $self = $proto->instance || $proto;
    my @keys = keys %{$self->{sections}};
    return wantarray ? @keys : \@keys;
}

sub section {
    my $proto = shift;
    my $self = $proto->instance || $proto;
    my $section = shift || '';
    return $self->{sections}->{$section};
}

sub get {
    return _getset(0, @_) 
}

sub getset {
    return _getset(1, @_) 
}

sub set {
    return !!_getset(1, @_);
}

sub add {
    my $proto = shift;
    my $self = $proto->instance || $proto;
    my $section_name = shift || '';
    unless ($section_name) {
        carp "where's no section_name for a section";
        return;
    } 
    my $section = $self->{sections}->{$section_name} ||= {};
    my $key = shift || '';
    unless ($key) {
        carp "where's no key for a section '$section'";
        return;
    }
    $section->{$key} = pop @_;
}

sub _getset {
    my $set = shift;
    my $proto = shift;
    my $self = $proto->instance || $proto;
    my $section_name = shift || '';
    my $section = $self->{sections}->{$section_name};
    unless ($section) {
        if ($set) {
            return $self->add($section_name, @_);
        } else {
            carp "where's no section";
            return;
        }
    }
    my $key = shift || '';
    unless ($key) {
        carp "where's no key '$key' section '$section'";
        return;
    }
    my $key_section = $section->{$key};
    unless (defined $key_section) {
        if ($set) {
            return $self->add($section_name, $key, @_);
        } else {
            carp "where's no value for '$key' in section '$section_name'";
            return;
        }
    }
    my $ref = ref $key_section;
    unless ($ref) {
        my $default = pop @_;
        if (defined $default and not length $key_section) {
            if ($set) {
                $section->{$key} = $default;
            }
            return $default;
        } else {
            return $key_section;
        }
    } elsif ($ref eq 'HASH') {
        my $hash_key = shift;
        my $default = pop @_;
        unless (exists $key_section->{$hash_key}) {
            $key_section->{$hash_key} = $default if $set;
            return $default;
        } else {
            return $key_section->{$hash_key};
        }
    } elsif ($ref eq 'ARRAY') {
        my $range = shift;
        my $default = pop @_;
        if (ref $range eq 'ARRAY' and not defined $default) {
            $default = $range;
            $range = undef;
        }
        my @ret = ();
        if (defined $range) {
            $range = [$range] unless ref $range eq 'ARRAY';
            @ret = @{$key_section}[@$range];
        } else {
            @ret = @$key_section;
        }
        if (defined $default and not @ret and ref $default eq 'ARRAY') {
            if ($set) {
                @$key_section = @$default; 
            }
            return $default;
        } else {
            return \@ret;
        }
    } else {
        croak("Strange value in section '$section_name' under key '$key'");
    }    
}


1;
__END__
