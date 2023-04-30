FROM maven:3-amazoncorretto-17-debian-bullseye

WORKDIR /root

#===============
# Build Arguments
#===============
ARG ANDROID_PLATFORM="android-29"
ARG BUILD_TOOLS="29.0.3"
ARG VNC_PASSWORD=123

#===============
# VNC ENV
#===============
ENV DISPLAY=:0 \
    SCREEN=0 \
    SCREEN_WIDTH=1600 \
    SCREEN_HEIGHT=900 \
    SCREEN_DEPTH=24+32 \
    LOCAL_PORT=5900 \
    TARGET_PORT=6080 \
    VNC_PASSWORD=$VNC_PASSWORD \
    LOG_PATH=/var/log/supervisor

#===============
# Install Packages
#===============
RUN apt-get update -y \
    && apt-get -y install --no-install-recommends \
    libglu1 \
    qemu-kvm \
    libvirt-dev \
    virtinst \
    bridge-utils \
    msr-tools \
    kmod \
    wget \
    cpu-checker \
    unzip \
    xterm \
    x11vnc \
    openbox \
    feh \
    menu \
    ffmpeg \
    libxcomposite-dev \
    jq \
    xvfb \
    python3-xdg \
    procps \
    supervisor \
    curl \
    aha \
    xz-utils

#================================================
# Installing Android SDK
#================================================
RUN mkdir -p /opt/android/sdk \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip commandlinetools-linux-9477386_latest.zip -d /opt/android/sdk \
    && rm commandlinetools-linux-9477386_latest.zip \
    && wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip \
    && unzip platform-tools-latest-linux.zip -d /opt/android/ \
    && rm platform-tools-latest-linux.zip \
    && yes | /opt/android/sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android/ --licenses \
    && /opt/android/sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android/ --update

#================================================
# Initiating Android Emulator
#================================================
RUN /opt/android/sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android/ "emulator" "build-tools;$BUILD_TOOLS" "platforms;$ANDROID_PLATFORM" "system-images;$ANDROID_PLATFORM;google_apis;x86_64" \
    && echo no | /opt/android/sdk/cmdline-tools/bin/avdmanager create avd -n "Android" -k "system-images;$ANDROID_PLATFORM;google_apis;x86_64" \
    && ln -s /opt/android/emulator/emulator /usr/bin \
    && ln -s /opt/android/platform-tools/adb /usr/bin

ENV ANDROID_HOME=/opt/android

#================================================
# Installing latest noVNC and websockify
#================================================
RUN novnc_latest=$(curl -s https://api.github.com/repos/novnc/noVNC/releases/latest | jq -r '.tag_name') \
 && websockify_latest=$(curl -s https://api.github.com/repos/novnc/websockify/releases/latest | jq -r '.tag_name') \
 && curl -L https://github.com/novnc/noVNC/archive/refs/tags/${novnc_latest}.zip --output /root/latest.zip \
 && unzip -x latest.zip \
 && rm -rf /root/latest.zip \
 && mv noVNC-$(echo ${novnc_latest} | cut -c2- ) noVNC \
 && curl -L https://github.com/novnc/websockify/archive/refs/tags/${websockify_latest}.zip --output /root/latest.zip \
 && unzip -x latest.zip \
 && mv websockify-$(echo ${websockify_latest} | cut -c2- ) ./noVNC/utils/websockify \
 && rm -rf /root/latest.zip \
 && mv /root/noVNC/vnc_lite.html /root/noVNC/index.html

 #================================================
# Installing Latest LTS nodejs and Appium
#================================================
RUN nodejs_lts_latest=$(curl -s https://nodejs.org/download/release/index.json | jq -r -c '.[] | select(.lts != false).version' | head -n 1) \
    && wget https://nodejs.org/dist/${nodejs_lts_latest}/node-${nodejs_lts_latest}-linux-x64.tar.xz -P /root/ \
    && tar -xvf $(echo "/root/node-${nodejs_lts_latest}-linux-x64.tar.xz") -C /opt/ \
    && ln -s $(echo "/opt/node-${nodejs_lts_latest}-linux-x64/bin/npm") /usr/bin/ \
    && ln -s $(echo "/opt/node-${nodejs_lts_latest}-linux-x64/bin/node") /usr/bin/ \
    && ln -s $(echo "/opt/node-${nodejs_lts_latest}-linux-x64/bin/npx") /usr/bin/ \
    && npm install -g appium --allow-root --unsafe-perm=true \
    && ln -s $(echo "/opt/node-${nodejs_lts_latest}-linux-x64/bin/appium") /usr/bin/ \
    && mkdir /root/noVNC/appium

#================================================
# openbox configuration
#================================================
ADD logo.png /root/logo.png
ADD .fehbg /root/.fehbg
ADD rc.xml /etc/xdg/openbox/rc.xml
RUN echo /root/.fehbg >> /etc/xdg/openbox/autostart

#================================================
# RUN
#================================================

ADD vnc.sh /root/vnc.sh
ADD appium.sh /root/appium.sh

COPY supervisord.conf /root/

RUN chmod +x /root/vnc.sh && chmod +x /root/supervisord.conf && chmod +x /root/.fehbg && chmod +x /root/appium.sh

EXPOSE 4723 6080

CMD kvm-ok && /usr/bin/supervisord --configuration /root/supervisord.conf
