package Plack::App::DRMVC::Base::Dispatcher;
use strict;
use warnings;

use Plack::Util;
use Cwd qw();
use HTTP::Date qw();
use Data::Util qw();

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
		return $bi->{view} || $bi->conf->{mvc}->{'view.namespace'}.'::TextXslate';
	}
}
sub Plack::App::DRMVC::visit {$_[0]->disp->{c}->{$_[1]}}

my $AttributesResolver_was_reqired = 0;
sub __add_mvc {
    my $self = shift;
    my $type = shift;
    my $class = shift;
    
    $self->{$type}->{$class->__shot_name} = $class;
    
    unless ($AttributesResolver_was_reqired) {
        require 'Plack::App::DRMVC::Controller::AttributesResolver';
        $AttributesResolver_was_reqired++;
    }
    
    if ($type eq 'c') {
        no strict 'refs';
        my $subinfo = ${$class."::_attr"};
        use strict 'refs';
        
        foreach (keys %$subinfo) {
            my $sub_name = (Data::Util::get_code_info($subinfo->{$_}->{code}))[1];            
            my $desc = Plack::App::DRMVC::Controller::CallDescription->new(action => [$class, $sub_name]);            
            Plack::App::DRMVC::Controller::AttributesResolver->new->call_description_coerce($subinfo->{$_}, $desc);
            my $final_desc = $desc->_make_decription;
            next unless $final_desc;
            Plack::App::DRMVC->instance->router->add_rule(%$final_desc);
        }
    }
    
    return;
}

sub _process {
    my $self = shift;
    my $bi = Plack::App::DRMVC->instance;
    my $match = $bi->_match;
    
    if ($bi->_match->{type} eq 'controller') {
        my $class      = $bi->_match->{action}->[0];
        my $sub_name   = $bi->_match->{action}->[1];
        eval {$class->$sub_name(@{$bi->_match->{segment}})};
        if ($@) {
            $bi->{__bi_match} = {
                type => 'error',
                code => 500,
                desc  => $@
            };
        } else {
            unless ($bi->res->body) {
            	$bi->view->process;
            } else {
                # if set custom body accept this
                $bi->res->status(200) unless $bi->res->status;
                $bi->res->content_type("text/html; charset=utf-8") unless $bi->res->content_type;
                $bi->res->content_length(length $bi->res->body) unless $bi->res->content_length;
            }
        	return;
        };        
        return if $bi->_match->{type} eq 'controller';  
    }
    
    if ($bi->_match->{type} eq 'static') {
        # static
        my $match = $bi->_match;
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
           return;
        }        
        $bi->res->status(200);
        $bi->res->content_type($match->{mime} =~ m!^text/! ? $match->{mime}."; charset=utf-8" : $match->{mime});
        $bi->res->content_length($stat[7]);
        $bi->res->header('Last-Modified'  => $lm);
        
        my $error = 0;
        open(my $fh, "<:raw", $match->{file}) or $error++;
        if ($error) {
            $bi->{__bi_match} = {
                type => 'error',
                code => 500,
                desc  => $!
            };
        } else {
	        Plack::Util::set_io_path($fh, Cwd::realpath($match->{file}));
	        $bi->res->body($fh);
	        return;
        }
    } 

    if ($bi->_match->{type} eq 'error') {
        my $code = $bi->_match->{code};
        # prepare response
        $bi->exception->$code($bi->_match->{desc});
        return;
    };
    
    return;
}

1;
__END__
