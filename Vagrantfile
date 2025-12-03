Vagrant.configure("2") do |config|

  # Variáveis reutilizáveis
  SERVER_IP   = "192.168.56.1"
  NETWORK_INT = "dhcp_network"

  # =====================================================================
  # VM SERVER
  # =====================================================================
  config.vm.define "server" do |server|
    server.vm.box = "ubuntu/bionic64"
    server.vm.hostname = "dhcp-bind-server"

    server.vm.network "private_network",
      ip: SERVER_IP,
      virtualbox__intnet: NETWORK_INT

    server.vm.provider "virtualbox" do |vb|
      vb.name = "dhcp-bind-server"
    end

    # Provisionamento unificado
    server.vm.provision "shell", inline: <<-SHELL
      echo "[SERVER] Atualizando..."
      apt-get update -y

      echo "[SERVER] Instalando pacotes principais..."
      apt-get install -y isc-dhcp-server bind9 bind9utils bind9-doc \
                         nfs-kernel-server nginx vsftpd

      # ---------------------------------------------------------
      # DHCP
      # ---------------------------------------------------------
      echo "[SERVER] Configurando DHCP..."
      sed -i 's/INTERFACESv4=""/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

      cat <<EOF > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.56.0 netmask 255.255.255.0 {
  range 192.168.56.10 192.168.56.100;
  option routers 192.168.56.1;
  option domain-name-servers 192.168.56.1;
}
EOF

      systemctl restart isc-dhcp-server
      systemctl enable isc-dhcp-server

      # ---------------------------------------------------------
      # BIND9 DNS
      # ---------------------------------------------------------
      echo "[SERVER] Configurando BIND9..."
      cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak

      cat <<EOF > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    listen-on { any; };
    allow-query { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation auto;
    auth-nxdomain no;
};
EOF

      cat <<EOF > /etc/bind/named.conf.local
zone "example.local" {
    type master;
    file "/etc/bind/db.example.local";
};
EOF

      cat <<EOF > /etc/bind/db.example.local
$TTL 604800
@       IN      SOA     example.local. root.example.local. (
                          2
                          604800
                          86400
                          2419200
                          604800 )
@       IN      NS      ns1.example.local.
@       IN      A       192.168.56.1
ns1     IN      A       192.168.56.1
www     IN      CNAME   example.local.
@       IN      MX      10 mail.example.local.
mail    IN      A       192.168.56.2
EOF

      named-checkconf
      named-checkzone example.local /etc/bind/db.example.local

      systemctl restart bind9
      systemctl enable bind9

      # ---------------------------------------------------------
      # NFS
      # ---------------------------------------------------------
      echo "[SERVER] Configurando NFS..."
      mkdir -p /srv/nfs_share
      chmod 777 /srv/nfs_share

      echo "/srv/nfs_share 192.168.56.0/24(rw,sync,no_subtree_check)" >> /etc/exports

      exportfs -ra
      systemctl restart nfs-kernel-server
      systemctl enable nfs-kernel-server

      # ---------------------------------------------------------
      # NGINX
      # ---------------------------------------------------------
      echo "[SERVER] Configurando Nginx..."

      rm -f /etc/nginx/sites-enabled/default
      mkdir -p /var/www/html/site

      cat <<EOF > /var/www/html/site/index.html
<h1>Bem-vindo ao Site Estático!</h1>
<p>Servido pelo Nginx.</p>
EOF

      cat <<EOF > /etc/nginx/sites-available/site
server {
    listen 80 default_server;
    root /var/www/html/site;
    index index.html;
}
EOF

      ln -s /etc/nginx/sites-available/site /etc/nginx/sites-enabled/
      nginx -t

      systemctl restart nginx
      systemctl enable nginx

      # ---------------------------------------------------------
      # FTP (vsftpd)
      # ---------------------------------------------------------
      echo "[SERVER] Configurando FTP..."

      cat <<EOF > /etc/vsftpd.conf
listen=YES
anonymous_enable=YES
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
local_umask=022
pasv_min_port=40000
pasv_max_port=50000
pasv_address=192.168.56.1
EOF

      mkdir -p /srv/ftp_share
      chmod 777 /srv/ftp_share
      echo "Bem-vindo ao servidor FTP!" > /srv/ftp_share/README.txt

      systemctl restart vsftpd
      systemctl enable vsftpd

      echo "[SERVER] Finalizado!"
    SHELL
  end

  # =====================================================================
  # VM CLIENT
  # =====================================================================
  config.vm.define "client" do |client|
    client.vm.box = "ubuntu/bionic64"
    client.vm.hostname = "dhcp-bind-client"

    client.vm.network "private_network",
      type: "dhcp",
      virtualbox__intnet: NETWORK_INT

    client.vm.provider "virtualbox" do |vb|
      vb.name = "dhcp-bind-client"
    end

    client.vm.provision "shell", inline: <<-SHELL
      echo "[CLIENT] Atualizando..."
      apt-get update -y

      echo "[CLIENT] Instalando utilitários..."
      apt-get install -y dnsutils curl nfs-common ftp

      # ---------------------------------------------------------
      # NFS
      # ---------------------------------------------------------
      echo "[CLIENT] Montando NFS..."
      mkdir -p /mnt/nfs_share
      mount 192.168.56.1:/srv/nfs_share /mnt/nfs_share

      echo "192.168.56.1:/srv/nfs_share /mnt/nfs_share nfs defaults 0 0" >> /etc/fstab

      # ---------------------------------------------------------
      # Testes
      # ---------------------------------------------------------
      echo "[CLIENT] Testando site Nginx..."
      curl -s http://192.168.56.1

      echo "[CLIENT] Testando FTP..."
      ftp -inv 192.168.56.1 <<EOF
user anonymous
ls
bye
EOF

      echo "[CLIENT] Finalizado!"
    SHELL
  end

end
