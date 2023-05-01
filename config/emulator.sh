#!/bin/bash

if [ $EMULATOR_WEB_LOG == true ]; then
  mkdir -p /root/noVNC/emulator
  param="2>&1 | tee -a /root/noVNC/emulator/emulator.log | tee >(while read line ; do cat /root/noVNC/emulator/emulator.log | aha -l > /root/noVNC/emulator/index.html ; done)"
else
  param=""
fi

emulator="/opt/android/emulator/emulator -avd Android -gpu swiftshader_indirect -accel on -wipe-data -writable-system ${param}"
eval "${emulator}"
