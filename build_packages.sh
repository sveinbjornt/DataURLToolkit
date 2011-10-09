#!/bin/sh

if [ ! -e command_line_tools/dataurlmaker.pl ]
then
    echo "must be run from Data URL Toolkit repository root"
    exit
fi

# Remove old tarballs
rm /tmp/DataURLToolkit.tgz &> /dev/null
rm web/html/downloads/dataurlmaker.tgz &> /dev/null
rm web/html/downloads/Apache-DataURL.tgz &> /dev/null

# Create repository tarball
tar cvfz /tmp/DataURLToolkit.tgz .

# Move repo tarball to download path
mv /tmp/DataURLToolkit.tgz web/html/downloads/DataURLToolkit.tgz

# Perl command line tool
tar cvfz web/html/downloads/dataurlmaker.tgz command_line_tools/dataurlmaker.pl

# Apache module
tar cvfz web/html/downloads/Apache-DataURL.tgz apache/Apache-DataURL.pm
