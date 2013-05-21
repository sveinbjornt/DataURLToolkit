#
# DataURL::Encode
# (C) Copyright 2011 Sveinbjorn Thordarson
# Distributed under the GNU General Public License
#

package DataURL::Encode;

use strict;
use utf8;
use MIME::Base64;
use IO::Scalar;
use File::MimeInfo::Magic qw(mimetype);
use DataURL::Util;

our @EXPORT = qw(dataurl_from_dataref dataurl_from_filepath dataurl_from_filehandle);
our $VERSION = "1.0";

sub data_from_dataurl
{
    # my ($dataurl) = @_;
    # my $dataurl = strip($dataurl);
    # 
    # if ($dataurl !~ m/^data\:/) 
    # { 
    #     warn("Not a Data RUL: $dataurl");
    #     return undef; 
    # }
    # 
    # my $mime_type = $dataurl =~ m/data\:(.+);base64/;
    # my $base64data = split('base64,', $dataurl)[1];
    # my $rawdata = decode_base64($base64data);
    # 
    # return (\$rawdata, $mime_type);
}

sub dataurl_from_filepath
{
    my ($filepath) = @_;
    my $data;
    open(DATAURL_FILE, $filepath) or die("Could not open for reading file at path $filepath");
    binmode(DATAURL_FILE);
    while ( <DATAURL_FILE> ) { $data .= $_;  }
    close(DATAURL_FILE);
    return dataurl_from_dataref(\$data);
}

sub dataurl_from_filehandle
{
    my ($filehandle) = @_;
    my $data;
    binmode($filehandle);
    while ( <$filehandle> ) { $data .= $_;  }
    return dataurl_from_data(\$data);
}

sub dataurl_from_dataref
{
    my ($data_ref) = @_;
    
    my $iofh = new IO::Scalar $data_ref;
    my $mime_type = mimetype($iofh);
    
    if (!$mime_type)
    {
        warn("Unable to determine mimetype of data " . $data_ref);
        return undef;
    }
    my $enc = encode_base64($$data_ref, '');
    if (!$enc)
    {
        warn("Unable to base64 encode data " . $data_ref);
        return undef; 
    }
    
    my $data_url = "data:$mime_type;base64,$enc";
    
    return $data_url;
}

1;
