#!/bin/bash
echo "Getting ${1} page ${2}"
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; }
command -v id3v2 >/dev/null 2>&1 || { echo >&2 "I require id3v2 but it's not installed. Aborting."; exit 1; }

q=`echo ${1} | vietstripper | sed -e 's/ /+/'`


function dl_song {
	tmptit=`echo "$3" | sed 's/[ \t]*$//'`
	tmpart=`echo "$2" | sed 's/[ \t]*$//'`
	artistS=`echo "$tmpart" | vietstripper`
	titS=`echo "$tmptit" | vietstripper`
	destfn=`echo "${artistS} - ${titS}.mp3"`
	echo "**** Getting $1 --> ${destfn} [$tmpart; $tmptit] ***"
	curl -L -o "${destfn}" "${1}"

	echo "Clearing ID3 shit..."
	id3v2 --delete-all "${destfn}"
	echo "Setting tag information..."
	id3v2 -a "${artistS}" -t "${titS}" "${destfn}"
}

function dl_nonprem {

echo "Downloading non-premium shit..."

curl -s "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${1}&t=artist&p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do 
	name=`echo $link | cut -d\" -f4 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //'`
	tit=`echo $name | cut -d- -f1`
	dlloc=`echo $link | cut -d\" -f6`
	dldest=`echo $dlloc | cut -d/ -f6`
	dl_song "${dlloc}" "${artist}" "${tit}"
done
}

function stripcdatashit {
	echo `echo "$1" | cut -d'[' -f3`
}

function dl_prem {

echo "Downloading premium shit..."

curl -vs "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${1}&t=artist&p=${2}" 2>&1 | grep  "_loginToBuy" | while read link
do
	pageID=`echo $link | cut -d\" -f20`
	pageCont=`curl -s "http://mp3.zing.vn/bai-hat/Screw-You/${pageID}.html" 2>&1 | grep "player" | grep  "xml/song-xml"`
	# echo $pageCont
	xmlURL=`echo $pageCont | grep -m 1 -o 'mp3\.zing\.vn\/xml\/song\-xml/[^\"]*' | sed -e 's/\&amp\;/\&/'`
	# echo XML URL ${xmlURL}
	curl -s "http://${xmlURL}" 2>&1 | sed -e 's/\n//' | sed -e 's/]/\n]/' | sed -e 's/\r//g' > tmp.txt
	titU=`cat tmp.txt | grep '<title'`
	tit=`stripcdatashit "$titU"`
	artistU=`cat tmp.txt | grep '<performer' | cut -d'[' -f3`
	artist=`stripcdatashit "$artistU"`
	dllinkU=`cat tmp.txt | grep '<source' | cut -d'[' -f3`
	dllink=`stripcdatashit "$dllinkU"`
	dl_song "${dllink}" "${artist}" "${tit}"
done
}

dl_nonprem $q $2
dl_prem $q $2


echo "Done!"

