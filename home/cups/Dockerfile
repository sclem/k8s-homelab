FROM docker.io/olbat/cupsd:2022-11-20

#RUN apt-get update

WORKDIR /tmp

RUN wget https://download.brother.com/welcome/dlf103577/dcpl2550dwpdrv-4.0.0-1.i386.deb
RUN dpkg --add-architecture i386 && \
        dpkg --install dcpl2550dwpdrv-4.0.0-1.i386.deb

WORKDIR /
