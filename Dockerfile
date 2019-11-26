FROM debian:stretch

ARG CHROME_RELEASE=latest
ARG CHROMEDRIVER_MAJOR_RELEASE=latest
ARG JITSI_RELEASE=stable

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
ADD https://download.jitsi.org/jitsi-key.gpg.key /tmp/jitsi.key
ADD https://github.com/subchen/frep/releases/download/v1.3.5/frep-1.3.5-linux-amd64 /usr/bin/frep

COPY rootbasefs/ /

RUN \
	tar xfz /tmp/s6-overlay.tar.gz -C / && \
	rm -f /tmp/*.tar.gz && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y apt-transport-https apt-utils ca-certificates gnupg && \
	apt-key add /tmp/jitsi.key && \
	rm -f /tmp/jitsi.key && \
	echo "deb https://download.jitsi.org $JITSI_RELEASE/" > /etc/apt/sources.list.d/jitsi.list && \
	echo "deb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get dist-upgrade -y && \
	apt-cleanup && \
	chmod +x /usr/bin/frep

RUN	\
	mkdir -p /usr/share/man/man1 && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y linux-image-$(uname -r) linux-headers-$(uname -r) && \
	#If Ubuntu
	apt-dpkg-wrap apt-get install -y linux-modules-extra-4.15.0-1049-gcp && \
	apt-dpkg-wrap apt-get install -y linux-modules-extra-$(uname -r) && \
	apt-dpkg-wrap apt-get install -y openjdk-8-jre-headless && \
	apt-cleanup

RUN \
	apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jibri \
	&& apt-cleanup

RUN \
	[ "${CHROME_RELEASE}" = "latest" ] \
	&& curl -4s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
	&& apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y google-chrome-stable \
	&& apt-cleanup \
	|| true

RUN \
        [ "${CHROME_RELEASE}" != "latest" ] \
        && curl -4so /tmp/google-chrome-stable_${CHROME_RELEASE}_amd64.deb http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_RELEASE}_amd64.deb \
	&& apt-dpkg-wrap apt-get update \
        && apt-dpkg-wrap apt-get install -y /tmp/google-chrome-stable_${CHROME_RELEASE}_amd64.deb \
	&& apt-cleanup \
	|| true

RUN \
	[ ${CHROMEDRIVER_MAJOR_RELEASE} = "latest" ] \
	&& CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE)" \
	|| CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROMEDRIVER_MAJOR_RELEASE})" \
	&& curl -4Ls https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_RELEASE}/chromedriver_linux64.zip \
	| zcat >> /usr/bin/chromedriver \
	&& chmod +x /usr/bin/chromedriver \
	&& chromedriver --version

COPY rootfs/ /

VOLUME /config

