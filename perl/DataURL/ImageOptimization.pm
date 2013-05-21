#
# DataURL::Util
# (C) Copyright 2011 Sveinbjorn Thordarson
# Distributed under the GNU General Public License
#

package DataURL::ImageOptimization;

use strict;
use utf8;

our @EXPORT = qw(   optimize_image_data 
                    optimize_png_data 
                    optimize_jpeg_data 
                    optimize_png_file 
                    optimize_jpeg_file 
                );

our $VERSION = "1.0";

our $pngcrush_path = '/usr/local/bin/pngcrush';
our $jpegtran_path = '/usr/local/bin/jpegtran';
our $tmpdir = '/tmp/';


sub optimize_image_data
{
    my ($data, $mimetype) = @_;
    
    if ($mimetype eq 'image/png') 
    {
        $data = optimize_png_data($data);
    } 
    elsif ($mimetype eq 'image/jpeg' && -e $jpegtran_path)
    {
        $data = optimize_jpeg_data($data);
    }
    return $data;
}

sub optimize_png_data
{
    my ($data) = @_;
    my $fn = write_imgdata_to_file($data, 'png');
    optimize_png_file($fn);
    $data = read_img_data($fn);
    unlink($fn);
    return $data;
}

sub optimize_jpeg_data 
{
    my ($data) = @_;
    my $fn = write_imgdata_to_file($data, 'jpeg');
    optimize_jpeg_file($fn);
    $data = read_img_data($fn);
    unlink($fn);
    return $data;
}

sub optimize_png_file 
{
    my ($path) = @_;
    my $outfn = "$path-optimized";
    
    if (! -e $pngcrush_path) 
    {
        warn("Warning: No binary at " . $pngcrush_path);
        return $path;
    }
    
    `$pngcrush_path '$path' '$outfn' &> /dev/null`;
    my $insize = -s $path;
    my $outsize = -s $outfn;
    warn("Optimized $path");
    warn("Bytes In: " . $insize . ' Bytes Out: ' . $outsize);
    
    if (-e $outfn && -s $outfn) 
    {
        unlink($path);
        rename($outfn, $path);
    }
    
    
    return $path;
}

sub optimize_jpeg_file 
{
    my ($path) = @_;
    my $outfn = "$path-optimized";
    
    if (! -e $jpegtran_path) 
    {
        warn("Warning: No binary at " . $jpegtran_path);
        return $path;
    }
    
    `$jpegtran_path -optimize -progressive -copy none -outfile '$outfn' '$path'`;
    my $insize = -s $path;
    my $outsize = -s $outfn;
    warn("Optimized $path");
    warn("Bytes In: " . $insize . ' Bytes Out: ' . $outsize);
    
    if (-e $outfn && -s $outfn) 
    {
        unlink($path);
        rename($outfn, $path);
    }
    return $path;
}

sub write_imgdata_to_file 
{
    my ($data, $suffix) = @_;
    my $randfn = rand() . '.' . $suffix;
    
    open(FILE, "+>$tmpdir/$randfn");
    binmode(FILE);
    print FILE $data;
    close(FILE);
    
    return "$tmpdir/$randfn";
}

sub read_img_data 
{
    my ($path) = @_;
    open(F, $path);
    binmode(F);
    my $data = do { local $/; <F> };
    close(F);
    return $data;
}