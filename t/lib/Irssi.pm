package Irssi;
use warnings;
use strict;
use base qw/Exporter/;
our @ISA = qw/Exporter/;
our @EXPORT = qw/MSGLEVEL_CLIENTCRAP/;

sub signal_add { 1 };
sub settings_add_bool { 1 };

1;
