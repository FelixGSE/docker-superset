FROM python:3.6-buster

ENV DEBIAN_FRONTEND=noninteractive \
    SUPERSET_HOME='/usr/local/superset'

COPY requirements.txt requirements.txt

RUN apt-get update \
&&  apt-get upgrade -qqy \
&&  apt-get install -y --no-install-recommends \
                       build-essential \
                       libssl-dev \ 
                       libffi-dev \ 
                       libsasl2-dev \
                       libldap2-dev \
                       default-libmysqlclient-dev \
                       gunicorn \
                       wait-for-it \
&&  pip install --upgrade pip \
                          setuptools \
&&  pip install -r requirements.txt \
&&  mkdir -p ${SUPERSET_HOME}/config \
&&  rm -rf /root/.cache \
&&  apt-get remove -qqy --purge \
            build-essential \
&&  apt-get -qqy autoremove --purge

ENV PYTHONPATH=PATH=${PYTHONPATH}:${SUPERSET_HOME}/config

COPY entrypoint.sh entrypoint.sh
COPY ./config/superset_config.py $SUPERSET_HOME/config/superset_config.py

ENTRYPOINT ["./entrypoint.sh"]
CMD ["debug"]
