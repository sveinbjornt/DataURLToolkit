#!/usr/bin/perl -w
#
# (c)2006 Sveinbjorn Thordarson
#
# CGI mechanism to create Data URLs
# Receives image as form parameter,
# processes the data and delivers the 
# Data URL in a TEXTAREA element
#
#
use Image::Info qw(image_info dim);
use MIME::Base64;
use CGI;
use strict;

my $cgi = new CGI;
my $file = $cgi->param('file');
my $data;

# Retrieve the entire file being passed
while ( <$file> ) { $data .= $_;  }

if (length($data) > 50000)
{
    print "Content-Type: text/plain\n\nFile exceeded maximum length";
}

# Image Info
my $info = image_info(\$data);
my $mimetype = $info->{file_media_type};
my($image_width, $image_height) = dim($info);

my $enc = encode_base64($data, '');
my $imghtml = '<img src="data:' . $mimetype . ';base64,' . $enc . "\" width=\"$image_width\" height=\"$image_height\">";

print "Content-Type: text/html\n\n";
print '<html><body>';
print '<center><h2>Data URL Image Tag Generator</h2></center>';
print '<div style="border: 1px solid #222222; background-color: #EAEAEA; margin: 15px; padding: 15px;">';
print $imghtml;
print '<br><br>';
print 'Data URL HTML Image Tag<br>';
print '<textarea rows="7" cols="40">';
print $imghtml;
print '</textarea>';
print '</div><center><small>&copy; 2005 Sveinbjorn Thordarson</small></center></body></html>';
