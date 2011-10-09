#!/bin/sh

if [ ! -e command_line_tools/dataurlmaker.pl ]
then
    echo "must be run from Data URL Toolkit repository root"
    exit
fi

echo "-> Removing old tarballs"
rm /tmp/DataURLToolkit.tgz &> /dev/null
rm web/html/downloads/dataurlmaker.tgz &> /dev/null
rm web/html/downloads/Apache-DataURL.tgz &> /dev/null
rm web/html/downloads/downloads/DataURL-Modules.tgz &> /dev/null

echo "-> Creating DataURLToolkit.tgz"
tar cvfz /tmp/DataURLToolkit.tgz .
mv /tmp/DataURLToolkit.tgz web/html/downloads/DataURLToolkit.tgz

echo "-> Creating dataurlmaker.tgz"
tar cvfz web/html/downloads/dataurlmaker.tgz command_line_tools/dataurlmaker.pl

echo "-> Creating Apache-DataURL.tgz"
tar cvfz web/html/downloads/Apache-DataURL.tgz apache/Apache-DataURL.pm
