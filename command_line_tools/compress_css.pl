#!/usr/bin/perl -w

use strict;
use utf8;
use lib ('../perl/');
use DataURL::CSS qw(compress_css);

if (scalar(@ARGV) < 1) { die("Missing CSS filename argument"); }

open(FILE, "+>$ARGV[0]") or die("Error opening $ARGV[0]");
my $css = join('', <FILE>);
close(FILE);

print compress_css($css);
exit 0;
