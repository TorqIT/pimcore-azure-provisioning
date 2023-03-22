FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install cron curl vim mariadb-server -y && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

COPY snapshot.sh /backup/snapshot.sh
COPY crontab /backup/crontab
COPY entrypoint.sh /backup/entrypoint.sh
ADD https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem /backup/ca-cert.crt.pem

RUN chmod gu+x /backup/*.sh

WORKDIR /backup

ENTRYPOINT [ "bash", "/backup/entrypoint.sh" ]