#!/usr/bin/bash

SERVER=127.0.0.1
CLIENT_PORT=8888
SERVER_PORT=8889

rm fifo/{a,b,c,d}
mkfifo fifo/{a,b,c,d}

exec 5<>fifo/a
exec 6<>fifo/b

exec 7<>fifo/c
exec 8<>fifo/d

nc -l $CLIENT_PORT >&5 <&6 &
nc $SERVER $SERVER_PORT >&7 <&8 &

function from_user() {
  sleep 1
  while true ; do
    read -u 5 -n 75 INP
    ENCD=$(echo $INP | base64 | ../magicwand.py -e)
    echo $ENCD
    echo $(echo $IMP | base64)
    echo $IMP
    echo 'encoding'
    echo "$ENCD" | convert -monochrome -pointsize 40 -font /usr/share/fonts/msttcore/comic.ttf label:@- oo1.png
    rm oo1.tif
    convert oo1.png oo1.tif
    #echo '-->ocr'
    base64 oo1.tif > oo1.b64
    echo $(stat --format=%s oo1.b64) >&8
    cat oo1.b64 >&8
    echo .
  done
}

function from_tunnel() {
  sleep 1
  while true ; do
    read -u 7 -n 75 INP2
    echo inp2=$INP2
    read -u 7 -N $INP2 IMG
    echo read from tunnel
    echo "$IMG" > oo2.b64
    base64 -d oo2.b64 > oo2.tif

    tesseract oo2.tif testpout 2>/dev/null 1>/dev/null
    FUHA=$(cat testpout.txt | ../magicwand.py -d)
    echo -n "$FUHA" | base64 -d -i
    echo -n "$FUHA" | base64 -d -i >&6
#    echo >&6
    echo ,
  done
}

from_user &
from_tunnel &
echo started
wait %1
wait %2

