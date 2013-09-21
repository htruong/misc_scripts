#!/bin/bash
command -v vietstripper >/dev/null 2>&1 || { echo >&2 "I require vietstripper but it's not installed. Get it from https://github.com/htruong/vietstripper. Aborting."; exit 1; }
q=`echo ${1} | vietstripper | sed -e 's/ /+/'`
rnd=`tr -dc "[:alpha:]" < /dev/urandom | head -c 8`

function print_pseudo_pls {
  echo -en "$1|$2 - $3\n" | vietstripper >> /tmp/zing_$rnd
}

function dl_nonprem {
curl -s "http://mp3.zing.vn/tim-kiem/bai-hat.html?q=${1}&t=artist&p=${2}" 2>&1 | grep  "/download/song/" | while read link 
do 
	name=`echo $link | cut -d\" -f4 | sed -e 's/^Download //'`
	artist=`echo $name | cut -d- -f2 | sed -e 's/^ //'`
	tit=`echo $name | cut -d- -f1 | sed 's/ *$//g'`
	dlloc=`echo $link | cut -d\" -f6`
	dldest=`echo $dlloc | cut -d/ -f6`
	print_pseudo_pls "${dlloc}" "${artist}" "${tit}"
done
}

echo -en "[playlist]\n"
for i in {1..3}
do
  dl_nonprem $q $i
done

counter=`wc -l /tmp/zing_$rnd | cut -d" " -f1`
echo -en "NumberOfEntries=$counter\n"

counter=1
while read line; do 
  dlloc=`echo $line | cut -d'|' -f1`
  title=`echo $line | cut -d'|' -f2`
  echo -en "File$counter=$dlloc\nTitle$counter=$title\nLength$counter=-1\n"
  ((counter++))
done < /tmp/zing_$rnd

echo -en "Version=2\n"

rm /tmp/zing_$rnd
