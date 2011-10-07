#!/usr/bin/perl
use strict;
use warnings;

use File::Spec;
use Cwd 'abs_path';
use lib File::Spec->catdir(sub{local @_=File::Spec->splitdir(File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__));@_[0..$#_-1]}->()));@_[0..$#_-1]}->(),'lib'), File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); @_[0..$#_-1]}->(),'lib');

use Plack::Builder;
use Plack::App::DRMVC;

use Plack::Test;
use Test::More;

  pass('*' x 10);
  
  # named params
  test_psgi
      app => builder {
          Plack::App::DRMVC->get_app(
                conf_path => File::Spec->catfile(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); $_[$#_] = 'conf.ini'; @_}->())
          );
      },
      client => sub {
          my $cb  = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          like $res->content, qr/Hello, word/, "test Root controller";
      };

    pass('*' x 10);
    print "\n";
    done_testing;      
