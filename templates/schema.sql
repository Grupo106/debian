-- Netcop 2016
-- Esquema de la base de datos del sistema
-- @author Yonatan Romero


-- Tablas
-- ========================================================================

-- tabla paquetes
-- ---------------------------------------------------------------
--  Almacena paquetes capturados por el adquisidor
CREATE TABLE IF NOT EXISTS paquetes (
    id serial PRIMARY KEY,
    hora_captura timestamp NOT NULL DEFAULT now(),
    ip_origen integer NOT NULL,
    puerto_origen integer NOT NULL,
    ip_destino integer NOT NULL,
    puerto_destino integer NOT NULL,
    bytes integer NOT NULL,
    direccion smallint NOT NULL DEFAULT 0,
    protocolo smallint NOT NULL DEFAULT 0
);

CREATE INDEX hora_idx ON paquetes(hora_captura);

-- tabla clase de trafico
-- ---------------------------------------------------------------
--  Almacena descripcion de la clases de traficos. Las clases pueden ser de
--  dos tipos:
--
--    0. Tipo 0: Clases del sistema
--    1. Tipo 1: Clases personalizadas por el usuario
--
--  Es importante esta clasificacion para el actualizador de clases de trafico,
--  ya que solo trabajara con las clases de trafico de sistema.
CREATE TABLE IF NOT EXISTS clase_trafico (
    id_clase serial PRIMARY KEY,
    nombre varchar(32) not null,
    descripcion varchar(160) not null,
    tipo smallint not null default 0
);

ALTER TABLE IF EXISTS clase_trafico 
ADD COLUMN activa boolean DEFAULT TRUE NOT NULL;

-- tabla cidr
-- ---------------------------------------------------------------
--  Almacena las redes que componen las clases de trafico.
--
--  Se compoenen de una  direccion de red y un prefijo que indica la cantidad
--  de bits en uno que tiene la mascara de subred. Si el prefijo es 32,
--  entonces la direccion pertenece a un host.
CREATE TABLE IF NOT EXISTS cidr (
    id_cidr serial PRIMARY KEY,
    direccion varchar(16) not null,
    prefijo smallint not null default 32 -- mascara subred de host --
);

-- tabla puerto
-- ---------------------------------------------------------------
--  Almacenan los puertos que componen las clases de trafico.
--
--  Se componen del numero de puerto y el protocolo (por defecto el protocolo
--  es TCP). Si el valor es cero entonces asume que es para todos los
--  protocolos
CREATE TABLE IF NOT EXISTS puerto (
    id_puerto serial PRIMARY KEY,
    numero integer not null,
    protocolo smallint not null default 0
);

-- tabla clase_cidr
-- ---------------------------------------------------------------
--  Relacion muchos a muchos entre clase de trafico y puerto
--
--  Se define el grupo al que pertenece la relacion. Por defecto existen dos
--  grupos, el 'o' y el 'i'. El grupo 'o' se utiliza para los hosts que esten
--  en la Internet (outside) y el grupo 'i' para hosts que se encuentren en la
--  red interna (inside).
CREATE TABLE IF NOT EXISTS clase_cidr (
    id_clase integer not null REFERENCES clase_trafico ON DELETE CASCADE,
    id_cidr integer not null REFERENCES cidr ON DELETE CASCADE,
    grupo char not null default 'o',
    PRIMARY KEY (id_clase, id_cidr, grupo)
);

-- tabla clase_puerto
-- ---------------------------------------------------------------
--  Relacion muchos a muchos entre clase de trafico y puerto
--
--  Se define el grupo al que pertenece la relacion. Por defecto existen dos
--  grupos, el 'o' y el 'i'. El grupo 'o' se utiliza para los hosts que esten
--  en la Internet (outside) y el grupo 'i' para hosts que se encuentren en la
--  red interna (inside).
CREATE TABLE IF NOT EXISTS clase_puerto (
    id_clase integer not null REFERENCES clase_trafico ON DELETE CASCADE,
    id_puerto integer not null REFERENCES puerto ON DELETE CASCADE,
    grupo char not null default 'o',
    PRIMARY KEY (id_clase, id_puerto, grupo)
);

-- Vistas
-- ========================================================================

-- vista v_clase_cidr
-- ---------------------------------------------------------------
-- Sirve para simplificar las consultas en el analizador
CREATE OR REPLACE VIEW v_clase_cidr AS
SELECT j.id_clase, c.direccion, c.prefijo, j.grupo
FROM cidr c INNER JOIN clase_cidr j USING (id_cidr);

-- vista v_clase_puerto
-- ---------------------------------------------------------------
-- Sirve para simplificar las consultas en el analizador
CREATE OR REPLACE VIEW v_clase_puerto AS
SELECT j.id_clase, p.numero, p.protocolo, j.grupo
FROM puerto p INNER JOIN clase_puerto j USING (id_puerto);
