FROM postgres

COPY init-user-db.sh /docker-entrypoint-initdb.d/init-user-db.sh

COPY /execute.sh /
COPY /OMOPCDM_GENERATE.sql /