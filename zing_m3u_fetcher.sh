#!/bin/bash
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
q=`echo ${1} | vietstripper | sed -e 's/ /+/'`

function print_pseudo_m3u {
  echo -en "#EXTINF:-1,$2 - $3\n$1\n\n" | vietstripper
}

function dl_nonprem {
curl -s "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${1}&t=artist&p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do 
	name=`echo $link | cut -d\" -f4 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //'`
	tit=`echo $name | cut -d- -f1 | sed 's/ *$//g'`
	dlloc=`echo $link | cut -d\" -f6`
	dldest=`echo $dlloc | cut -d/ -f6`
	print_pseudo_m3u "${dlloc}" "${artist}" "${tit}"
done
}

echo -en "#EXTM3U\n\n"
for i in {1..3}
do
  dl_nonprem $q $i
done

