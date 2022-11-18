#!/bin/bash
DIR='packages'
if [ -d $DIR ]; then
	echo "deleting existing packages"
	rm -rf ./$DIR
	mkdir $DIR
fi
URL_LIST=("https://github.com/rsms/sublime-theme/archive/refs/heads/main.zip" "https://github.com/chriskempson/base16-textmate/archive/refs/heads/master.zip")
echo "fetching sublime packages"
for f in "${URL_LIST[@]}"; do
	wget -P ./$DIR/ "${f}"
done
cd ./$DIR
echo "unzipping all packages"
ls *.zip | xargs -n 1 -P 4 unzip
echo "removing package zips"
rm *.zip