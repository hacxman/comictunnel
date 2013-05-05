#!/usr/bin/bash

WORLD_SERVER=127.0.0.1
WORLD_PORT=80

TUNNEL_PORT=8889

INPUT_BUFFER_SIZE=1

rm fifo/{a,b,c,d,u,v}
mkfifo fifo/{a,b,c,d,u,v}

exec 5<>fifo/a
exec 6<>fifo/b

exec 7<>fifo/c
exec 8<>fifo/d

exec 10<>fifo/u
exec 11<>fifo/v

alias worldnc="nc $WORLD_SERVER $WORLD_PORT >&5 <&6 &"
alias tunnelnc="nc -l $TUNNEL_PORT >&7 <&8 &"

#function wait_wrap() {
#  wait %$1
#  echo $#
#  echo "$1 ended"
#  if [ $# == 2 ] ; then
#    echo "$1 ended -> fifo/$2"
#    echo $1 > fifo/$2
#  fi
#}

function from_world() {
  sleep 1
  SHOULDDIS=0
  while true ; do
#    read -u 5 -n $INPUT_BUFFER_SIZE INP
#    echo "$INP"
    read -n 7 -u 11 -t 0 TRM
    if [ $? == 0 ] ; then
      SHOULDDIS=1
    fi
#    if [ $SHOULDDIS == 1 ] ; then
#      read -n 0 -u 5 LALA
#      if [ $? == 1 ] ; then
#        echo 1 >&8
#      fi 
#    fi
    ENCD=$(head -c $INPUT_BUFFER_SIZE fifo/a | base64 | ../magicwand.py -e)

#    echo "$ENCD"
#    echo 'encoding'
    rm oo1.png
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
        echo IT
        if [ $S == 0 ] ; then
          sleep 1
          echo 1 >&11
          echo WORLD DISCONNECTED
          sleep 1
          echo 1 >&10
          S=1
        fi
        ;;
      1)
        wait_wrap "nc $WORLD_SERVER $WORLD_PORT >&5 <&6" u &
        echo SOCKET REOPEN
        S=0
        ;;
      2)
        echo attemtping to kill world
        kill $PID
        ;;
      3)
        echo attemtping to kill world $PID
        kill $PID
        S=1
        ;;
      4)
        read -u 10 PID
        ;;
    esac
  done
}
#function wait_world() {
#  read -u 10 WRLD
##  if [ $? == 0 ] ; then
##    echo 1 >&8
##    echo WORLD DISCONNECTED
##  fi
#  echo 1 >&8
#}

function from_tunnel() {
  sleep 1
  echo HUUUU
  wait_wrap "nc -l $TUNNEL_PORT >&7 <&8" &
  #wait_wrap 1 &

  HASCONN=0
  INP=0

  wait_world_and_respawn &
  while true ; do
#    read -n 10 fifo/u TUNST
#    if [ $TUNST == 1 ] ; then
#      echo tunndead
#      nc -l $TUNNEL_PORT >&7 <&8 &
#      wait_wrap 1 u &
#    fi

#    read -u 10 -t 0 WRLD
#    if [ $? == 0 ] ; then
#      echo 1 >&8
#      echo WORLD DISCONNECTED
#    fi

    read -u 7 -n 75 CMD

    case $CMD in
      1)
#        kill %3
        echo 3 >&10
        HASCONN=0
        echo STREAM CLOSE
        continue
        ;;
      2)
        if [ $HASCONN == 0 ] ; then
          echo STREAM OPEN
          echo 1 >&10
#          wait_wrap "nc $WORLD_SERVER $WORLD_PORT >&5 <&6" u &
#          wait_world &
#          wait_wrap 3 u &
          HASCONN=1
        fi
        continue
        ;;
    esac

    read -u 7 -n 75 INP2
#    echo inp2=$INP2
    if [ $INP2 == 0 ] ; then
      continue
    fi
#    echo read from tunnel
    read -u 7 -N $INP2 IMG
#    echo read from tunnel
    echo "$IMG" > oo2.b64
#    echo "$IMG"
    cp oo2.b64 $(date +%Y%H%M%S.b64)
    base64 -d oo2.b64 > oo2.tif

    rm testpout.txt
    tesseract oo2.tif testpout 2>/dev/null 1>/dev/null
    FUHA=$(cat testpout.txt | ../magicwand.py -d)
#    echo -n "$FUHA"
#    echo -n "$FUHA" | sed -e 's/[[:space:]]*\([[:graph:]]*\)[[:space:]]*/\1\n/g' | base64 -d -i
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


from_world &
from_tunnel
#echo started
#jobs
#for j in $(seq 1) ; do
#  wait_wrap2 $j &
#done
#wait_wrap2 $((j+1))
