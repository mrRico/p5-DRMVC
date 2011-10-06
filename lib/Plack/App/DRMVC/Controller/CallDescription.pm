package Plack::App::DRMVC::Controller::CallDescription;
use strict;
use warnings;

sub new {
    my $class = shift;    
    my %param = @_;
    
    bless {
       'connect'        => '', 
       'action'         => $param{'action'},
       'methods'        => undef,
       'match_callback' => undef,
       'match_callback_arr' => []
    }, $class;
}

# rw
sub connect {
    my $self = shift;
    if (@_) {
       $self->{'connect'} = $_[0];
       return 1; 
    } else {
       $self->{'connect'};
    }
}

# r
sub action {$_[0]->{'action'}}
sub action_class {$_[0]->action->[0]}
sub action_method {$_[0]->action->[1]}

# rw
sub http_methods {
    my $self = shift;
    if (@_) {
       $self->{'methods'} = [@_];
       return 1; 
    } else {
       wantarray ? @{$self->{'methods'}|| []} : $self->{'methods'};
    }
}

# w
sub add_match_callback {
    my $self = shift;
    return unless @_;
    push @{$self->{'match_callback_arr'}}, @_;
    return 1;    
}


sub _prepare_match_callback_arr {
    my $self = shift;
    return unless $self->{match_callback_arr};
    my @sub = grep {(reftype $_ || '') eq 'CODE'} @{$self->{match_callback_arr}};
    return unless @sub;
    $self->{match_callback} = sub {
        for (@sub) {
            last unless $_->(@_);
        }
    };
}

sub _make_decription {
    my $self = shift;
    return unless $self->connect;
    $self->_prepare_match_callback_arr;
    
    return {
        'connect' => $self->connect,
        'action'  => $self->action,
        'methods' => scalar $self->http_methods,
        'match_callback' => $self->{match_callback}
    };
}


1;
__END__
