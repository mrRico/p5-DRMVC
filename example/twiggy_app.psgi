#!/usr/bin/perl
use strict;
use warnings;

use File::Spec;
use Cwd 'abs_path';
use lib File::Spec->catdir(sub{local @_=File::Spec->splitdir(File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__));@_[0..$#_-1]}->()));@_[0..$#_-1]}->(),'lib'), File::Spec->catdir(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); @_[0..$#_-1]}->(),'lib');

use Plack::Builder;
use Plack::App::DRMVC;

      use Twiggy::Server;

      my $server = Twiggy::Server->new(
          host => '127.0.0.1',
          port => 3000,
      );
      $server->register_service(
        builder {
              Plack::App::DRMVC->get_app(
                    conf_path => File::Spec->catfile(sub{local @_ = File::Spec->splitpath(abs_path(__FILE__)); $_[$#_] = 'conf.ini'; @_}->())
              );
        }
      );

      AE::cv->recv;

