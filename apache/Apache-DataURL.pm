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

package Apache2::DataURL;

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
    
    if (defined($cache{$cssfile}))
    {
        $text = $cache{$cssfile};
    }
    else
    {
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
                
        my $sr = $r->lookup_uri("\"$url");
        my $rc = $sr->run();
        my $pi = $sr->path_info();
        my $mimetype = $sr->content_type();
        my $path = $ENV{DOCUMENT_ROOT} . $pi;
        
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
