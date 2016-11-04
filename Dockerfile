FROM alpine:3.4

# Add the testing repo to get neovim
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install all the needed packages
RUN apk add --no-cache \
			# My Stuff
      bash \
      unibilium \
      php5 \
      php5-json \
      php5-phar \
      php5-openssl \
      curl \
      git \
      ack \
      python3 \
      python3-dev \
      nodejs \
      neovim \
      # Needed for python pip installs
      musl-dev \ 
      gcc \
      # Needed for infocmp and tic
      ncurses

# Configure Git
RUN git config --global user.email "codyfh@gmail.com"
RUN git config --global user.name "Cody Hiar"

# Download composer and move it to new location
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Update the path to include composer bins
ENV PATH "$PATH:/root/.composer/vendor/bin"

# Composer install Code Sniff
RUN composer global require "squizlabs/php_codesniffer=*"

# Install Symfony 2 coding standard
RUN composer global require --dev escapestudios/symfony2-coding-standard:~2.0

# Add Symfony 2 coding standard to the phpcs paths
RUN phpcs --config-set installed_paths /root/.composer/vendor/escapestudios/symfony2-coding-standard

# Install custom linting
ADD PEARish.xml /root/PEARish.xml

# Install python linting and neovim plugin
RUN pip3 install neovim jedi flake8 flake8-docstrings flake8-import-order flake8-quotes pep8 pep8-naming pep257

# Install nodejs linting
# Install JS linting modules
# The reason for the version specifications is an 'Unmet peerDependancy error'
# https://github.com/airbnb/javascript/issues/952
# Commented out because I can't make it work right now
# RUN npm install -g eslint@\^2.10.2 eslint-config-airbnb eslint-plugin-import eslint-plugin-react eslint-plugin-jsx-a11y@\^1.2.2

# Install the eslintrc.json
ADD eslintrc.json /root/.eslintrc.json

# Copy over the shellcheck binaries
COPY package/bin/shellcheck /usr/local/bin/
COPY package/lib/           /usr/local/lib/
RUN ldconfig /usr/local/lib

# Download my Neovim Repo
RUN git clone https://github.com/thornycrackers/.nvim.git /root/.config/nvim

# Install neovim Modules
RUN nvim +PlugInstall +qall
RUN nvim +UpdateRemotePlugins +qall

# Add some aliases
ADD bashrc /root/.bashrc

WORKDIR /app

# Better terminal support
ENV TERM xterm-256color

# Neovim needs this so that <ctrl-h> can work
RUN infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > /tmp/$TERM.ti
RUN tic /tmp/$TERM.ti

# Command for the image
CMD ["/bin/zsh"]
