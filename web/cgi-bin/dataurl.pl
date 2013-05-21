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
use Data::Validate::URI qw(is_http_uri is_https_uri);
use SQLiteLogger;

my $dataurlmaker_hardlimit = 250 * 1024;

use vars qw($logdb); # Shared dictionary of databases

if (!defined($logdb)) 
{
    $logdb = new SQLiteLogger;
    if (!$logdb) { error("Could not connect to database.", '200 OK'); }
}

local our $remote_ip    = $ENV{'REMOTE_ADDR'};
local our $user_agent   = $ENV{'HTTP_USER_AGENT'};

local our $cgi = new CGI;
local our $action = $cgi->param('action');

if ($action eq 'encode')
{    
    if($ENV{REQUEST_METHOD} ne 'POST') { error("Illegal request.", 403); }
    
    # Read file data
    my $filehandle = $cgi->upload('file');
    my $data = undef;
    while ( <$filehandle> ) { $data .= $_;  }
    
    if (length($data) > $dataurlmaker_hardlimit)
    {
        my %reply = ( error => "File exceeds max size, which is $dataurlmaker_hardlimit bytes.", '200 OK');
        reply(\%reply);
    }
    
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
    # IP-based cooldown for this expensive operation
    my $cooldown = $logdb->CooldownRemaining($remote_ip);
    if ($cooldown > 0)
    {
        warn($cooldown);
        error("Cooldown in effect to prevent hammering of the server.  Please wait $cooldown seconds before trying again.", '200 OK');
    }
    
    # Read parameters
    my $url = $cgi->param('css_file_url');
    if (!$url) { error("Empty URL provided", '200 OK'); }
    
    # Is it a URI?
    if(!is_http_uri($url) and !is_https_uri($url)) {   error("The provided URL is invalid.", '200 OK')}
    
    # Calc these vals based on params 
    my $limit = $cgi->param('size_limit') ? $cgi->param('size_limit') * 1024 : undef;
    my $compress = ($cgi->param('compress') eq 'on') ? 1 : 0;
    my $optimg = ($cgi->param('optimize_images') eq 'on') ? 1 : 0;

    # Optimize
    my $cssinfo_hashref = DataURL::CSS::optimize($url, $limit, $compress, $optimg);
    
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
    $logdb->Log($status, defined($hashref->{error}), time(), $remote_ip, $json);
    
    exit(0);
}

sub error
{
    my ($errmsg, $status) = @_;
    if (!defined($status)) { $status = '500'; }
    my %reply = ( error => $errmsg );
    reply(\%reply, $status);
    exit(1);
}


