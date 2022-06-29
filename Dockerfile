FROM debian:buster

SHELL ["/bin/bash", "-l", "-euxo", "pipefail", "-c"]

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    git \
    curl \
    jq \
    build-essential \
    bsdmainutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# RUN git clone https://github.com/algolia/instant-search-demo.git /app
COPY instant-search-demo /app

ENV NVM_DIR /usr/local/nvm

RUN mkdir -p "$NVM_DIR"; \
    curl -o- \
        "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | \
        bash \
    ; \
    source $NVM_DIR/nvm.sh; \
    cd /app; \
    nvm install; \
    nvm use; \
    npm install

EXPOSE 3000 3001

CMD cd /app; source $NVM_DIR/nvm.sh; npm start