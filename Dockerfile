FROM maven:3-amazoncorretto-17-debian-bullseye

WORKDIR /root

ENV DISPLAY=:0 \
    SCREEN=0 \
    SCREEN_WIDTH=1600 \
    SCREEN_HEIGHT=900 \
    SCREEN_DEPTH=24+32 \
    LOCAL_PORT=5900 \
    TARGET_PORT=6080 \
    VNC_PASSWORD=123 \
    LOG_PATH=/var/log/supervisor


RUN apt-get update -y \
    && apt-get -y install --no-install-recommends \
    libglu1 qemu-kvm libvirt-dev virtinst bridge-utils msr-tools kmod wget cpu-checker unzip xterm x11vnc openbox feh menu ffmpeg jq xvfb python3-xdg procps supervisor curl \
    && kvm-ok

#================================================
# installing latest noVNC and websockify
#================================================
RUN novnc_latest=$(curl -s https://api.github.com/repos/novnc/noVNC/releases/latest | jq -r '.tag_name') \
 && websockify_latest=$(curl -s https://api.github.com/repos/novnc/websockify/releases/latest | jq -r '.tag_name') \
 && curl -L https://github.com/novnc/noVNC/archive/refs/tags/${novnc_latest}.zip --output /root/latest.zip \
 && unzip -x latest.zip \
 && rm -rf latest.zip  \
 && mv noVNC-${novnc_latest:1} noVNC \
 && curl -L https://github.com/novnc/websockify/archive/refs/tags/${websockify_latest}.zip --output /root/latest.zip \
 && unzip -x latest.zip \
 && mv websockify-${websockify_latest:1} ./noVNC/utils/websockify \
 && rm -rf latest.zip

#================================================
# openbox configuration
#================================================

ADD logo.jpg /root/logo.jpg
ADD .fehbg /root/.fehbg
ADD rc.xml /etc/xdg/openbox/rc.xml
RUN echo /root/.fehbg >> /etc/xdg/openbox/autostart

#================================================
# x11vnc configuration
#================================================

ADD vnc.sh /root/vnc.sh

EXPOSE 6080

COPY supervisord.conf /root/

RUN chmod +x /root/vnc.sh && chmod +x /root/supervisord.conf

CMD /usr/bin/supervisord --configuration supervisord.conf
