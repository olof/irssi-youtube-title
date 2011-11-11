package Irssi;
use warnings;
use strict;
use base qw/Exporter/;
our @ISA = qw/Exporter/;
our @EXPORT = qw/MSGLEVEL_CLIENTCRAP/;

my $settings = { };

sub signal_add { 1 };
sub settings_add_bool { 1 };

sub settings_get_bool { 
	my $k = shift;
	return $settings->{$k}
}

1;
