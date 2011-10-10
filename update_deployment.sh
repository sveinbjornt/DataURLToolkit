#!/bin/sh

rsync -az --progress -rvv --force  web/*    root@dataurl.net:/www/dataurl
rsync -az --progress -rvv --force  modules/*  root@dataurl.net:/www/dataurl/cgi-bin/