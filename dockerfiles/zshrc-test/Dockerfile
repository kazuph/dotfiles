FROM centos

RUN yum install -y sudo git vim zsh

WORKDIR /root
RUN git clone https://kazuph@github.com/kazuph/dotfiles.git
WORKDIR /root/dotfiles
RUN ./updatupdate_submodules.sh
RUN cp /root/dotfiles/.zshrc /root/.zshrc
WORKDIR /root
ENTRYPOINT ["/bin/zsh"]
