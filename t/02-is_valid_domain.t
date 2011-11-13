#!/usr/bin/perl
require 'youtube_title.pl';

package test;
use warnings;
use strict;
use lib qw;t/lib;;
use Test::More tests => 6;

sub f { main::canon_domain(@_) } # short alias

is(f('youtube.com'), 'youtube_com', 'validity of youtube.com');
is(f('www.youtube.com'), 'youtube_com', 'validity of www.youtube.com');
is(f('youtu.be'), 'youtu_be', 'validity of youtu.be');
is(f('www.youtu.be'), 'youtu_be', 'validity of www.youtu.be');
ok(! f('google.com'), 'invalidity of google.com');
ok(! f('www.google.com'), 'invalidity of www.google.com');
