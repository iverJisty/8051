#!/bin/bash

clear
cat /dev/ttyUSB0 &
while read -sN1 key # 1 char (not delimiter), silent
do
  # catch multi-char special key sequences
  read -sN1 -t 0.0001 k1
  read -sN1 -t 0.0001 k2
  read -sN1 -t 0.0001 k3
  key+=${k1}${k2}${k3}

  case "$key" in
    
    $'\e[A' | $'\e0A')  
        echo 'u' > /dev/ttyUSB0;;

    $'\e[B' | $'\e0B')
        echo 'd' > /dev/ttyUSB0;;

    $'\e[D' | $'\e0D')
        echo 'l' > /dev/ttyUSB0;;

    $'\e[C' | $'\e0C') 
        echo 'r' > /dev/ttyUSB0;;
  
  esac                  
    

    

done
