#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y xfce4 xfce4-goodies \
                   tightvncserver wget unzip \
                   supervisor

if ! id vncuser &>/dev/null; then
  useradd -m -s /bin/bash vncuser
  echo "vncuser:vncpassword" | chpasswd
fi

su - vncuser <<'EOF'
# Inicializa configuração do VNC para criar ~/.vnc/passwd e arquivo inicial
mkdir -p ~/.vnc
echo "vncpassword" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Cria o xstartup para usar XFCE
cat > ~/.vnc/xstartup <<XUP
#!/bin/sh
xrdb $HOME/.Xresources
startxfce4 &
XUP
chmod +x ~/.vnc/xstartup
EOF

# Configurando Supervisor para gerenciar o serviço VNC
cat > /etc/supervisor/conf.d/vncserver.conf <<SUP
[program:vncserver]
command=/usr/bin/su - vncuser -c "/usr/bin/vncserver :1 -geometry 1280x800 -depth 24"
autostart=true
autorestart=true
user=root
SUP

NGROK_ZIP="ngrok-stable-linux-amd64.zip"
wget -q https://bin.equinox.io/c/4VmDzA7iaHb/${NGROK_ZIP} -O /tmp/${NGROK_ZIP}
unzip -q /tmp/${NGROK_ZIP} -d /usr/local/bin
chmod +x /usr/local/bin/ngrok

if [ -n "$NGROK_AUTH_TOKEN" ]; then
  /usr/local/bin/ngrok authtoken $NGROK_AUTH_TOKEN
fi

supervisord -c /etc/supervisor/supervisord.conf &

sleep 3

nohup /usr/local/bin/ngrok tcp 5901 &

echo "VNC + ngrok iniciado"
