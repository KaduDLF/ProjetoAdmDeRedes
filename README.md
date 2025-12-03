# ProjetoAdmDeRedes
Esse projeto é um trabalho em grupo da matéria de Administração de redes

# README

**Administração de Redes de Computadores**

-   **Instituição:** IF Goiano -- Campus Ceres\
-   **Curso:** Bacharelado em Sistemas de Informação\
-   **Disciplina:** Administração de Redes de Computadores\
-   **Alunos:** **David Corrêa Duarte**, **Carlos Eduardo de Oliveira
    Silva**\
-   **Professor:** Roitier

## Objetivo do Projeto

Este trabalho consiste na criação de duas máquinas virtuais utilizando
**Vagrant**, configurando e testando: **DHCP, DNS, FTP, NFS e Nginx**.

O ambiente contém: - **Servidor:** DHCP, DNS, FTP, NFS, Nginx\
- **Cliente:** recebe IP via DHCP e testa os serviços

## Preparação do Ambiente

### Requisitos

-   Vagrant\
-   VirtualBox

### Subir as VMs

``` bash
vagrant up
```

### Acessar o cliente

``` bash
vagrant ssh client
```

## Testes

### 1. DHCP

``` bash
ip addr show
```

### 2. DNS

``` bash
dig example.local
```

### 3. FTP

``` bash
ftp 192.168.56.1
```

### 4. NFS

``` bash
sudo mount 192.168.56.1:/srv/nfs_share /mnt
```

### 5. Nginx

``` bash
curl http://192.168.56.1
```

## Conclusão

Todos os serviços (DHCP, DNS, FTP, NFS, Nginx) foram configurados no
servidor e testados pelo cliente com sucesso.

