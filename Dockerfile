# Dockerfile
FROM ubuntu:latest

# Prevent apt from prompting for user input
ENV DEBIAN_FRONTEND=noninteractive

# Install basic utilities (customize this list as needed)
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    git \
    vim 

# Create workspace directory
WORKDIR /opt/workspace

RUN apt-get install -y libdbus-1-3

RUN apt-get install -y \
    xfce4 \
    xfce4-terminal \
    xvfb \
    x11vnc \
    novnc \
    supervisor \
    net-tools \
    dbus-x11 \
    openssh-server

RUN apt-get remove -y xfce4-screensaver \
    && apt-get autoremove -y 

# Set up VNC password
RUN mkdir -p /root/.vnc && \
    x11vnc -storepasswd password /root/.vnc/passwd

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Disable screensaver in XFCE4 settings
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<channel name="xfce4-screensaver" version="1.0">\n\
  <property name="enabled" type="bool" value="false"/>\n\
</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml

# Download and install Google Chrome
RUN curl -Lo google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb

# Configure supervisord
RUN mkdir -p /root/.config/goose
RUN curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash


RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    apt-get install -y python3-pip python3.12-dev ripgrep

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv $HOME/.local/bin/uv /usr/local/bin/uv

RUN \. "$HOME/.nvm/nvm.sh" && nvm install 22

COPY agent.yaml /root/.config/goose/config.yaml
COPY .hints /root/.config/goose/.goosehints
COPY bashrc /root/.bashrc
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports for noVNC and SSH
EXPOSE 6080 22

CMD ["/usr/bin/supervisord"]
