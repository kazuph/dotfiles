FROM centos

RUN yum install -y sudo git vim zsh

WORKDIR /root
RUN git clone --recursive https://kazuph@github.com/kazuph/dotfiles.git
WORKDIR /root/dotfiles
RUN git submodule foreach 'git fetch;git checkout origin/master'
RUN cp /root/dotfiles/_zshrc /root/.zshrc
WORKDIR /root
ENTRYPOINT ["/bin/zsh"]
