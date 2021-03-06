#!/bin/bash
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
q=`echo ${1} | vietstripper | sed -e 's/ /+/'`

function print_pseudo_json {
  echo -n "{\"location\":\"$1\",\"artist\":\"$2\",\"title\":\"$3\"},"
}

function dl_nonprem {
curl -s "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${1}&t=artist&p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do 
	name=`echo $link | cut -d\" -f4 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //'`
	tit=`echo $name | cut -d- -f1 | sed 's/ *$//g'`
	dlloc=`echo $link | cut -d\" -f6`
	dldest=`echo $dlloc | cut -d/ -f6`
	print_pseudo_json "${dlloc}" "${artist}" "${tit}"
done
}

echo -n "{\"songs\":["
dl_nonprem $q $2
echo -n "null]}"



