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
ALTER TABLE paquetes OWNER TO netcop;

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
    tipo smallint not null default 1
);
ALTER TABLE clase_trafico OWNER TO netcop;

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
    direccion cidr not null,
    prefijo smallint not null default 32 -- mascara subred de host --
);
ALTER TABLE cidr OWNER TO netcop;

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
ALTER TABLE puerto OWNER TO netcop;

-- tabla clase_cidr
-- ---------------------------------------------------------------
--  Relacion muchos a muchos entre clase de trafico y puerto
--
--  ### Grupos
--   * 'o': Outside, En Internet
--   * 'i': Inside, En la red local
CREATE TABLE IF NOT EXISTS clase_cidr (
    id_clase integer not null REFERENCES clase_trafico ON DELETE CASCADE,
    id_cidr integer not null REFERENCES cidr ON DELETE CASCADE,
    grupo char not null default 'o',
    PRIMARY KEY (id_clase, id_cidr)
);
ALTER TABLE clase_cidr OWNER TO netcop;

-- tabla clase_puerto
-- ---------------------------------------------------------------
--  Relacion muchos a muchos entre clase de trafico y puerto
--
--  ### Grupos
--   * 'o': Outside, En Internet
--   * 'i': Inside, En la red local
CREATE TABLE IF NOT EXISTS clase_puerto (
    id_clase integer not null REFERENCES clase_trafico ON DELETE CASCADE,
    id_puerto integer not null REFERENCES puerto ON DELETE CASCADE,
    grupo char not null default 'o',
    PRIMARY KEY (id_clase, id_puerto)
);
ALTER TABLE clase_puerto OWNER TO netcop;

-- tabla politica
-- ---------------------------------------------------------------------------
--  Define reglas de trafico creadas por el usuario
CREATE TABLE IF NOT EXISTS politica (
    id_politica serial PRIMARY KEY,
    nombre varchar(63) NOT NULL,
    descripcion varchar(255) NULL,
    activa boolean NOT NULL DEFAULT 'TRUE',
    prioridad smallint NULL,
    velocidad_bajada integer NULL, -- en kbit/s
    velocidad_subida integer NULL, -- en kbit/s
    fc_creacion timestamp without time zone NULL
);
-- modoficaciones a la tabla politica
ALTER TABLE politica RENAME COLUMN velocidad_maxima TO velocidad_bajada;
ALTER TABLE politica ADD COLUMN velocidad_subida integer NULL;
ALTER TABLE politica ADD COLUMN fc_creacion timestamp without time zone NULL;
ALTER TABLE politica OWNER TO netcop;

-- tabla objetivo
-- ---------------------------------------------------------------------------
--  Especifica los objetivos a los que se les va a aplicar la politica.
--
--  ### Tipos
--    * 'd': Destino
--    * 'o': Origen
CREATE TABLE IF NOT EXISTS objetivo (
    id_objetivo serial PRIMARY KEY,
    id_politica integer NOT NULL REFERENCES politica ON DELETE CASCADE,
    id_clase integer NULL REFERENCES clase_trafico ON DELETE CASCADE,
    tipo char(1) NOT NULL DEFAULT 'd',
    direccion_fisica macaddr NULL
);
ALTER TABLE objetivo OWNER TO netcop;

-- tabla rango_horario
-- ---------------------------------------------------------------------------
--  Especifica los rangos horarios en los que la politica esta activa
--
--  ### Columnas
--   * dia: Dia de la semana, entre 0 y 6 siendo 0 el dia domingo
--   * hora_inicial: Hora de inicio del rango valido 
--   * hora_fin: Hora de fin del rango valido 
CREATE TABLE IF NOT EXISTS rango_horario (
    id_rango_horario serial PRIMARY KEY,
    id_politica integer NOT NULL REFERENCES politica ON DELETE CASCADE,
    dia smallint NOT NULL,
    hora_inicial time NOT NULL,
    hora_fin time NOT NULL
);
ALTER TABLE rango_horario OWNER TO netcop;

-- tabla usuario
-- ---------------------------------------------------------------------------
--  almacena a los usuarios del sistema

CREATE TABLE IF NOT EXISTS usuarios
(
  id_usu serial NOT NULL,
  usuario character varying(16) NOT NULL,
  password character varying(64) NOT NULL,
  nombre character varying(16),
  apellido character varying,
  mail character varying(32),
  rol character varying(16),
  CONSTRAINT id PRIMARY KEY (id_usu)
);
ALTER TABLE usuarios OWNER TO netcop;
ALTER TABLE usuarios ALTER COLUMN password SET DATA TYPE character varying(64);

-- tabla log
-- ---------------------------------------------------------------------------
--  almacena a los usuarios del sistema

CREATE TABLE IF NOT EXISTS logs
(
  id_log serial PRIMARY KEY,
  usuario character varying(16),
  descripcion character varying(255),
  hora_log timestamp NOT NULL DEFAULT now()  
);
ALTER TABLE logs OWNER TO netcop;

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

-- vista v_politica_clase_oyd
-- ---------------------------------------------------------------
-- Chequear si es clase origen y destino
CREATE OR REPLACE VIEW v_politica_clase_oyd AS 
 SELECT a.id_politica
   FROM objetivo a
     JOIN objetivo b ON a.id_politica = b.id_politica AND a.id_clase = b.id_clase AND a.id_objetivo <> b.id_objetivo AND a.tipo <> b.tipo AND a.direccion_fisica IS NULL AND b.direccion_fisica IS NULL AND NOT (a.id_politica IN ( SELECT objetivo.id_politica
           FROM objetivo
          GROUP BY objetivo.id_politica
         HAVING count(objetivo.id_politica) <> 2))
  GROUP BY a.id_politica
 HAVING count(1) = 2;

ALTER TABLE v_politica_clase_oyd
  OWNER TO netcop;
GRANT ALL ON TABLE v_politica_clase_oyd TO netcop;

-- Limpieza
-- ---------------------------------------------------------------------------
--  Limpia clases de trafico de sistema mal creadas con id menores a mil
--  millones
DELETE FROM clase_trafico where id_clase < 1000000000 and tipo = 0;
