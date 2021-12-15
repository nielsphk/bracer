FROM trinityrnaseq/trinityrnaseq:2.13.2

## set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin

RUN apt-get update && apt-get -y upgrade
RUN apt-get update && apt-get -y install zlib1g-dev git openjdk-8-jre libglib2.0-dev pigz

RUN pip3 install scikit-learn

RUN apt-get update && apt-get -y install libgd3 libgts-0.7-5 liblasi0 libltdl7 freeglut3 libglade2-0 libglu1-mesa libglu1 libgtkglext1 libxaw7 graphviz libffi-dev
#RUN apt-get update && apt-get -y install libgd3 libgts-0.7-5 liblasi0v5 libltdl7 freeglut3 libglade2-0 libglu1-mesa libglu1 libgtkglext1 libxaw7 graphviz libffi-dev

#phylip
RUN wget https://evolution.gs.washington.edu/phylip/download/phylip-3.697.tar.gz && \
	tar xzvf phylip-3.697.tar.gz && rm phylip-3.697.tar.gz &&\
	cd phylip-3.697/src && make -f Makefile.unx install

#Trim Galore! 
RUN curl -fsSL https://github.com/FelixKrueger/TrimGalore/archive/0.6.6.tar.gz -o trim_galore.tar.gz &&\
	tar xvzf trim_galore.tar.gz && mv TrimGalore-0.6.6/trim_galore $BIN

WORKDIR $SRC
ENV SEQTK_VER 1.3
RUN wget https://github.com/lh3/seqtk/archive/v${SEQTK_VER}.tar.gz && \
 tar -xzvf v${SEQTK_VER}.tar.gz && \
 rm v${SEQTK_VER}.tar.gz && \
 cd seqtk-${SEQTK_VER} && \
 make
 
ENV PATH="${PATH}:${SRC}/seqtk-${SEQTK_VER}"

#bracer proper, no need to reposition resources as config will now know where this lives
RUN cd /
COPY . /bracer
RUN cd /bracer && pip3 install -r requirements.txt && python3 setup.py install

## Bowtie2
WORKDIR $SRC
ENV BOWTIE2_VERSION 2.2.9
RUN wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/${BOWTIE2_VERSION}/bowtie2-${BOWTIE2_VERSION}-linux-x86_64.zip/download -O bowtie2-${BOWTIE2_VERSION}-linux-x86_64.zip && \
    unzip bowtie2-${BOWTIE2_VERSION}-linux-x86_64.zip && \
    mv bowtie2-${BOWTIE2_VERSION}/bowtie2* $BIN && \
    rm *.zip && \
    rm -r bowtie2-${BOWTIE2_VERSION}



# Download and extract IgBLAST
#WORKDIR $SRC
ENV IGBLAST_VERSION 1.17.1
RUN wget https://ftp.ncbi.nih.gov/blast/executables/igblast/release/${IGBLAST_VERSION}/ncbi-igblast-${IGBLAST_VERSION}-x64-linux.tar.gz && \
	tar xvf ncbi-igblast-${IGBLAST_VERSION}-x64-linux.tar.gz && \
	cp ncbi-igblast-${IGBLAST_VERSION}/bin/* $BIN && \ 
	rm ncbi-igblast-${IGBLAST_VERSION}-x64-linux.tar.gz &&\
	mkdir -p /usr/local/share/igblast &&\
	bash /bracer/scripts/fetch_igblastdb.sh -o /usr/local/share/igblast &&\
	mv ncbi-igblast-${IGBLAST_VERSION}/internal_data ncbi-igblast-${IGBLAST_VERSION}/optional_file /usr/local/share/igblast &&\
	rm -r ncbi-igblast-${IGBLAST_VERSION}


#obtaining the transcript sequences, no need for kallisto/salmon indices
RUN mkdir GRCh38 && cd GRCh38 && wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_38/gencode.v38.transcripts.fa.gz && \
	gunzip gencode.v38.transcripts.fa.gz && python3 /bracer/docker_helper_files/gencode_parse.py gencode.v38.transcripts.fa && rm gencode.v38.transcripts.fa
RUN mkdir GRCm38 && cd GRCm38 && wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M27/gencode.vM27.transcripts.fa.gz && \
	gunzip gencode.vM27.transcripts.fa.gz && python3 /bracer/docker_helper_files/gencode_parse.py gencode.vM27.transcripts.fa && rm gencode.vM27.transcripts.fa
	

#placing a preconfigured bracer.conf in ~/.bracerrc
RUN cp /bracer/docker_helper_files/docker_bracer.conf ~/.bracerrc


#this is a bracer container, so let's point it at a bracer wrapper that sets the silly IgBLAST environment variable thing
#ENTRYPOINT ["bash", "/bracer/docker_helper_files/docker_wrapper.sh"]

ENV IGDATA=/usr/local/share/igblast
RUN set -xe
ENTRYPOINT []
