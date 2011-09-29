#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Plack::Builder;
use Plack::App::DRMVC;

builder {
      Plack::App::DRMVC->new(conf_path => 'conf.ini');
};
