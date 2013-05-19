#!/usr/bin/perl -w

use HTML::Packer;

my $packer = HTML::Packer->init();
my %opts = ( remove_comments => 1, remove_newlines => 1);

my $file = $ARGV[0] or '';

if (!$file or ! -e $file) {
    die("File '$file' not defined or non-existent.  Pass file as first arg.");
}

my $html;
open(FILE, $file) or die("Error opening file '$file'.");
foreach(<FILE>) {
    $html .= $_;
}
close(FILE);

$packer->minify(\$html,  \%opts);
print $html;
