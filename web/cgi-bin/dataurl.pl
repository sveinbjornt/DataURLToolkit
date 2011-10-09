#!/usr/bin/perl -w

use strict; # yes, oh yes
use utf8;

use CGI;
use Compress::Zlib;
use JSON;
use File::Basename;

use DataURL::CSS qw(optimize);
use DataURL::Util qw(is_image_data);
use DataURL::Encode qw(dataurl_from_dataref);

local our $cgi = new CGI;
local our $action = $cgi->param('action');

if ($action eq 'encode')
{
    if($ENV{REQUEST_METHOD} ne 'POST') { error("Illegal request.", 403); }
    
    # Read file data
    my $filehandle = $cgi->upload('file');
    my $data = undef;
    while ( <$filehandle> ) { $data .= $_;  }
    
    # Get data URL
    my $data_url = DataURL::Encode::dataurl_from_dataref(\$data);
    
    # Create reply dict and reply
    my %reply = (   dataurl     => $data_url,
                    size        => length($data_url),
                    origsize    => length($data),
                    filename    => basename($filehandle),
                    image       => DataURL::Util::is_image_data(\$data),
                    gzipsize    => length(Compress::Zlib::compress($data_url))
                );
    
    reply(\%reply);
}
elsif ($action eq 'optimize') 
{   
    # Read parameters
    my $file = $cgi->param('css_file_url');
    if (!defined($file)) { error("Missing css remote url argument."); }
    my $limit = $cgi->param('size_limit') ? $cgi->param('size_limit') * 1024 : undef;
    my $compress = ($cgi->param('compress') eq 'on') ? 1 : 0;

    # Optimize
    my $cssinfo_hashref = DataURL::CSS::optimize($file, $limit, $compress);
    
    # Reply with info dict
    reply($cssinfo_hashref);
}
else
{
    error('Illegal request', 403);
}

sub reply
{
    my ($hashref, $status) = @_;
    
    my $json = encode_json($hashref);
    
    binmode(STDOUT, ":utf8");
    if (!defined($status)) { $status = '200 OK'; }
    print "Status: $status\n";
    print STDOUT "Content-Type: application/json\n\n";
    print STDOUT $json;
    warn($json);
    exit(0);
}

sub error
{
    my ($errmsg, $status) = @_;
    if (!defined($status)) { $status = '500'; }
    my %reply = ( error => $errmsg );
    reply(\%reply, $status);
    warn("Status $status : $errmsg");
    exit(1);
}







