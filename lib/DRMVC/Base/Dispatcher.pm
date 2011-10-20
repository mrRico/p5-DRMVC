package DRMVC::Base::Dispatcher;
use strict;
use warnings;

=head1 NAME

DRMVC::Base::Dispatcher

=head1 DESCRIPTION

There is base Dispatcher for you app.

By default supporting methods B<model>, B<view>, B<forward>, B<detach> to your App.

=head1 SYNOPSIS

    my $app = MyApp->instance;
    
    # get class name or instance from MyApp::Model::Some::Data 
    $app->model('Some::Data');
    # or
    $app->model('MyApp::Model::Some::Data');
    
    # accessor for view 
    $app->view;
    $app->view('JSON');
    
    # dispatchers object
    my $disp = MyApp->instance->disp
    
    # others methods have custom implementation in MyApp::Extend::Dispatcher

=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

use Plack::Util;
use Cwd qw();
use HTTP::Date qw();
use Data::Util qw();
use Module::Load qw();
use Scalar::Util qw();

use DRMVC::Controller::CallDescription;

sub new {bless{}, shift}

sub _add_model {
    my $self = shift;
    $self->__add_mvc('m',@_);
}

sub _add_view {
    my $self = shift;
    $self->__add_mvc('v',@_);
}

sub _add_controller {
    my $self = shift;
    $self->__add_mvc('c',@_);
}

sub __add_mvc {
    my $self  = shift;
    my $type  = shift;
    my $proto_class = shift;
    my $proto = shift;
    
    # add short name
    $self->{$type}->{$proto_class->__short_name} = $proto;
    # add full name
    $self->{$type}->{$proto_class} = $proto;
    
    if ($type eq 'c') {
        no strict 'refs';
        my $subinfo = ${$proto_class."::_attr"};
        use strict 'refs';
        foreach (keys %$subinfo) {
            my $sub_name = (Data::Util::get_code_info(delete $subinfo->{$_}->{code}))[1];            
            my $desc = DRMVC::Controller::CallDescription->new(action => [$proto_class, $sub_name]);            
            DRMVC::Controller::AttributesResolver->new->call_description_coerce($subinfo->{$_}, $desc);
            my $final_desc = $desc->_make_decription;
            next unless $final_desc;
            DRMVC->instance->router->add_rule(%$final_desc);
        }
    }
    
    return;
}

sub process {
    my $self = shift;
    my $bi = DRMVC->instance;
    
    if ($bi->match->{type} eq 'controller') {
        my $class      = $bi->match->{action}->[0];
        my $sub_name   = $bi->match->{action}->[1];
        $class->$sub_name($bi->match->{name_segments});        
        $bi->view->process unless $bi->res->body;        
        $bi->exception($bi->res->status);
    }
    
    if ($bi->match->{type} eq 'static') {
        # static
        my $match = $bi->match;
        my @stat = stat $match->{file};
        my $lm = HTTP::Date::time2str($stat[9]);
        my $ms = $bi->req->headers->header('If-Modified-Since') || '';
        if ($ms eq $lm) {
           # not change - get from user cache
           $bi->exception(304);
        }        
        $bi->res->content_type($match->{mime} =~ m!^text/! ? $match->{mime}."; charset=utf-8" : $match->{mime});
        $bi->res->content_length($stat[7]);
        $bi->res->header('Last-Modified'  => $lm);
        
        my $error = 0;
        open(my $fh, "<:raw", $match->{file}) or $error++;
        if ($error) {
            $bi->exception(500, error => $!);
        } else {
	        Plack::Util::set_io_path($fh, Cwd::realpath($match->{file}));
	        $bi->res->body($fh);
	        $bi->exception(200);
        }
    } 

    if ($bi->match->{type} eq 'error') {
        my $code = $bi->match->{code};
        # prepare response
        $bi->exception($code, error => $bi->match->{desc});
    };
    
    die "Unknown match type";
}

sub forward {$_[0]->disp->{c}->{$_[1]}}

sub detach {
    eval {
        $_[0]->forward($_[1]);
        die "__";
    };
    unless ($@ eq "__") {
        die $@;
    } else {
        undef $@;
    }
}

1;
__END__
