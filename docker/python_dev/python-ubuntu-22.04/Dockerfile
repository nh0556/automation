FROM ubuntu:22.04 

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# install the basic packages
RUN apt-get update; \
    apt-get install -y --no-install-recommends \
    ssh \
    ssh-agent-filter \
    ca-certificates \
    python3 \
    python3-pip \
    sudo \
    wget \
    vim \
    openssl \
    inetutils-ping \
    git \
    python3-apt \
    tmux \
    psmisc \
    curl \
    netcat

# The psmisc package installs the following programs
# fuser – identifies what processes are using files.
# killall – kills a process by its name, similar to a pkill Unices.
# pstree – Shows currently running processes in a tree format.
# peekfd – Peek at file descriptors of running processes.

RUN pip3 install setuptools
RUN pip3 install wheel
RUN pip3 install flask
RUN pip3 install flask-restful
RUN pip3 install redis
RUN pip3 install pika==1.3.1
RUN pip3 install Celery==5.2.7

# download argocd-vault-plugin
WORKDIR "/usr/local/bin"
RUN wget -O argocd-vault-plugin https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v1.14.0/argocd-vault-plugin_1.14.0_linux_amd64
RUN chmod +x argocd-vault-plugin

WORKDIR "/root"
RUN wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
RUN tar xvf helm-v3.12.0-linux-amd64.tar.gz
WORKDIR "/root/linux-amd64"
RUN cp ./helm /usr/local/bin
WORKDIR "/root"
RUN rm -Rf linux-amd64
RUN rm helm-v3.12.0-linux-amd64.tar.gz

# dns settings
#RUN sed 's/8.8.8.8/17.8.8.8/' /etc/resolv.conf
#RUN sed 's/8.8.4.4/17.7.7.7/' /etc/resolv.conf

# configure root user directory
RUN mkdir -p /root/.ssh

# configure cert dir
RUN mkdir -p /usr/local/share/ca-certificates

# configure vim
COPY .vimrc /root/.vimrc

# back to root directory
WORKDIR /root
