#!/bin/bash

if [ $APPIUM_WEB_LOG == true ]; then
  mkdir -p /root/noVNC/appium
  param="2>&1 | tee -a /root/noVNC/appium/appium.log | tee >(while read line ; do cat /root/noVNC/appium/appium.log | aha -l > /root/noVNC/appium/index.html ; done)"
else
  param=""
fi

appium="appium -p 4723 ${param}"
eval "${appium}"