#!/usr/bin/perl
# Copyright 2009 -- 2014, Olof Johansson <olof@ethup.se>, DrThum <thum@drthum.net>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;
use Irssi;
use LWP::UserAgent;
use HTML::Entities;
use JSON qw( decode_json );
use URI;
use URI::QueryParam;
use Regexp::Common qw/URI/;

my $VERSION = '0.8';

my %IRSSI = (
	authors     => 'Olof "zibri" Johansson, DrThum',
	contact     => 'olof@ethup.se',
	name        => 'youtube-title',
	uri         => 'https://github.com/olof/irssi-youtube-title',
	description => 'prints the title of a youtube video automatically',
	license     => 'GNU APL',
);

# Changelog is now available as a separate file (./Changes). If you
# don't have it, you can find it on github.
Irssi::settings_add_bool('youtube_title', 'yt_print_own', 0); # Whether to print the title for your own youtube links
Irssi::settings_add_str('youtube_title', 'yt_api_key', ''); # User's personal Google API key

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
	my $uri = URI->new(shift);
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
		my $id = id_from_uri($_);
		next unless $id;

		$id =~ s/[^\w-].*//;
		push @ids, $id;
	}

	return @ids;
}

# extract title and duration using youtube api v3
sub get_title {
	my($vid)=@_;

	my $key = Irssi::settings_get_str('yt_api_key');
	my $url = "https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=$vid&fields=items&key=$key";
	
	my $ua = LWP::UserAgent->new();
	$ua->agent("$IRSSI{name}/$VERSION (irssi)");
	$ua->timeout(1);
	$ua->env_proxy;

	my $response = $ua->get($url);

	if($response->code == 200) {
		my $content = $response->decoded_content;

		my $json = decode_json($content);
		my @items = @{ $json->{'items'} };
		my $first = $items[0];
		my $title = $first->{'snippet'}{'title'};
		my $duration = $first->{'contentDetails'}{'duration'};
		$duration =~ s/PT//;

		if($title) {
			return {
				title => $title,
				duration => $duration,
			};
		}

		return {error => 'could not find title'};
	} elsif ($response->code >= 400) {
		return { error => 'did you setup your API key? /help yt-title for more information.' };	
	}
	
	return {error => $response->message};
}

sub print_error {
	my ($server, $target, $msg) = @_;
	$server->window_item_find($target)->printformat(
		MSGLEVEL_CLIENTCRAP, 'yt_error', $msg
	);
}

sub print_title {
	my ($server, $target, $title, $d) = @_;

	$title = decode_entities($title);
	$d = decode_entities($d);

	$server->window_item_find($target)->printformat(
		MSGLEVEL_CLIENTCRAP, 'yt_ok', $title, $d
	);
}

sub help_msg {
	if ($_[0] eq 'yt-title') {
		my $help = "To use this plugin, you must first set create and set your personal Google API key.
This is needed because each key is allowed for only specific IP addresses.
To create your key, go to https://console.developers.google.com/project and create a project. Once
it's done, go to the newly created project, APIs & auth on the right, and in the APIs tab, ensure that
YouTube Data API v3 is set to ON (the others don't matter).
Now, in the Credentials tab, press the Create new key button, and choose the Server key option. In the 
text area, enter the IP address of the machine hosting your irssi client. Once the key is created, copy
it and in irssi, run the command /set yt_api_key followed by the key.
Congratulations, you should now be able to use this script!";

		Irssi::print($help, MSGLEVEL_CLIENTCRAP);
		Irssi::signal_stop;
	}
}

Irssi::theme_register([
	'yt_ok', '%yYoutube:%n $0 ($1)',
	'yt_error', '%rError fetching youtube title:%n $0',
]);

Irssi::signal_add("message public", \&callback);
Irssi::signal_add("message private", \&callback);

Irssi::signal_add("message own_public", \&own_callback);
Irssi::signal_add("message own_private", \&own_callback);

Irssi::command_bind('help', 'help_msg');
