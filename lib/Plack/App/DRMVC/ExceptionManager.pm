package Plack::App::DRMVC::ExceptionManager;
use strict;
use warnings;

use Data::Dumper qw();

=head1 NAME

Plack::App::DRMVC::ExceptionManager

=cut
our $AUTOLOAD;

sub new {bless {exc_class => {}}, shift}

sub _add_exception {
    my $self    = shift;
    my $package = shift;
    return unless $package =~ /(\d+)$/;
    $self->{exc_class}->{$1} = $package;
    return;
}

sub _500 {
    my $self  = shift;
    my $error = shift;
    
    my $app = Plack::App::DRMVC->instance->app;
    $app->res->status(500);
    $app->res->content_type('text/plain; charset=utf-8');
    my $body = "Internal error";
    $app->res->content_length(length $body);
    $app->res->body($body);
    $app->log(fatal => $error);
    
    return;
}

sub error {
    my $self = shift;
    my $code = 
    
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    
    $AUTOLOAD =~ /show_(\d+)$/;
    my $name = $1;
    
    # если не нашли нужного класса для ошибки, но обращение было, вызываем дефолтный обработчик ошибки,
    # отдающий 500-ю ошибку
    if (exists $self->{exc_class}->{$name}) {
        eval {$self->{exc_class}->{$name}->process(@_)};
        if ($@) {
            Plack::App::DRMVC->instance->app->log(fatal => $@);
            return $self->_500($@);
            undef $@;
        }
        return;
    } else {
        # call when app wrong used $app->exception
        my $dump_args = Data::Dumper->new([\@_])->Indent(0)->Dump;
        my $msg = "Exception with code '$name' not implemented. It was call with arguments: $dump_args";
        return $self->_500($msg);
    }
}


=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
