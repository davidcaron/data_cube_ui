FROM opendatacube/datacube-core

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /datacube/ui_results
RUN chmod 777 /datacube/ui_results

RUN apt-get update && apt-get install -y \
    gosu \
    libfreeimage3 \
    imagemagick \
    mailutils \
    && rm -rf /var/lib/apt/lists/*

ARG DATACUBE_USER=localuser
ENV DATACUBE_USER=$DATACUBE_USER
RUN adduser --disabled-password --gecos '' $DATACUBE_USER

ENV DATACUBE_CONFIG_PATH /home/$DATACUBE_USER/Datacube/data_cube_ui/config/.datacube.conf

WORKDIR /home/$DATACUBE_USER/Datacube/data_cube_ui

# todo: configure myhostname
# http://www.postfix.org/BASIC_CONFIGURATION_README.html
RUN sed -i 's/inet_interfaces.*/inet_interfaces = localhost/' /etc/postfix/main.cf && \
    sed -i 's/inet_protocols.*/inet_protocols = ipv4/' /etc/postfix/main.cf

COPY requirements.txt .

RUN pip3 install --upgrade pip && \
    pip3 install --no-cache -r requirements.txt && \
    pip3 install --no-cache gunicorn && \
    rm -rf $HOME/.cache/pip

COPY . .

RUN chown -R $DATACUBE_USER:$DATACUBE_USER .

RUN mv docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

CMD gunicorn --bind 0.0.0.0:8000 --workers 4 data_cube_ui.wsgi:application