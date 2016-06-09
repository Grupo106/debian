Despliegue de ambiente de desarrollo
==============================================

0. Requisitos
----------------------------------------------

* vagrant
* ansible

### Para Windows
* VirtualBox

### Para Linux
Se puede usar VirtualBox o libvirt ([KVM](https://es.wikipedia.org/wiki/Kernel-based_Virtual_Machine))

Si se utiliza libvirt hay que instalar un [plugin](https://github.com/vagrant-libvirt/vagrant-libvirt) en el vagrant con el siguiente comando

```sh
vagrant plugin install vagrant-libvirt
```

1. Instalacion
----------------------------------------------

### Para Virtualbox
```sh
vagrant up --provider virtualbox
```

### Para libvirt (sólo linux)
```sh
vagrant up --provider libvirt
```
Esto descargará la imagen del sistema operativo y configurará el ambiente

2. Administración
----------------------------------
```sh
vagrant ssh
```

Para iniciar una conexión ssh cuando se haya creado el sistema
