#file:MyApache2/Rocks.pm
#----------------------
package Apache2::Hello;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::SubRequest();
use Apache2::RequestIO ();
use Image::Info qw(image_info dim);
use MIME::Base64;

use Apache2::Const -compile => qw(OK);

my %cache;

sub handler 
{
    my $r = shift;
	my $text;

	my $cssfile = $r->filename();
	
	warn("Mimetype for css: " . $r->content_type());
	
	if (defined($cache{$cssfile}))
	{
		warn("Reading from cache");
		$text = $cache{$cssfile};
	}
	else
	{
		warn("DATAURLIFYING");
		open(FILE, $cssfile) or die("Could not read css file $cssfile");
		my @lines = <FILE>;
		close(FILE);
		$text = join(//, @lines);
		$text = dataurlifyCSS($text, $r);
		$cache{$cssfile} = $text;
	}

	$r->content_type('text/css');
	print $text;
	
    return Apache2::Const::OK;
}

sub dataurlifyCSS
{
	my $text = shift;
	my $r = shift;
	
	#while ($text =~ m/url\((.+\.gif.*?|.+\.png.*?|.+\.jpg.*?|.+\.jpeg.*?)\)/ig)
	while ($text =~ m/\s*url\(\s*["']?([^"']+(\.gif|\.png|\.jpg|\.jpeg))["']?\s*\)/ig)
	{
		my $url = $1;		
		if ($url =~ m/^data\:/) { next; } # Already a Data URL
		
		# warn($url);
		
		my $sr = $r->lookup_uri("\"$url");
		my $rc = $sr->run();
		my $pi = $sr->path_info();
		my $mimetype = $sr->content_type();
		warn("Mime: $mimetype");
		my $path = $ENV{DOCUMENT_ROOT} . $pi;
		
		warn($path);
		my $dataurl = dataurlForFilePath($path, $mimetype);
		
		if (defined($dataurl))
		{
			$text =~ s/$1/$dataurl/ig;	
		}
	}
	return $text;	
}

sub dataurlForFilePath
{
	my $path = shift;	
	my $mimetype = shift;
	
	my $data;
	if (! -e $path) { return undef; }
	
	open(FILE, $path) or die("Error opening file '$path' for reading");
	binmode FILE;
	while (<FILE>) { $data .= $_; }
	close(FILE);
	
	my $enc = encode_base64($data, '');
	my $imgurl = 'data:' . $mimetype . ';base64,' . $enc;
	
	return $imgurl;
}

1;
