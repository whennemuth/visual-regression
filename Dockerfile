FROM backstopjs/backstopjs:latest

RUN echo "deb http://deb.debian.org/debian stretch main contrib" >> /etc/apt/sources.list && \
    apt update && \
    apt install -y vim jq

WORKDIR /app
COPY init.sh scenario.sh ./

WORKDIR /src
ENTRYPOINT [ "/bin/bash", "/app/init.sh" ]

