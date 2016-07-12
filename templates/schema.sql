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
