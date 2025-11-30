#!/bin/bash

echo "==== Atualizando o sistema ===="
apt update -y && apt upgrade -y


echo "Configurando interface de rede..."
IFACE=$(ip -o -4 addr show | awk '!/lo/ {print $2; exit}')


echo "==== Instalando DHCP ===="
apt install isc-dhcp-server -y

echo "$IFACE" > /etc/default/isc-dhcp-server

cat <<EOF > /etc/dhcp/dhcpd.conf
default-lease-time 43200;
max-lease-time 86400;

subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.100 192.168.10.199;
    option routers 192.168.10.10;
    option broadcast-address 192.168.10.255;
    option domain-name-servers 192.168.10.11;
}
EOF

systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

echo "==== Instalando DNS ===="
apt install bind9 -y

cat <<EOF > /etc/bind/db.empresa.local
\$TTL 86400
@   IN  SOA srv-main.empresa.local. admin.empresa.local. (
        1
        7200
        120
        2419200
        86400 )

@       IN  NS      srv-main
srv-main IN A       192.168.10.10
srv-web  IN A       192.168.10.10
srv-ftp  IN A       192.168.10.10
srv-nfs  IN A       192.168.10.10
EOF

cat <<EOF > /etc/bind/db.10.168.192
@ IN SOA srv-main.empresa.local. admin.empresa.local. (
        1
        7200
        120
        2419200
        86400 )

@       IN  NS      srv-main
10      IN PTR srv-main.empresa.local.
EOF

cat <<EOF > /etc/bind/named.conf.local
zone "empresa.local" {
    type master;
    file "/etc/bind/db.empresa.local";
};

zone "10.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.168.192";
};
EOF

systemctl restart bind9
systemctl enable bind9

echo "==== Instalando Webserver ===="
apt install apache2 -y

mkdir -p /var/www/interno
cat <<EOF > /var/www/interno/index.html
<h1>Servidor Web Interno - Funcionando</h1>
EOF

cat <<EOF > /etc/apache2/sites-available/interno.conf
<VirtualHost *:80>
    ServerName interno.empresa.local
    DocumentRoot /var/www/interno
</VirtualHost>
EOF

a2ensite interno.conf
a2dissite 000-default.conf
systemctl restart apache2

echo "==== Instalando FTP ===="
apt install vsftpd -y

cat <<EOF > /etc/vsftpd.conf
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
local_umask=022
EOF

mkdir -p /srv/ftp
useradd ftpuser -d /srv/ftp -s /bin/false
echo "ftpuser:123" | chpasswd

systemctl restart vsftpd


echo "==== Instalando NFS ===="
apt install nfs-kernel-server -y

mkdir -p /srv/compartilhado

cat <<EOF > /etc/exports
/srv/compartilhado 192.168.10.0/24(rw,sync,no_root_squash)
EOF

systemctl restart nfs-kernel-server

echo "==== PROVISIONAMENTO FINALIZADO ===="
