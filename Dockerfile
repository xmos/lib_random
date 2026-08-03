FROM gcc:15-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libbz2-dev libdivsufsort-dev libjsoncpp-dev libssl-dev libmpfr-dev
