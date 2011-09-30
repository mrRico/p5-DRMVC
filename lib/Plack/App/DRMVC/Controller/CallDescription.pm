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
       $self->{'connect'} = [@_];
       return 1; 
    } else {
       wantarray ? @{$self->{'connect'}|| []} : $self->{'connect'};
    }
}

# w
sub add_match_callback {
    my $self = shift;
    return unless @_;
    push @{$self->{'match_callback_arr'}}, @_
    return 1;    
}

sub _make_decription {
    my $self = shift;
    
    
    
}


1;
__END__
