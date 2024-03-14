FROM centos

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# install python
RUN yum install -y python39 python39-pip

# install snowsql
COPY /conf/snowflake-snowsql-1.2.31-1.x86_64.rpm /opt/
RUN rpm -i /opt/snowflake-snowsql-1.2.31-1.x86_64.rpm ;\
    rm /opt/snowflake-snowsql-1.2.31-1.x86_64.rpm

# set workdir to project path
WORKDIR /home/aou-ehr-file-check/

# aou-ehr-file-chech
COPY /aou-ehr-file-check/ ./
RUN mv ./_settings.py ./settings.py
RUN python3.9 -m pip install -U pip ;\
    pip install -r ./requirements.txt

# RUN sed -i "s|csv_dir = .*|csv_dir = './tests/resources/examples_erroneous' |g" ./settings.py
RUN sed -i "s|csv_dir = .*|csv_dir = '/home/data' |g" ./settings.py

# copy scripts
COPY /scripts/ /opt/scripts/
COPY /conf/snowsql.cnf /etc/

RUN chmod -R 755 ./
RUN chmod -R 755 /opt/scripts/


CMD [ "/opt/scripts/aou-dq"]
