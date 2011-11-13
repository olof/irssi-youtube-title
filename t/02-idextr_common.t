#!/usr/bin/perl
require 'youtube_title.pl';

package test;
use warnings;
use strict;
use lib qw;t/lib;;
use Test::More;
use Data::Dumper;
use URI;
use URI::QueryParam;

sub has_ids {
	my $code = shift;
	my $uri = shift;
	my $expected = shift;
	my $description = shift;

	is($code->($uri), $expected, $description);
}

my %domains = (
	'youtube.com' => {
		urigen => \&urigen_youtube_com,
		idextr => \&main::idextr_youtube_com,
		extra_tests => 3,
		extra_test => \&tests_youtube_com,
	},
	'youtu.be' => {
		urigen => \&urigen_youtu_be,
		idextr => \&main::idextr_youtu_be,
		extra_tests => 1,
		extra_test => \&tests_youtu_be,
	},
);

sub idextr_tests {
	my($code, $urigen) = @_;

	my $domain = $urigen->(undef, { nopath => 1 });
	$domain =~ s;.*?://;;;

	has_ids($code, $urigen->('asdfasd'), 'asdfasd', "$domain: simple case");
	has_ids(
		$code, $urigen->('asdfasd', { www=>1 }), 
		'asdfasd', "$domain: simple case (www)"
	);
	has_ids(
		$code, $urigen->('asdfasd', { ssl=>1 }), 
		'asdfasd', "$domain: simple case (ssl)"
	);
	has_ids(
		$code, $urigen->('asdfasd', { ssl=>1, www=>1 }), 
		'asdfasd', "$domain: simple case (www,ssl)"
	);

	ok(! $code->($urigen->(undef, { nopath => 1 })), "$domain: no path");
	ok(
		!$code->($urigen->(undef, { nopath => 1, www => 1 })),
		"$domain: no path, (www)"
	);
	ok(
		!$code->($urigen->(undef, { nopath => 1, ssl => 1 })), 
		"$domain: no path, (ssl)"
	);
	ok(
		!$code->($urigen->(undef, { nopath => 1, www => 1, ssl => 1 })),
		"$domain: no path, (www, ssl)"
	);

	ok(! $code->(''), "$domain: invalid uri ''");
	ok(! $code->(undef), "$domain: invalid uri undef");
}

my $number_of_tests_in_idextr_tests = 10; # nice symbol name =)
my $extra_tests;
$extra_tests += $domains{$_}->{extra_tests} for( keys %domains );
plan tests => keys(%domains) * $number_of_tests_in_idextr_tests + $extra_tests;

for(keys %domains) {
	my $idextr = $domains{$_}->{idextr};
	my $urigen = $domains{$_}->{urigen};
	my $extra_test = $domains{$_}->{extra_test};

	idextr_tests($idextr, $urigen);
	$extra_test->() if defined $extra_test;
}

sub urigen_youtube_com {
	my ($id, $opts) = @_;

	my $uri = URI->new;
	$uri->scheme('http');
	$uri->scheme('https') if $opts->{ssl};
	$uri->host('youtube.com');
	$uri->host('www.youtube.com') if $opts->{www};
	return $uri if $opts->{nopath};

	$uri->path('/watch');
	$uri->query_param(v => $id);

	return $uri;
}

sub urigen_youtu_be {
	my ($id, $opts) = @_;

	my $uri = URI->new;
	$uri->scheme('http');
	$uri->scheme('https') if $opts->{ssl};
	$uri->host('youtu.be');
	$uri->host('www.youtu.be') if $opts->{www};
	return $uri if $opts->{nopath};

	$uri->path("/$id");

	return $uri;
}

sub tests_youtube_com {
	my $f = sub { main::idextr_youtube_com(@_) }; # alias
	ok(! $f->('http://youtube.com/watch'), 'youtube: /watch, but no ?v=');
	ok(! $f->('http://youtube.com/watch?'), 'youtube: /watch?, but no v=');
	ok(! $f->('http://youtube.com/watch?v='), 'youtube: v=, but no vid');
}

sub tests_youtu_be {
	my $f = sub { main::idextr_youtu_be(@_) }; # alias

	is(
		$f->('http://youtu.be/watch?v=asdf'), 
		'watch',
		'using youtu.be as youtube.com'
	);
}

