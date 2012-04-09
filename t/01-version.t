#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 1;

sub get_changelog_version {
	open my $fh, '<', 'Changes' or
		BAIL_OUT("Could not open ./Changes: $!");

	my $first_row = <$fh>;
	close $fh;

	my ($version) = $first_row =~ /^([0-9]+\.[0-9]+),/;
	return $version;
}

sub get_script_version {
	open my $fh, '<', 'youtube_title.pl' or
		BAIL_OUT("Could not open ./youtube_title.pl: $!");

	my ($vervar) = grep {
		/^(?:my|our)\s*\$VERSION\s*=\s*(["']?)[0-9]+\.[0-9]+\1\s*;/
	} <$fh>;
	close $fh;

	my ($version) = $vervar =~ /([0-9]+\.[0-9]+)/;
	return $version;
}

is(
	get_script_version(),
	get_changelog_version(),
	'Changelog and script version match'
);
