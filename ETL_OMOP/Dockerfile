FROM postgres

RUN mkdir ./csv ;\ 
    mkdir ./vocabulary_v5

COPY /output/csv ./csv/
COPY /output/vocabulary_v5 ./vocabulary_v5/
COPY /vocab ./
COPY /output/OMOPCDM_GENERATE.sql ./
