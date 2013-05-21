#!/bin/sh

rsync -az --progress -rvv --exclude web/tmp/log.db --force  web/*    root@dataurl.net:/www/dataurl
rsync -az --progress -rvv --force  perl/*  root@dataurl.net:/www/dataurl/cgi-bin/

# Use minifier script to minify HTML
perl command_line_tools/compress_html.pl web/html/index.html > tmp/RANDOMNAME.html
scp tmp/RANDOMNAME.html root@dataurl.net:/www/dataurl/html/index.html

# Use YUI compressor to compress CSS and JavaScript
java -jar yui-compressor/yuicompressor.jar --type css --charset utf8 -v web/html/style.css > tmp/RANDOMNAME.css 
scp tmp/RANDOMNAME.css root@dataurl.net:/www/dataurl/html/style.css

java -jar yui-compressor/yuicompressor.jar --type js --charset utf8 -v web/html/dataurl.js > tmp/RANDOMNAME.js
scp tmp/RANDOMNAME.js root@dataurl.net:/www/dataurl/html/dataurl.js


