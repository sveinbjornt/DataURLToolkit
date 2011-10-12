#
# DataURL::OptimizeCSS
# (C) Copyright 2011 Sveinbjorn Thordarson
# Distributed under the GNU General Public License
#

package DataURL::CSS;

use strict;
use utf8;
use POSIX;
use HTTP::Request;
use LWP::UserAgent;
use DataURL::Util;

our @EXPORT = qw(optimize compress);
our $VERSION = "1.0";
our $default_limit = 4096;
our $default_ua = 'DataURL.Net-CSSOptimizerBot/$VERSION (dataurl.net) ' . POSIX::uname();
our $timeout = 4;
our $max_css_size = 200 * 1024;
our $max_ext_obj_size = 200 * 1024;

sub optimize
{
    my ($css_url, $limit, $compress) = @_;
    
    # Verify args and defaults
    if (!defined($css_url)) { return _error("Empty URL"); }
    if (!defined($limit)) { $limit = $default_limit; }
    if (!defined($compress)) { $compress = 0; }
    
    # First, make sure URL has protocol
    if ($css_url !~ m/^.+\:\/\//) { $css_url = 'http://' . $css_url; }
    
    # Create User Agent
    my $ua = LWP::UserAgent->new;
    $ua->agent($default_ua);
    $ua->timeout($timeout);
    
    # Request CSS file
    my $request = HTTP::Request->new(HEAD => $css_url);
    my $response = $ua->request($request);
    
    # Make sure response is OK
    if (!$response->is_success) 
    {
        return _error("Failed to fetch CSS document. Status:  " . $response->status_line);
    }
    
    my $mime_type = $response->header('content-type');
    if ($mime_type ne 'text/css' and $mime_type ne 'text/plain') 
    {
        return _error("Remote file is not a CSS document.  Declared mime type is $mime_type");
    }
    
    my $css_size = $response->header('content-length');
    if ($css_size > $max_css_size)
    {
        return _error("CSS size ($css_size) exceeds maximum ($max_css_size)");
    }
    
    # OK, the file seems fine.  Let's fetch it properly using GET.
    $request = HTTP::Request->new(GET => $css_url);
    $response = $ua->request($request);
    
    # Get content
    my $css = $response->decoded_content();
    
    # Find and clean all strings contained within url()
    my (@matches) = $css =~ m/url\s?\(\s?"?'?(\s?.+\s?)'?"?\)/ig;
    foreach (@matches) { $_ = DataURL::Util::clean_url_value($_); }
    
    # Create CSS info dict 
    my %cssinfo = ();
    $cssinfo{pre}{css_size} = length($css);
    $cssinfo{pre}{css_gzip_size} = length(Compress::Zlib::compress($css));
    $cssinfo{pre}{data_urls} = 0;
    
    # Build list of URLs to fetch
    my %fetch_urls = ();
    foreach my $url (@matches)
    {
        if ($url =~ /^data\:/) { $cssinfo{pre}{data_urls} += 1; next; }
        my %urlhash = (         get => 0, 
                                converted => 0,
                                image => 0,
                                size => '?',
                                status_msg => '',
                                req => '?',
                                full_url => '?',
                                mime_type => '?',
                                full_url => DataURL::Util::urljoin($css_url, $url),
                                status => 'ok'    ); # can be ok, warn, err
        $fetch_urls{$url} = \%urlhash;
    }
    
    # Set up some pre-fetch info
    $cssinfo{pre}{ext_objects} = scalar(keys(%fetch_urls));
    $cssinfo{pre}{requests} = 1 + $cssinfo{pre}{ext_objects};
    $cssinfo{pre}{img_size} = 0;
    $cssinfo{pre}{ext_size} = 0;
    $cssinfo{pre}{total_size} = 0;
    $cssinfo{dataurl_converted} = 0;
    $cssinfo{pre}{total_gzip_size} = 0;
    
    # Maps URLs in CSS to Data URLs
    my %replace_map;
    
    # Do HEAD request on each external object
    foreach my $url (keys(%fetch_urls))
    {        
        # Send HEAD request
        $fetch_urls{$url}{req} = 'HEAD';
        $request = HTTP::Request->new(HEAD => $fetch_urls{$url}{full_url});
        $response = $ua->request($request);
        
        # If it fails, we mark error, else save info from HEAD req
        if ($response->is_success)
        {
            $fetch_urls{$url}{status_msg} = $response->status_line . " HEAD";
        }
        else
        { 
            $fetch_urls{$url}{status_msg} = $response->status_line;
            $fetch_urls{$url}{status} = 'err';
            next; 
        }
        my $remote_mimetype = $response->header('Content-Type');
        my $remote_size = $response->header('Content-Length');
        
        # We save the size and mime information about remote URL
        if ($remote_mimetype)   { $fetch_urls{$url}{mime_type} = $remote_mimetype; }
        if ($remote_size)       { $fetch_urls{$url}{size} = $remote_size; }
        
        # Make sure it doesn't exceed hard limit in size
        if ($remote_size > $max_ext_obj_size)
        {
            $fetch_urls{$url}{status_msg} = "OK Skipping, too large (hard limit)";
            $fetch_urls{$url}{status} = 'warn';
            $fetch_urls{$url}{get} = 0;
            next; 
        }
        
        # If no content-length, we fetch it to see how big it is
        if (!defined($remote_size)) 
        { 
            $fetch_urls{$url}{get} = 1; 
            next; 
        }
        
        # If it's an image, we mark it for fetching if below size limit
        if ((DataURL::Util::is_image_mime_type($remote_mimetype) or 
            DataURL::Util::is_image_mime_type(DataURL::Util::image_mime_type_from_filename($url)))) 
        { 
            if ($remote_size <= $limit)
            {
                $fetch_urls{$url}{get} = 1;
            }
            else
            {
                $fetch_urls{$url}{status_msg} = 'OK Skipping, too large';
                $fetch_urls{$url}{status} = 'warn';
            }
            $fetch_urls{$url}{image} = 1;
        }
        else
        {
            $fetch_urls{$url}{status_msg} = 'OK Skipping, not an image';
            $fetch_urls{$url}{status} = 'warn';
        }
    }
    
    # Iterate again, GET request for those marked for fetching
    foreach my $url (keys(%fetch_urls)) 
    {
        # Skip those not marked for fetching
        if (!$fetch_urls{$url}{get}) { next; }
        
        # Send GET request
        $fetch_urls{$url}{req} = 'GET';
        $request = HTTP::Request->new(GET => $fetch_urls{$url}{full_url});
        $response = $ua->request($request);
        if ($response->is_success)
        {
            $fetch_urls{$url}{status_msg} = $response->status_line . " GET";
        }
        else
        { 
            $fetch_urls{$url}{status_msg} = $response->status_line;
            $fetch_urls{$url}{status} = 'err';
            next; 
        }
        
        my $data = $response->content;
        
        # If we're dealing with an image, we check if it's not too big,
        # and then encode it to base64 and save the dataurl for it for find/replace
        if ($fetch_urls{$url}{image})
        {
            my $datasize = length($data);
            if ($datasize >= $limit)
            {
                $fetch_urls{$url}{status_msg} = "Skipping, image size gt $limit";
                $fetch_urls{$url}{status} = 'warn';
            }
            else
            {
                my $data_url = DataURL::Encode::dataurl_from_dataref(\$data);
                $replace_map{$url} = $data_url;
            }
            $cssinfo{pre}{img_size} += $fetch_urls{$url}{size};
        }
        $cssinfo{pre}{ext_size} += $fetch_urls{$url}{size}
    }
        
    # Calc total sizes
    $cssinfo{pre}{total_size} = $cssinfo{pre}{css_size} + $cssinfo{pre}{ext_size};
    $cssinfo{pre}{total_gzip_size} = $cssinfo{pre}{css_gzip_size} + $cssinfo{pre}{ext_size};
    
    # Set up post info
    $cssinfo{post}{ext_size} = $cssinfo{pre}{ext_size};
    $cssinfo{post}{img_size} = $cssinfo{pre}{img_size};
    
    foreach my $url (sort(keys(%replace_map)))
    {
        $css =~ s/$url/$replace_map{$url}/ig;
        $cssinfo{dataurl_converted} += 1;
        $cssinfo{post}{ext_size} -= $fetch_urls{$url}{size};
        $fetch_urls{$url}{converted} = 1;
        $fetch_urls{$url}{status_msg} = 'OK Converted';
        $fetch_urls{$url}{data_url_size} = length($replace_map{$url});
        if ($fetch_urls{$url}{image}) 
        {
            $cssinfo{post}{img_size} -= $fetch_urls{$url}{size};
        }
    }
    
    # Calculate post-optimization properties
    $cssinfo{post}{css_size} = length($css);
    $cssinfo{post}{data_urls} = $cssinfo{pre}{data_urls} + $cssinfo{dataurl_converted};
    $cssinfo{post}{ext_objects} = $cssinfo{pre}{ext_objects} - $cssinfo{dataurl_converted};
    $cssinfo{post}{requests} = 1 + $cssinfo{post}{ext_objects};
    $cssinfo{post}{total_size} = $cssinfo{post}{css_size} + $cssinfo{post}{ext_size};
    $cssinfo{post}{css_gzip_size} = length(Compress::Zlib::compress($css));
    $cssinfo{post}{total_gzip_size} = $cssinfo{post}{css_gzip_size} + $cssinfo{post}{ext_size};
    
    # Compress CSS, if specified
    if ($compress) { $css = compress($css); }
    $cssinfo{css_output} = $css;
    
    # Add the dict of remote urls, for resource status on client side
    $cssinfo{ext_objects} = \%fetch_urls;
    
    return \%cssinfo;
}

sub _error
{
    my ($msg) = @_;
    my %reply = ( 'error' => $msg );
    return \%reply;
}

sub compress
{
    my ($css) = @_;
    $css =~ s/\r+//gi;
    $css =~ s/\n+//gi;
    $css =~ s/\t+//gi;
    $css =~ s/(?m)([;:])\s+/$1/gi;
    $css =~ s/\s*}\s*/}\n/gi;
    $css =~ s/\s*{\s*/{/gi;
    $css =~ s/[ \t]*,[ \t]*/,/gi;
    $css =~ s/^\s+//;
    $css =~ s/\s+$//;
    return $css;
}

1;