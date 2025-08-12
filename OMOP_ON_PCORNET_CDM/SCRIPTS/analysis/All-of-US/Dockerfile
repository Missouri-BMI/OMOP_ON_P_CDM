FROM amazonlinux:2

# install python
RUN amazon-linux-extras enable python3.8 \
    && yum install -y python3.8 python3-pip gcc python3-devel \
    && ln -sf /usr/bin/python3.8 /usr/bin/python3 \
    && ln -sf /usr/bin/pip3 /usr/bin/pip


# aou-ehr-file-check
COPY aou-ehr-file-check/ /home/aou-ehr-file-check/


WORKDIR /home/aou-ehr-file-check/

RUN python3.8 -m pip install --upgrade pip && \
    python3.8 -m pip install -r ./requirements.txt

CMD ["python3.8", "./omop_file_validator.py"]