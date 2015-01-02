#!/bin/bash

as31 serialgame.asm
sudo ./up /dev/ttyUSB0 serialgame.hex
clear
./sh.sh

