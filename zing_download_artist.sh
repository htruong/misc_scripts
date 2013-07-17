#!/bin/bash

## Zing downloader
## Do something like this
## ./zing_download_artist.sh "Dan Truong" 1

echo "Getting ${1} page ${2}"
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; }
command -v id3v2 >/dev/null 2>&1 || { echo >&2 "I require id3v2 but it's not installed. Aborting."; exit 1; }

q=`echo ${1} | vietstripper | sed -e 's/ /-/'`

function dl_song {
	artistS=`echo "$2" | vietstripper`
	titS=`echo "$3" | vietstripper`
	destfn=`echo "${artistS} - ${titS}.mp3"`
	echo "**** Getting ${destfn} [$2; $3] ***"
	echo "**** URL $1 ***"

	curl -L -o "${destfn}" "${1}"
	
	echo "Clearing ID3 shit..."
	id3v2 --delete-all "${destfn}"
	echo "Setting tag information..."
	id3v2 -a "${artistS}" -t "${titS}" "${destfn}"
}

function dl_nonprem {
echo "Downloading shit..."
curl -s "http://mp3.zing.vn/nghe-si/${1}/bai-hat?p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do
	echo "$link"
	name=`echo $link | cut -d\" -f2 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //'`
	tit=`echo $name | cut -d- -f1`
	dlloc=`echo $link | cut -d\" -f6`
	dl_song "${dlloc}" "${artist}" "${tit}"
done
}

function stripcdatashit {
	echo `echo "$1" | cut -d'[' -f3`
}

dl_nonprem $q $2

echo "Done!"

