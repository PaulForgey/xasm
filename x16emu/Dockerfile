FROM ubuntu:latest

RUN apt-get update \
	&& apt-get install -y unzip \
	&& apt-get install -y libsdl2-dev

ADD https://github.com/X16Community/x16-emulator/releases/download/r48/x16emu_linux-x86_64-r48.zip /

RUN unzip x16emu_linux-x86_64-r48.zip

ENV SDL_VIDEODRIVER=dummy
ENV SDL_AUDIODRIVER=dummy

