#
# DataURL::Util
# (C) Copyright 2011 Sveinbjorn Thordarson
# Distributed under the GNU General Public License
#

package DataURL::Util;

use strict;
use utf8;
use Image::Info qw(image_info);
use File::Basename qw(fileparse);

our @EXPORT = qw(   strip 
                    clean_url_value 
                    urljoin 
                    is_image_filename 
                    is_image_data 
                    is_image_filename 
                    is_image_mime_type 
                    image_mime_type_from_dataref
                    image_mime_type_from_filename
                );

our $VERSION = "1.0";

sub is_image_filename
{
    my ($str) = @_;
    if ($str =~ m/\.jpg$/i or $str =~ m/\.png$/i or $str =~ m/\.gif$/i or $str =~ m/\.jpeg$/i) { return 1; }
    return 0;
}

sub is_image_data
{
    my ($dataref) = @_;
    my $mime_type = image_mime_type_from_dataref($dataref);
    if (defined($mime_type) and is_image_mime_type($mime_type)) { return 1; }
    return 0;
}

sub is_image_mime_type
{
    my ($mime_type) = @_;
    my @mimetypes = ('image/jpeg', 'image/gif', 'image/png');
    return grep($_ eq $mime_type, @mimetypes);
}

sub image_mime_type_from_filename
{
    my ($fn) = @_;
    my($filename, $directories, $suffix) = fileparse($fn);
    my %suffix2mime = ( '.jpg' => 'image/jpeg', 
                        '.png' => 'image/png', 
                        '.gif' => 'image/gif', 
                        '.jpeg' => 'image/jpeg');
    my $mime = $suffix2mime{lc($suffix)};
    return $mime;
}

sub image_mime_type_from_dataref
{
    my ($dataref) = @_;
    my $info = image_info($dataref);
    my $mime_type = $info->{file_media_type};
    if (!defined($info) or !defined($mime_type) or !is_image_mime_type($mime_type)) 
    {
        return undef;
    }
    return $mime_type;
}

sub strip
{
    my ($s) = @_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub clean_url_value
{
    my ($s) = @_;
    $s = strip($s);
    $s =~ s/^'//;
    $s =~ s/'$//;
    $s =~ s/^"//;
    $s =~ s/"$//;
    $s = strip($s);
    return $s;
}

sub urljoin
{
    my ($a, $b) = @_;
    my $result;
    
    if (!$a) { return $b; }
    if (!$b) { return $a; }
    
    # latter full url overrides prior
    if ($b =~ m/^http/) { return $b; }
    
    my ($a_protocol) = $a =~ m/(https?)\:\/\//;
    my ($b_protocol) = $b =~ m/(https?)\:\/\//;
    
    $a =~ s/$a_protocol\:\/\///i;
    
    my ($domain, @path_elements) = split(/\//, $a);
    
    if ($b =~ m/^\//) 
    {
        $result = $a_protocol . '://' . $domain . $b;
        return $result;
    }
        
    pop(@path_elements);
    push(@path_elements, $b);
    
    $result = $a_protocol . '://' . $domain;
    foreach (@path_elements)
    {
        $result .= '/' . $_;
    }
    
    return $result;
}

1;