#!/bin/bash
echo "Getting ${1} page ${2}"
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; }

q=`echo ${1} | vietstripper | sed -e 's/ /+/'`

curl -vs "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${q}&t=artist&p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do 
	name=`echo $link | cut -d\" -f4 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //' | vietstripper`
	tit=`echo $name | cut -d- -f1 | vietstripper`
	dlloc=`echo $link | cut -d\" -f6`
	dldest=`echo $dlloc | cut -d/ -f6`
	echo "**** Getting $dlloc --> $dldest; $artist; $tit ***"
	echo $ curl -L -o "${dldest}.mp3" "${dlloc}"
	# wget -O"${dldest}.mp3" $dlloc
	curl -L -o "${dldest}.mp3" "${dlloc}"
	echo "Setting tag information..."
	id3v2 --delete-all "${dldest}.mp3"
	id3v2 -a "${artist}" -t "${tit}" "${dldest}.mp3"
done
echo "Done!"

