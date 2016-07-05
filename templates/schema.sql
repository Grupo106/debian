CREATE TABLE IF NOT EXISTS paquetes (
    id serial PRIMARY KEY,
    hora_captura timestamp NOT NULL DEFAULT now(),
    ip_origen integer NOT NULL,
    puerto_origen integer NOT NULL,
    ip_destino integer NOT NULL,
    puerto_destino integer NOT NULL,
    bytes integer NOT NULL,
    direccion smallint NULL,
    protocolo smallint NOT NULL
);

CREATE INDEX hora_idx ON paquetes(hora_captura);
