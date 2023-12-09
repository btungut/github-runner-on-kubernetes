FROM ubuntu:20.04

ARG RUNNER_VERSION="2.311.0"

ENV CONTAINER_USER="runneruser"
ENV CONTAINER_USER_HOME="/home/$CONTAINER_USER"
ENV TGZ_FILE_NAME="runner.tar.gz"
ENV DEBIAN_FRONTEND=noninteractive

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    netcat \
    gnupg \
    lsb-release \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get -y upgrade

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    apt-transport-https \
    software-properties-common

#install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && mv ./yq_linux_amd64 /usr/bin/yq \
    && chmod +x /usr/bin/yq

#install helm
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

#install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && mv ./kubectl /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

#install docker cli
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && apt-get install -y docker-ce-cli

RUN apt-get update && apt-get -y upgrade


### Create a non-root user to use
RUN groupadd --g "10000" "$CONTAINER_USER"
RUN useradd --create-home --no-log-init -u "10000" -g "10000" "$CONTAINER_USER"
RUN apt-get update \
    && apt-get install -y sudo \
    && echo "$CONTAINER_USER" ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$CONTAINER_USER \
    && chmod 0440 /etc/sudoers.d/$CONTAINER_USER
    
RUN chown -R ${CONTAINER_USER} ${CONTAINER_USER_HOME}
USER ${CONTAINER_USER}
WORKDIR ${CONTAINER_USER_HOME}

### Install the runner
RUN wget https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -O ${CONTAINER_USER_HOME}/${TGZ_FILE_NAME}
WORKDIR ${CONTAINER_USER_HOME}/runner
RUN tar xzf ${CONTAINER_USER_HOME}/${TGZ_FILE_NAME} -C .

COPY --chown=${CONTAINER_USER} --chmod=+x entrypoint.sh .
RUN chmod +x ./entrypoint.sh

COPY --chown=${CONTAINER_USER} --chmod=+x call-api-github.sh .
RUN chmod +x ./call-api-github.sh

CMD ["./entrypoint.sh"]