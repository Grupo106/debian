Control de tráfico de red en GNU/Linux
==============================================================================
Se utiliza el comando *tc* (disponible con el paquete *iproute2*). Este comando
brinda una interfaz para la configuración de parámetros de control de tráfico
en el kernel de GNU/Linux en sus versiones > 2.4. Las reglas de *tc* se aplican
a trafico saliente.

Se utilizará el algormito HTB (hierarchical token bucket) para el manejo de
colas

```
Árbol HTB
                    root 1:
                      |
                    _1:1_
                   /  |  \
                  /   |   \
                 /    |    \
               1:10  1:11  1:12
              /   \       /   \
           1:101  1:102 1:121  1:122

```


Términos y acrónimos
------------------------------------------------------------------------------
* HTB
* Cola (queue)
* Disciplina de cola (qdisc)
* Clase (class)
* Filtro (filter)
* mbit: Cantidad de bits transmitidos por segundo.
1 Mbit/s (bit por segundo) = 128 KB/s (bytes por segundo)


Configuración de colas
------------------------------------------------------------------------------
`tc qdisc add dev eth1 root handle 1: htb default 2`

### Parámetros
* __dev__: Interfaz a la que se aplica. Recordar que se aplica sobre *tráfico
saliente*
* __root__: Indica que es raíz del árbol HTB
* __handle__: Indica que será la raiz del árbol 1
* __htb__: Identificador de algoritmo de cola (siempre será htb)
* __default__: Clase que se aplicará para los paquetes que no coincidan con
ningun filtro (en este caso será la clase 1:2)


Configuración de clases
------------------------------------------------------------------------------
`tc class add dev eth1 parent 1: classid 1:2 htb rate 5mbit`

### Parámetros
* __dev__: Interfaz a la que se aplica. Recordar que se aplica sobre *tráfico
saliente*
* __parent__: Clase Padre en el arbol
* __classid__: Identificador de la clase
* __htb__: Identificador de algoritmo de cola (siempre será htb)
* __rate__: Velocidad maxima (Se puede agregar 5% más sobre la velocidad máxima
  para compensar los bytes de *overhead* que no corresponden a datos).


Configuración de filtros
------------------------------------------------------------------------------
Para la configuración de filtros existen 2 técnicas: se puede filtrar tráfico
con el mismo *tc* o se puede utilizar *iptables*. En este caso se utilizará
*iptables* para identificar tráfico y etiquetarlo para que lo vea el *tc*

### iptables

`iptables -A PREROUTING -t mangle -p all -j MARK --set-mark 10`

Se crea la regla en el IPtables para etiquetar el tráfico y agregarle una marca
que será un número entero. Se puede usar cualquier patrón válido para iptables
para seleccionar tráfico.

#### Parámetros
* __-A PREROUTING__ (obligatorio): Indica que se aplica a cuando llega el
  paquete
* __-t mangle__ (obligatorio): Indica que modifica paquetes
* __PATRON__: Indica los patrones de los paquetes. En este caso son todos los
  paquetes de todos los protocolos (para más información ver el manual de
  *iptables*)
* __-j MARK__ (obligatorio): Indica que se agrega una marca al paquete (que
  luego será reconocida por el filtro de *tc*)
* __--set-mark__ (obligatorio): Indica el contenido de la marca. Tiene que ser
 un número entero positivo.

### tc

`tc filter add dev eth0 parent 1: prio 0 protocol ip handle 10 fw flowid 1:10`

#### Parámetros
* __dev__: Interfaz a la que se aplica. Recordar que se aplica sobre *tráfico
saliente*
* __parent__: Clase Padre en el arbol
* __prio__: Prioridad de la regla (0 es mayor prioridad)
* __protocol__: Protocolo en la que se aplica
* __handle__: Número de marca que agrega el firewall
* __fw__: Indica que la marca la agrega el firewall
* __flowid__: Clase que manipulará el tráfico

Ejemplo
------------------------------------------------------------------------------
```sh
# Arquitectura
# ----------------------------------------------------------------------------
# Internet <-> eth0 <-> Kernel <-> eth1 <-> LAN
# ----------------------------------------------------------------------------

# Limpia reglas previas
/sbin/iptables -t mangle -F
/sbin/tc qdisc del dev eth0 root
/sbin/tc qdisc del dev eth1 root

# Velocidad de bajada (saliente a eth1)
/sbin/tc qdisc add dev eth1 root handle 1: htb default 2
/sbin/tc class add dev eth1 parent 1: classid 1:2 htb rate 20mbit
/sbin/tc class add dev eth1 parent 1:2 classid 1:10 htb rate 0.5mbit

# Velocidad de subida (saliente a eth0)
/sbin/tc qdisc add dev eth0 root handle 1: htb default 2
/sbin/tc class add dev eth0 parent 1: classid 1:2 htb rate 2mbit
/sbin/tc class add dev eth0 parent 1:2 classid 1:10 htb rate 1mbit

# Selecciona trafico para limitarlo
/sbin/iptables -A PREROUTING -t mangle -p all -j MARK --set-mark 10
/sbin/tc filter add dev eth0 parent 1: prio 0 protocol ip handle 10 fw flowid 1:10
/sbin/tc filter add dev eth1 parent 1: prio 0 protocol ip handle 10 fw flowid 1:10
```


Links de interés
------------------------------------------------------------------------------
* [Manual de ruteo avanzado con GNU/Linux](http://lartc.org/howto/lartc.qdisc.filters.html)
* [Manual HTB](http://luxik.cdi.cz/~devik/qos/htb/manual/userg.htm)
* [Manual filtros](http://lartc.org/howto/lartc.qdisc.filters.html)
* [Manual iptables](http://ipset.netfilter.org/iptables.man.html)
