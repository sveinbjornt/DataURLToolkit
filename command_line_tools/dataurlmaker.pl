#!/usr/bin/perl -w
#
# (c) 2006-2011 Sveinbjorn Thordarson <sveinbjornt@simnet.is>
#
# This Perl command line program accepts files as arguments
# and dumps out an RFC-compliant Data URL for each file.
#
# The -i option generates an HTML img tag for the Data URL
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


use strict;
use Image::Info qw(image_info dim);
use MIME::Base64;
use Getopt::Std;

our $VERSION = 2.0;
my $scriptname = 'dataurlmaker.pl';
my $valid_opts = 'i'

# Getopt

sub main::HELP_MESSAGE
{
    print STDERR <<"EOF";
$scriptname

    Usage: $scriptname [-$valid_opts] file1 file2 ..."
    
        -i Generate HTML img tag for an image data URL
        
EOF
}

# check num arguments
if (!scalar(@ARGV))
{
	main::HELP_MESSAGE();
	exit;
}

# Iterate through files, print out data URL for each in turn
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
