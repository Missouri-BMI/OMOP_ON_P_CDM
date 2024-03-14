FROM python:3.9

ARG USER_UID=1000
ARG USERNAME=appUser
ARG USERGROUP=appGroup
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERGROUP \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

USER $USERNAME

COPY --chown=$USERNAME:$USERGROUP /aou-ehr-file-check/ /home/$USERNAME/aou-ehr-file-check/

# SET Home directory
WORKDIR /home/$USERNAME/aou-ehr-file-check/

COPY --chown=$USERNAME:$USERGROUP /csv/ ./data/

RUN chmod -R 755 ./

RUN mv ./_settings.py ./settings.py

RUN python -m pip install -U pip ;\
    pip install -r ./requirements.txt

# RUN sed -i "s|csv_dir = .*|csv_dir = './tests/resources/examples_erroneous' |g" ./settings.py

RUN sed -i "s|csv_dir = .*|csv_dir = './data' |g" ./settings.py

CMD [ "python", "./omop_file_validator.py"]