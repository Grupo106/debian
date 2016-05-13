Instalación de ambiente
=======================
0. Requisitos
------------------
* Debian 8
* ansible

1. Instalacion Debian
------------------------------------
1. Seguir asistente de instación de Debian-8, crear usuario morfeo
y reiniciar el equipo.
1. Una vez que se reinició el equipo, ingresar como root y ejecutar los
siguientes comandos:

```sh
apt-get update
apt-get install python
```

2. Copiar tus llaves ssh (esto se hace en la máquina real)
-------------------------------------------------
* Donde dice *debian* reemplazar por la IP de la máquina, caso
contrario agregar el nombre *debian* al archivo `/etc/hosts` de tu
PC (requiere privilegios de root)

```sh
ssh-copy-id morfeo@debian
```

**ATENCION** No olvides copiar tu clave ssh pública en el archivo
`templates/ssh/authorized_keys`, sino vas a perder la administración. Yo te
avisé

```sh
cat ~/.ssh/id_rsa.pub >> templates/ssh/authorized_keys
```

3. Ejecutar ansible
------------------------------------
```sh
ansible-playbook -i hosts site.yml
```


TODO
-----------
* Hacer Vagrant
