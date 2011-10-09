#!/usr/bin/perl -w
#
# This doesn't work

use strict;

use LWP::Simple;
use MIME::Base64;
use URI::Split qw(uri_split uri_join);
use Image::Info qw(image_info dim);



my $url = $ARGV[0];

my $base = BaseURLForURL($ARGV[0]);

my $html = get($ARGV[0]);

print DataURLify($html,$base);

sub FullResourceURLFromSource
{
	my ($src, $baseurl) = @_;
	
	# we need to clean this a little
	# Remove any parentheses, spaces
	while ($src =~ m/^[\'|\"| +]/i)
	{
		$src = substr($src,1);
	}
	while ($src =~ m/[\'|\"|\s+]$/i)
	{
		chop($src);
	}
	
	my ($scheme, $auth, $path, $query, $frag) = uri_split($src);	
	my $resource_url = $src;

	# This means it's not a whole URL
	if (length($auth) eq 0)
	{
		# absolute if starts with slash
		if ($resource_url =~ m/^\//)
		{
			my $dnsbase = $baseurl;
			$resource_url = $dnsbase . $resource_url;
		}
		else # relative url
		{
			$resource_url = $baseurl . $resource_url;
		}
	}
#	print $resource_url . "\n";
	return $resource_url;
}

sub DataURLify
{
	my ($html,$baseurl) = @_;
	
	$html = DataURLifyHTML($html,$baseurl);
	$html = InlineCSSifyText($html,$baseurl);
	
	return $html;
}

sub DataURLifyHTML
{
	my ($text,$baseurl) = @_;
	
	while ($text =~ m/src=[\'|\"](.+\.gif.*?|.+\.png.*?|.+\.jpg.*?|.+\.jpeg.*?)[\'|\"]/ig)
	{
		my $resourceurl = FullResourceURLFromSource($1,$baseurl);
		my $imgdata = get($resourceurl);
		my $info = image_info(\$imgdata);
		my $mimetype = $info->{file_media_type};
		my $base64data = encode_base64($imgdata, '');
		my $dataurl = "data:" . $mimetype . ";base64," . $base64data;
		$text =~ s/$1/$dataurl/g;
	}
	return $text;
}

sub InlineCSSifyText
{
	my ($text,$baseurl) = @_;
	
	#replace all css with inline css
	while ($text =~ m/(<.+href=[\"|\'](.+\.css.*?)[\"|\'].*>)/ig)
	{
		my $resourceurl = FullResourceURLFromSource($2,$baseurl);
		my $css = get($resourceurl);
		$css = DataURLifyCSS($css,$resourceurl);
		my $csstag = '<style type="text/css">' . "\n$css\n" . "</style>\n";
		$text =~ s/$1/$csstag/g;
	}
	
	return $text;
}

sub DataURLifyCSS
{
	my ($text,$url) = @_;
	
	#print "LENGTH OF CSS at $url is ".length($text) ."\n";
	#print "URL IN CSS: ".$2 . "\n";
	while ($text =~ m/url\((.+\.gif.*?|.+\.png.*?|.+\.jpg.*?|.+\.jpeg.*?)\)/ig)
	{
		my $url = $1;
		
		if ($url =~ m/^data/) { next; }
		
		my $resourceurl = FullResourceURLFromSource($1,BaseURLForURL($url));		
		my $imgdata = get($resourceurl);
		my $info = image_info(\$imgdata);
		my $mimetype = $info->{file_media_type};
		my $base64data = encode_base64($imgdata, '');
		my $dataurl = "data:" . $mimetype . ";base64," . $base64data;
		$text =~ s/$1/$dataurl/ig;	
	}
	return $text;
}


sub BaseURLForURL
{
	my ($url) = @_;
	
	my ($scheme, $auth, $path, $query, $frag) = uri_split($url);
	my $baseurl = uri_join($scheme, $auth);
	
	return $baseurl;
}

# #replace all JavaScript with inline Javascript
# while ($html =~ m/(<script.+src=\"(.+\.js)\".+>)/)
# {
# 	my $js = get("http://$url$2");
# #	print $2 . "\n";
# 	my $jstag = '<script type="text/javascript">' . $js . '</script>';
# 	$html =~ s/$1/$jstag/;
# }
# print $html;