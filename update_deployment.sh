#!/bin/sh

rsync -az --progress -rvv --force  web/*    root@dataurl.net:/www/dataurl
rsync -az --progress -rvv --force  modules/*  root@dataurl.net:/www/dataurl/cgi-bin/

perl command_line_tools/compress_css.pl web/html/style.css > /tmp/RANDOMNAME.css 
scp /tmp/RANDOMNAME.css root@dataurl.net:/www/dataurl/html/style.css

perl command_line_tools/compress_html.pl web/html/style.css > /tmp/RANDOMNAME.html 
scp /tmp/RANDOMNAME.html root@dataurl.net:/www/dataurl/html/index.html
