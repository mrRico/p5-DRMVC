package Plack::App::DRMVC::ExceptionManager;
use strict;
use warnings;

use Data::Dumper qw();

=head1 NAME

Plack::App::DRMVC::ExceptionManager

=cut
#our $AUTOLOAD;

sub new {bless {exc_class => {}}, shift}

sub _add_exception {
    my $self    = shift;
    my $package = shift;
    my $short_name = shift;
    $self->{exc_class}->{$short_name} = $package;
    return;
}

sub _500 {
    my $self  = shift;
    my $error = shift;
    
    my $app = Plack::App::DRMVC->instance;

    # condom-ization
    $app->{res} = Plack::Response->new if (not Scalar::Util::blessed($app->res) or not $app->res->isa('Plack::Response')); 

    $app->res->status(500);
    $app->res->content_type('text/plain; charset=utf-8');
    my $body = "Internal error";
    $app->res->content_length(length $body);
    $app->res->body($body);
    $app->log(fatal => $error);
    
    return;
}

# NOTE: не существующие ошибки - это 500
sub make {
    my $self = shift;
    die $self->_create(@_);
}

sub _create {
    my $self = shift;
    my $code = shift;
    if ($self->{exc_class}->{$code}) {
        $self->{exc_class}->{$code}->new(@_);
    } else {
        my @err = 'Not found exception class for code '.$code;
        push @err, 'call with params', @_ if @_;
        my $dump_args = Data::Dumper->new([\@err])->Indent(0)->Dump;
        $self->{exc_class}->{500}->new(error => $dump_args);
    }
}

#sub DESTROY {}
#
#sub AUTOLOAD {
#    my $self = shift;
#    
#    $AUTOLOAD =~ /show_(\d+)$/;
#    my $name = $1;
#    
#    # если не нашли нужного класса для ошибки, но обращение было, вызываем дефолтный обработчик ошибки,
#    # отдающий 500-ю ошибку
#    if (exists $self->{exc_class}->{$name}) {
#        eval {$self->{exc_class}->{$name}->process(@_)};
#        if ($@) {
#            Plack::App::DRMVC->instance->app->log(fatal => $@);
#            return $self->_500($@);
#            undef $@;
#        }
#        return;
#    } else {
#        # call when app wrong used $app->exception
#        my $dump_args = Data::Dumper->new([\@_])->Indent(0)->Dump;
#        my $msg = "Exception with code '$name' not implemented. It was call with arguments: $dump_args";
#        return $self->_500($msg);
#    }
#}


=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
