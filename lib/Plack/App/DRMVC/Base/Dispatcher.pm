package Plack::App::DRMVC::Base::Dispatcher;
use strict;
use warnings;

use Plack::Util;
use Cwd qw();
use HTTP::Date qw();
use Data::Util qw();
use Module::Load qw();

use Plack::App::DRMVC::Controller::CallDescription;

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

# import mvc to Plack::App::DRMVC
sub Plack::App::DRMVC::model {$_[0]->disp->{m}->{$_[1]}}
sub Plack::App::DRMVC::view  {
	my $bi = shift;
	if (@_) { 
	   my $view_class = $bi->disp->{v}->{$_[0]};
	   $bi->{view} = $view_class;
	   return 1;
	} else {
		return $bi->{view} || $bi->disp->{v}->{'TT'};
	}
}

# TODO: сделать аналоги каталиста
#sub Plack::App::DRMVC::visit {$_[0]->disp->{c}->{$_[1]}}

sub __add_mvc {
    my $self = shift;
    my $type = shift;
    my $class = shift;
    
    # add short name
    $self->{$type}->{$class->__short_name} = $class;
    # add full name
    $self->{$type}->{$class} = $class;
    
    if ($type eq 'c') {
        no strict 'refs';
        my $subinfo = ${$class."::_attr"};
        use strict 'refs';
        foreach (keys %$subinfo) {
            my $sub_name = (Data::Util::get_code_info(delete $subinfo->{$_}->{code}))[1];            
            my $desc = Plack::App::DRMVC::Controller::CallDescription->new(action => [$class, $sub_name]);            
            Plack::App::DRMVC::Controller::AttributesResolver->new->call_description_coerce($subinfo->{$_}, $desc);
            my $final_desc = $desc->_make_decription;
            next unless $final_desc;
            Plack::App::DRMVC->instance->router->add_rule(%$final_desc);
        }
    }
    
    return;
}

sub process {
    my $self = shift;
    my $bi = Plack::App::DRMVC->instance;
    
    if ($bi->match->{type} eq 'controller') {
        my $class      = $bi->match->{action}->[0];
        my $sub_name   = $bi->match->{action}->[1];
        $class->$sub_name($bi->match->{name_segments});
        
        unless ($bi->res->body) {
            $bi->view->process;
        } else {
            # if set custom body accept this
            $bi->res->status(200) unless $bi->res->status;
            $bi->res->content_type("text/html; charset=utf-8") unless $bi->res->content_type;
            $bi->res->content_length(length $bi->res->body) unless $bi->res->content_length;
        }
        $bi->exception(200);
    }
    
    if ($bi->match->{type} eq 'static') {
        # static
        my $match = $bi->match;
        my @stat = stat $match->{file};
        my $lm = HTTP::Date::time2str($stat[9]);
        my $ms = $bi->req->headers->header('If-Modified-Since') || '';
        if ($ms eq $lm) {
           # not change - get from user cache
           $bi->res->status(304);
           $bi->res->content_type("text/plain; charset=utf-8");
           my $mess = 'Not Modified';
           $bi->res->content_length(length $mess);
           $bi->res->body($mess);
           $bi->exception(304);
        }        
        $bi->res->status(200);
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

1;
__END__
