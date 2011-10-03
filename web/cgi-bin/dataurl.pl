use strict; # yes, oh yes
use utf8;
use CGI;
use URI::Split qw(uri_split uri_join);
use LWP::Simple;
use Image::Info qw(image_info);
use MIME::Base64;
use Compress::Zlib;
use JSON;

binmode(STDOUT, ":utf8");


local our $cgi = new CGI;
local our $action = $cgi->param('action');
local our $file = $cgi->param('file');
local our $limit = $cgi->param('size_limit') * 1024;
local our $compress = $cgi->param('compress');
local our %cssinfo;


if ($action eq 'optimize') 
{    
    my $css = get($file);
    
    # Find and clean all strings contained within url()
    my (@matches) = $css =~ m/url\s?\(\s?"?'?(\s?.+\s?)'?"?\)/ig;
    foreach (@matches) { $_ = strip($_); }
    
    if ($compress eq 'on') 
    { 
        $css =~ s/\n+//g;
        $css =~ s/\t+//g;
        $css =~ s/(?m)([;:])\s+/$1/gi;
        $css =~ s/\s*}\s*/}\n/gi;
        $css =~ s/\s*{\s*/{/gi;
        $css =~ s/[ \t]*,[ \t]*/,/gi;
        $css =~ s/^\s+//;
        #$css =~ s/\s+//g;
    }
    
    $cssinfo{pre}{css_size} = length($css);
    $cssinfo{pre}{css_gzip_size} = length(Compress::Zlib::compress($css));
    $cssinfo{pre}{data_urls} = 0;
    
    my @fetch_urls;
    foreach my $url (@matches)
    {
        if ($url =~ /^data\:/) { $cssinfo{pre}{data_urls} += 1; next; }
        push(@fetch_urls, $url);
    }
    
    $cssinfo{pre}{ext_objects} = scalar(@fetch_urls);
    $cssinfo{pre}{requests} = 1 + $cssinfo{pre}{ext_objects};
    $cssinfo{pre}{img_size} = 0;
    $cssinfo{pre}{ext_size} = 0;
    $cssinfo{pre}{total_size} = 0;
    $cssinfo{dataurl_converted} = 0;
    
    my %replace_map;
    my %ext_obj_sizes;
    
    foreach my $url (@fetch_urls)
    {
        my $full_url = urljoin($file, $url);
        my $data = get($full_url);
        
        if (($url =~ m/\.jpg$/i or $url =~ m/\.png$/i or $url =~ m/\.gif$/i or $url =~ m/\.jpeg$/i) and length($data) <= $limit)
        {         
            my $info = image_info(\$data);
            my $mimetype = $info->{file_media_type};
            my $base64data = encode_base64($data, '');
            my $dataurl = "data:" . $mimetype . ";base64," . $base64data;
          
            $replace_map{$url} = $dataurl;
            $cssinfo{pre}{img_size} += length($data);
        }
        $cssinfo{pre}{ext_size} += length($data);
        $ext_obj_sizes{$url} = length($data);
    }
    $cssinfo{pre}{total_size} = $cssinfo{pre}{css_size} + $cssinfo{pre}{ext_size};
    $cssinfo{pre}{total_gzip_size} = $cssinfo{pre}{css_gzip_size} + $cssinfo{pre}{ext_size};
    $cssinfo{post}{ext_size} = $cssinfo{pre}{ext_size};
    $cssinfo{post}{img_size} = $cssinfo{pre}{img_size};
    
    foreach my $origurl (sort(keys(%replace_map)))
    {
        $css =~ s/$origurl/$replace_map{$origurl}/ig;
        $cssinfo{dataurl_converted} += 1;
        $cssinfo{post}{ext_size} -= $ext_obj_sizes{$origurl};
        if ($origurl =~ m/\.jpg$/i or $origurl =~ m/\.png$/i or $origurl =~ m/\.gif$/i or $origurl =~ m/\.jpeg$/i) 
        {
            $cssinfo{post}{img_size} -= $ext_obj_sizes{$origurl};
        }
    }
    $cssinfo{post}{css_size} = length($css);
    $cssinfo{post}{data_urls} = $cssinfo{pre}{data_urls} + $cssinfo{dataurl_converted};
    $cssinfo{post}{ext_objects} = $cssinfo{pre}{ext_objects} - $cssinfo{dataurl_converted};
    $cssinfo{post}{requests} = 1 + $cssinfo{post}{ext_objects};
    $cssinfo{post}{total_size} = $cssinfo{post}{css_size} + $cssinfo{post}{ext_size};
    $cssinfo{post}{css_gzip_size} = length(Compress::Zlib::compress($css));
    $cssinfo{post}{total_gzip_size} = $cssinfo{post}{css_gzip_size} + $cssinfo{post}{ext_size};
    $cssinfo{css_output} = $css;
    
    # foreach (keys(%cssinfo)) {
    #     print $_ . ' : ' . $cssinfo{$_} . "\n";
    # }
    # 
    # print $css;
    print "Content-Type: application/json\n\n";
    print encode_json(\%cssinfo);
    exit(0);
}



sub strip
{
    my ($s) = @_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    $s =~ s/^'//;
    $s =~ s/'$//;
    $s =~ s/^"//;
    $s =~ s/"$//;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
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






