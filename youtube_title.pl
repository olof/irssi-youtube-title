#!/usr/bin/perl
# Copyright 2009 -- 2011, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;
use Irssi;
use LWP::UserAgent;
use XML::Simple;
use HTML::Entities;
use URI;
use URI::QueryParam;
use Regexp::Common qw/URI/;

my $VERSION = '0.52';

my %IRSSI = (
	authors     => 'Olof \'zibri\' Johansson',
	contact     => 'olof@ethup.se',
	name        => 'youtube-title',
	description => 'prints the title of a youtube video automatically',
	license     => 'GNU APL',
);

Irssi::settings_add_bool('youtube_title', 'yt_print_own', 0);

sub callback {
	my($server, $msg, $nick, $address, $target) = @_;
	$target=$nick if $target eq undef;

	# process each youtube link in message
	process($server, $target, $_) for (get_ids($msg)); 
}

sub own_callback {
	my($server, $msg, $target) = @_;

	if(Irssi::settings_get_bool('yt_print_own')) { 
		callback($server, $msg, undef, undef, $target);
	}
}

sub process {
	my ($server, $target, $id) = @_;
	my $yt = get_title($id);
		
	if(exists $yt->{error}) {
		print_error($server, $target, $yt->{error});
	} else {
		print_title($server, $target, $yt->{title}, $yt->{duration});
	}
}

sub canon_domain {
	my $domain = normalize_domain(shift);

	{
		'youtube.com' => 'youtube.com',
		'youtu.be' => 'youtu.be',
	}->{$domain};
}

sub normalize_domain {
	my $_ = shift;
	s/^www\.//;
	return $_;
}

sub idextr_youtube_com {
	my $u = URI->new(shift);
	return $u->query_param('v') if $u->path eq '/watch';
}

sub idextr_youtu_be { (URI->new(shift)->path =~ m;/(.*);)[0] }

sub id_from_uri {
	my $uri = shift;
	my $domain = canon_domain($uri->host);

	my %domains = (
		'youtube.com' => \&idextr_youtube_com,
		'youtu.be' => \&idextr_youtu_be,
	);

	return $domains{$domain}->($uri) if ref $domains{$domain} eq 'CODE';
	# TODO warn somehow if you reach this point and $domains{$domain}?
}

sub get_ids {
	my $msg = shift;
	my $re_uri = qr#$RE{URI}{HTTP}{-scheme=>'https?'}#;
	my @ids;

	foreach($msg =~ /$re_uri/g) {
		my $uri = URI->new($_);
		my $id;

		if($uri->host =~ /^(?:www\.)?youtube\.com$/) {
			next unless $uri->path eq '/watch';
			$id = $uri->query_param('v');
		} elsif($uri->host =~ /^(?:www\.)?youtu\.be$/) {
			($id) = $uri->path =~ m;/(.*);
		}
		
		next unless $id;

		$id =~ s/[^\w-].*//;
		push @ids, $id;
	}

	return @ids;
}

# extract title using youtube api
# http://code.google.com/apis/youtube/2.0/developers_guide_protocol.html
sub get_title {
	my($vid)=@_;

	my $url = "http://gdata.youtube.com/feeds/api/videos/$vid";
	
	my $ua = LWP::UserAgent->new();
	$ua->agent("$IRSSI{name}/$VERSION (irssi)");
	$ua->timeout(3);
	$ua->env_proxy;

	my $response = $ua->get($url);

	if($response->code == 200) {
		my $content = $response->decoded_content;

		my $xml = XMLin($content)->{'media:group'};
		my $title = $xml->{'media:title'}->{content};
		my $s = $xml->{'yt:duration'}->{seconds};

		my $m = $s / 60;
		my $d = sprintf "%d:%02d", $m, $s % 60;

		if($title) {
			return {
				title => $title,
				duration => $d,
			};
		}

		return {error => 'could not find title'};
	}
	
	return {error => $response->message};
}

sub print_error {
	my ($server, $target, $msg) = @_;
	$server->window_item_find($target)->print(
		"%rError fetching youtube title:%n $msg", MSGLEVEL_CLIENTCRAP
	);
}

sub print_title {
	my ($server, $target, $title, $d) = @_;

	$title = decode_entities($title);
	$d = decode_entities($d);

	$server->window_item_find($target)->print(
		"%yyoutube:%n $title ($d)", MSGLEVEL_CLIENTCRAP
	);
}

Irssi::signal_add("message public", \&callback);
Irssi::signal_add("message private", \&callback);

Irssi::signal_add("message own_public", \&own_callback);
Irssi::signal_add("message own_private", \&own_callback);

