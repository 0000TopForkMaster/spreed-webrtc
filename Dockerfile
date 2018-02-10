FROM ubuntu:xenial

# Set locale.
RUN apt-get clean && apt-get update
RUN apt-get install locales
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

# Base build dependencies.
RUN apt-get update && apt-get install -qy \
	golang \
	nodejs \
	build-essential \
	git \
	automake \
	autoconf

# Add and build Spreed WebRTC server.
ADD . /srv/spreed-webrtc
WORKDIR /srv/spreed-webrtc
RUN ./autogen.sh && \
	./configure && \
	make pristine && \
	make get && \
	make

# Add runtime dependencies.
RUN apt-get update && apt-get install -qy \
	bsdmainutils \
	openssl

COPY scripts/privkey.pem /srv/privkey.pem
COPY scripts/cert.pem /srv/cert.pem
COPY scripts/secrets.conf /srv/secrets.conf

# Add entrypoint.
#COPY scripts/docker_entrypoint.sh /srv/entrypoint.sh

# Create default config file.
RUN cp -v /srv/spreed-webrtc/server.conf.in /srv/spreed-webrtc/default.conf && \
	sed -i 's|listen = 127.0.0.1:8080|listen = 0.0.0.0:80|' /srv/spreed-webrtc/default.conf && \
	sed -i 's|;root = .*|root = /srv/spreed-webrtc|' /srv/spreed-webrtc/default.conf && \
	sed -i 's|;listen = 127.0.0.1:8443|listen = 0.0.0.0:443|' /srv/spreed-webrtc/default.conf && \
	sed -i 's|;certificate = .*|certificate = /srv/cert.pem|' /srv/spreed-webrtc/default.conf && \
	sed -i 's|;key = .*|key = /srv/privkey.pem|' /srv/spreed-webrtc/default.conf
RUN touch /srv/spreed-webrtc/server.conf

# Add mount point for extra things.
#RUN mkdir /srv/extra
#VOLUME /srv/extra

# Tell about our service.
EXPOSE 80
EXPOSE 443

# Define entry point with default command.
CMD ["/srv/spreed-webrtc/bin/spreed-webrtc-server", "-c", "/srv/spreed-webrtc/default.conf"]
