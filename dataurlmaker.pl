#!/usr/bin/perl -w
#
# (c) 2006 Sveinbjorn Thordarson <sveinbjornt@simnet.is>
#
# This Perl command line program accepts file paths to images as arguments
# and dumps out an RFC-compliant Data URL HTML IMG tag for each image.
#
# The Image::Info and MIME::Base64 modules are required.  To install these
# modules, do the following:
#
# perl -MCPAN -e shell
#
# install Image::Info
# install MIME:Base64
#

use strict;
use Image::Info qw(image_info dim);
use MIME::Base64;

# check num arguments
if (!scalar(@ARGV))
{
	print "Usage:\n";
	print "\t./dataurlmaker.pl file1 file2 file3 ...\n\n";
	exit(0);
}

foreach my $file(@ARGV)
{
	if (! -e $file)
	{
		warn("$file: no such file.  Skipping...");
		next;
	}

	# Get Image Info
        my $info = image_info($file);
        my $mimetype = $info->{file_media_type};
        my($image_width, $image_height) = dim($info);

	my $data;
	open(FILE, "$file") or die("Error opening file '$file' for reading");
	binmode FILE;
	while (<FILE>) { $data .= $_; }
	close(FILE);

	my $enc = encode_base64($data, '');
	my $imghtml = '<img src="data:' . $mimetype . ';base64,' . $enc . "\" width=\"$image_width\" height=\"$image_height\">";

	print "-----------\n$file:\n$imghtml\n";
}

exit(0);
