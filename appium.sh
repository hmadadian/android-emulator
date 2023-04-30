#!/bin/bash

appium -p 4723 2>&1 | tee -a /root/noVNC/appium/appium.log | tee >(while read line ; do cat /root/noVNC/appium/appium.log | aha -l > /root/noVNC/appium/index.html ; done)
