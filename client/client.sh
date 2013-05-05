#!/usr/bin/bash

SERVER=127.0.0.1
CLIENT_PORT=8888
SERVER_PORT=8889
INPUT_BUFFER_SIZE=1

rm fifo/{a,b,c,d,u,v,w}
mkfifo fifo/{a,b,c,d,u,v,w}

exec 5<>fifo/a
exec 6<>fifo/b

exec 7<>fifo/c
exec 8<>fifo/d

exec 10<>fifo/u
exec 11<>fifo/v
exec 12<>fifo/w


function from_user() {
  sleep 1
  HASCONN=0
  while true ; do
    #read -u 5 -n $INPUT_BUFFER_SIZE INP
    #ENCD=$(echo -n $INP | base64 | ../magicwand.py -e)
    read -n 7 -u 11 -t 0 TRM
    if [ $? == 0 ] ; then
      HASCONN=0
      echo 1 >&8
    fi

    if [ $HASCONN == 0 ] ; then
      read -u 12 NCON
      echo 2 >&8
      HASCONN=1
    fi
    ENCD=$(head -c $INPUT_BUFFER_SIZE fifo/a | base64 | ../magicwand.py -e)

#    if [ $HASCONN == 0 ] ; then
#      echo 2 >&8
#    fi

#    echo "$ENCD"
#    echo "$(echo $INP | base64)"
#    echo $IMP
#    echo 'encoding'
    
    echo "0, $ENCD" | convert -monochrome -pointsize 72 -font /usr/share/fonts/msttcore/comic.ttf label:@- oo1.png

    rm oo1.tif
    convert oo1.png oo1.tif
    base64 oo1.tif > oo1.b64

    echo 0 >&8
    echo $(stat --format=%s oo1.b64) >&8
    cat oo1.b64 >&8
    echo -n ';'
  done
}

function wait_world_and_respawn() {
  PID=0
  S=0
  while true ; do
    read -u 10 WRLD
    case $WRLD in
      0)
        echo 1 >&11
        echo WORLD DISCONNECTED
        sleep 1
        if [ $S == 0 ] ; then
          echo 1 >&10
          S=1
        fi
        ;;
      1)
        wait_wrap "nc -v -l $CLIENT_PORT >&5 <&6 2>&12" u &
        echo SOCKET REOPEN
        S=0
        ;;
      2)
        echo attemtping to kill world
        kill $PID
        ;;
      3)
        echo attemtping to kill world
        kill $PID
        S=1
        ;;
      4)
        read -u 10 PID
        ;;
    esac
  done
}

function from_tunnel() {
alias clientnc="nc -l $CLIENT_PORT >&5 <&6 &"
alias servernc="nc $SERVER $SERVER_PORT >&7 <&8 &"
  sleep 1
#  servernc
  wait_wrap "nc $SERVER $SERVER_PORT >&7 <&8" &
#  jobs
#  wait_wrap 1 &
  HASCONN=0

  wait_wrap "nc -v -l $CLIENT_PORT >&5 <&6 2>&12" u &
  wait_world_and_respawn &
#  wait_wrap 3 u &

  while true ; do
#    read -u 10 -t 0 WRLD
#    if [ $? == 0 ] ; then
#      echo 1 >&8
#      echo CLIENT DISCONNECTED
#
#      wait_wrap "nc -l $CLIENT_PORT >&5 <&6" &
##      wait_wrap 3 &
#      echo SOCKET REOPEN
#    fi
    read -u 7 -n 75 CMD

    case $CMD in
      1)
        echo 3 >&10
#        kill %3
        HASCONN=0
        echo STREAM CLOSE
        sleep 1

        echo 1 >&10
        #wait_wrap "nc -l $CLIENT_PORT >&5 <&6" &
#        wait_wrap 3 &
        #echo SOCKET REOPEN
        continue
        ;;
    esac


    read -u 7 -n 75 INP2
#    echo inp2=$INP2
    read -u 7 -N $INP2 IMG
#    echo read from tunnel
    echo "$IMG" > oo2.b64
    base64 -d oo2.b64 > oo2.tif

    rm testpout.txt
    tesseract oo2.tif testpout 2>/dev/null 1>/dev/null
    FUHA=$(cat testpout.txt | ../magicwand.py -d)
#    echo -n "$FUHA" | base64 -d -i
    echo -n "$FUHA" | base64 -d -i >&6
#    echo >&6
    echo -n ,
  done
}

function wait_wrap() {
#  sleep 1
  #echo inwrap3
  eval "$1 &"
  P=$!
  if [ $# == 2 ] ; then
    echo 4 > fifo/$2
    echo $P > fifo/$2
  fi
  wait $P
  #echo $#
  echo "$1 ended"
  if [ $# == 2 ] ; then
    echo "$1 ended -> fifo/$2"
    echo 0 > fifo/$2
  fi
}

function wait_wrap2() {
  wait %$1
  echo "$1 ended"
}

from_user &
from_tunnel
#echo started
#jobs
#for j in $(seq 1) ; do
#  wait_wrap2 $j &
#done
#wait_wrap2 $((j+1))
