#!/usr/bin/perl
require 'youtube_title.pl';

package test;
use warnings;
use strict;
use lib qw;t/lib;;
use Test::More tests => 21;
use Data::Dumper;

sub youtube_com { "http://youtube.com/watch?v=" . shift }
sub youtu_be    { "http://youtu.be/" . shift }
sub www_youtube_com { "http://www.youtube.com/watch?v=" . shift }
sub www_youtu_be    { "http://www.youtu.be/" . shift }

sub https_youtube_com { "https://youtube.com/watch?v=" . shift }
sub https_youtu_be    { "https://youtu.be/" . shift }
sub https_www_youtube_com { "https://www.youtube.com/watch?v=" . shift }
sub https_www_youtu_be    { "https://www.youtu.be/" . shift }


sub has_ids {
	my $privmsg = shift;
	my $expected = shift;
	my $description = shift;

	my @ids = main::get_ids($privmsg);
	if(! is_deeply(\@ids, $expected, $description)) {
		print STDERR "got: " . Dumper(\@ids);
		print STDERR "expected: " . Dumper($expected);
	}
}

has_ids(
	youtube_com('asdfasd'),
	['asdfasd'],
	'an lone youtube.com uri'
);
has_ids(
	youtu_be('asdfasd'),
	['asdfasd'],
	'a lone youtu.be uri'
);
has_ids(
	www_youtube_com('asdfasd'),
	['asdfasd'],
	'an lone www.youtube.com uri'
);
has_ids(
	www_youtu_be('asdfasd'),
	['asdfasd'],
	'a lone www.youtu.be uri'
);
has_ids(
	https_youtube_com('asdfasd'),
	['asdfasd'],
	'a lone youtube.com uri (ssl)'
);
has_ids(
	https_youtu_be('asdfasd'),
	['asdfasd'],
	'a lone youtu.be uri (ssl)'
);
has_ids(
	https_www_youtube_com('asdfasd'),
	['asdfasd'],
	'a lone www.youtube.com uri (ssl)'
);
has_ids(
	https_www_youtu_be('asdfasd'),
	['asdfasd'],
	'a lone www.youtu.be uri (ssl)'
);
has_ids(
	"Lala, foo bar baz",
	[],
	'no uri in msg'
);

has_ids(
	sprintf("Haha, really funny video! %s", youtube_com('ASdf78A')),
	['ASdf78A'],
	'youtube.com uri in message'
);

has_ids(
	sprintf("Haha, really funny video! %s", youtu_be('ASdf78A')),
	['ASdf78A'],
	'youtu.be uri in message'
);

has_ids(
	'http://example.com/watch?v=foo',
	[],
	'good youtube.com format, wrong domain'
);

has_ids(
	'http://example.net/foobar',
	[],
	'good youtu.be format, wrong domain'
);

has_ids(
	sprintf(
		"Which is better? %s or %s",
		youtube_com('ABCDEF'), youtube_com('FOOBAR')
	),
	['ABCDEF', 'FOOBAR'],
	'multiple youtube.com links'
);

has_ids(
	sprintf(
		"Which is better? %s or %s",
		youtu_be('ABCDEF'), youtu_be('FOOBAR')
	),
	['ABCDEF', 'FOOBAR'],
	'multiple youtu.be links'
);

has_ids(
	sprintf(
		"Which is better? %s or %s",
		youtube_com('ABCDEF'), youtu_be('FOOBAR')
	),
	['ABCDEF', 'FOOBAR'],
	'multiple youtube.com and youtu.be links'
);

has_ids(
	sprintf(
		"Which is better? %s or %s",
		youtube_com('ABCDEF'), 'http://google.com/pacman'
	),
	['ABCDEF'],
	'multiple links, only one youtube.com'
);

has_ids(
	sprintf("Something (%s)", youtu_be('ASdf78A')),
	['ASdf78A'],
	'youtu.be uri in message within ()'
);

has_ids(
	sprintf("%s, :D", youtu_be('ASdf78A')),
	['ASdf78A'],
	'youtu.be uri delimieted by ,'
);

has_ids(
	sprintf("%s, :D", https_www_youtube_com('ASdf78A-')),
	['ASdf78A-'],
	'youtu.be uri with a trailing -'
);

has_ids(
	sprintf("%s, :D", https_www_youtube_com('AS-df_78A')),
	['AS-df_78A'],
	'youtube uri with _ and -'
);

