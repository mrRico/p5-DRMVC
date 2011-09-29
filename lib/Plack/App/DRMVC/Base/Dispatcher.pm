package Plack::App::DRMVC::Base::Dispatcher;
use strict;
use warnings;

use Plack::Util;
use Cwd qw();
use HTTP::Date qw();
use Data::Util qw();

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

sub __add_mvc {
    my $self = shift;
    my $type = shift;
    my $shot_name = shift;
    my $class = shift;
    
    $self->{$type}->{$shot_name} = $class;
    
    if ($type eq 'c') {
        # and add routing rule    
        my $router = Plack::App::DRMVC->instance->router;
        my $connect_prefix = $shot_name; 
        unless ($connect_prefix eq 'Root') {
	        $connect_prefix =~ s!:{2}!/!g;
	        $connect_prefix = '/' . lc $connect_prefix;
        } else {
        	$connect_prefix = '';
        }
        
        no strict 'refs';
        my $subinfo = ${$class."::_attr"};
        use strict 'refs';
        
        foreach (keys %$subinfo) {
            my $sub_name = (Data::Util::get_code_info($subinfo->{$_}->{code}))[1];
        	my $connect = '';
        	if (exists $subinfo->{$_}->{LocalConnect}) {
        		$connect = join('/',$connect_prefix,$subinfo->{$_}->{LocalConnect});
        	} elsif (exists $subinfo->{$_}->{GlobalConnect}) {
        		$connect = $subinfo->{$_}->{GlobalConnect};
        	}
        	next unless $connect;
        	my %desc = (
        	   'connect' => $connect, 
        	   'action'  => [$class, $sub_name],
        	   'methods' => $subinfo->{$_}->{methods}
            );
            $router->add_rule(%desc);
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
