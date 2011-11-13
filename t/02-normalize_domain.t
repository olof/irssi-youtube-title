#!/usr/bin/perl
require 'youtube_title.pl';

package test;
use warnings;
use strict;
use lib qw;t/lib;;
use Test::More tests => 8;

sub f { main::normalize_domain(@_) } # short alias

is(f('youtube.com'), 'youtube.com', 'input: youtube.com');
is(f('www.youtube.com'), 'youtube.com', 'input: www.youtube.com');
is(f('youtu.be'), 'youtu.be', 'input: youtu.be');
is(f('www.youtu.be'), 'youtu.be', 'input: www.youtu.be');
is(f('google.com'), 'google.com', 'input: google.com');
is(f('www.google.com'), 'google.com', 'input: www.google.com');
is(f('wwwexample.com'), 'wwwexample.com', 'input: wwwexample.com');
is(f('www'), 'www', 'input: www');
