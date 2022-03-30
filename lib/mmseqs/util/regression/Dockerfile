FROM soedinglab/mmseqs2
RUN apt-get -yy update \
    && apt-get -yy --no-install-recommends install git cmake build-essential time wget \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/benchmark
ADD . .
ADD ./samtools/samtools-linux /usr/local/bin/samtools
RUN ./run_regression.sh mmseqs /tmp/regression

