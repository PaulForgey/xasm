FROM ubuntu:latest

RUN apt-get update \
	&& apt-get install -y unzip \
	&& apt-get install -y libsdl2-dev

ADD https://github.com/X16Community/x16-emulator/releases/download/r47/x16emu_linux-x86_64-r47.zip /

RUN unzip x16emu_linux-x86_64-r47.zip

ENV SDL_VIDEODRIVER=dummy
ENV SDL_AUDIODRIVER=dummy

