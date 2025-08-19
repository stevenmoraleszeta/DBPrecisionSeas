-- =========================================
-- Base de datos
-- =========================================
CREATE DATABASE db_precision_seas;

-- =========================================
-- EMPRESA
-- =========================================
CREATE TABLE empresa (
    cod_empresa      VARCHAR(20) PRIMARY KEY,
    nombre_empresa   VARCHAR(200),
    direccion        TEXT,
    telefono         VARCHAR(50),
    email_factura    VARCHAR(150),
    cedula           VARCHAR(50),
    observaciones    TEXT
);

-- =========================================
-- CONTACTO (N:1 EMPRESA)
-- =========================================
CREATE TABLE contacto (
    id_contacto      SERIAL PRIMARY KEY,
    cod_empresa      VARCHAR(20),
    nombre_contacto  VARCHAR(150),
    telefono         VARCHAR(50),
    email            VARCHAR(150),
    puesto           VARCHAR(150),
    notas            TEXT,

    -- Foráneas
    CONSTRAINT fk_contacto_empresa
        FOREIGN KEY (cod_empresa)
        REFERENCES empresa(cod_empresa)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- =========================================
-- COTIZACION (cabezal)
-- =========================================
CREATE TABLE cotizacion (
    num_cotizacion   VARCHAR(30) PRIMARY KEY,
    cod_empresa      VARCHAR(20),
    id_contacto      INT,
    direccion        TEXT,
    telefono         VARCHAR(20),
    desc_servicio    TEXT,
    cantidad         INT DEFAULT 0,
    moneda           VARCHAR(10),
    validez_oferta   VARCHAR(100),
    tiempo_entrega   VARCHAR(100),
    forma_pago       VARCHAR(100),
    subtotal         NUMERIC(12,2) DEFAULT 0,
    descuento        NUMERIC(10,2) DEFAULT 0,
    iva              NUMERIC(10,2) DEFAULT 0,
    total            NUMERIC(12,2) DEFAULT 0,
    observa_cliente  TEXT,
    observa_interna  TEXT,

    -- Foráneas
    CONSTRAINT fk_cotizacion_empresa
        FOREIGN KEY (cod_empresa)
        REFERENCES empresa(cod_empresa)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_cotizacion_contacto
        FOREIGN KEY (id_contacto)
        REFERENCES contacto(id_contacto)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- =========================================
-- Catálogos: MATERIAL / IMPORTACION
-- =========================================
CREATE TABLE material (
    id_material  SERIAL PRIMARY KEY,
    descripcion  TEXT,
    cantidad     INT DEFAULT 0,
    unidad       VARCHAR(20)
);

CREATE TABLE importacion (
    id_importacion  SERIAL PRIMARY KEY,
    descripcion     TEXT,
    cantidad        INT DEFAULT 0,
    unidad          VARCHAR(20)
);

-- =========================================
-- PROCESO/MAQUINA
-- =========================================
CREATE TABLE proceso_maquina (
    id_proceso        SERIAL PRIMARY KEY,
    descripcion       VARCHAR(200) NOT NULL,
    tarifa_x_minuto   NUMERIC(10,2) DEFAULT 0
);

-- =========================================
-- Detalles (Many-to-Many)
-- =========================================

-- COTIZACION <-> MATERIAL
CREATE TABLE cotizacion_material (
    num_cotizacion  VARCHAR(30) NOT NULL,
    id_material     INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_mat PRIMARY KEY (num_cotizacion, id_material),

    -- Foráneas
    CONSTRAINT fk_cm_cotizacion
        FOREIGN KEY (num_cotizacion)
        REFERENCES cotizacion(num_cotizacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_cm_material
        FOREIGN KEY (id_material)
        REFERENCES material(id_material)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_cotizacion_material_material
    ON cotizacion_material (id_material);

-- COTIZACION <-> IMPORTACION
CREATE TABLE cotizacion_importacion (
    num_cotizacion  VARCHAR(30) NOT NULL,
    id_importacion  INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_imp PRIMARY KEY (num_cotizacion, id_importacion),

    -- Foráneas
    CONSTRAINT fk_ci_cotizacion
        FOREIGN KEY (num_cotizacion)
        REFERENCES cotizacion(num_cotizacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_ci_importacion
        FOREIGN KEY (id_importacion)
        REFERENCES importacion(id_importacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_cotizacion_importacion_importacion
    ON cotizacion_importacion (id_importacion);

-- COTIZACION <-> PROCESO/MAQUINA
CREATE TABLE cotizacion_proceso (
    num_cotizacion  VARCHAR(30) NOT NULL,
    id_proceso      INT NOT NULL,
    tiempo          INT DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_proceso PRIMARY KEY (num_cotizacion, id_proceso),

    -- Foráneas
    CONSTRAINT fk_cp_cotizacion
        FOREIGN KEY (num_cotizacion)
        REFERENCES cotizacion(num_cotizacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_cp_proceso
        FOREIGN KEY (id_proceso)
        REFERENCES proceso_maquina(id_proceso)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_cotizacion_proceso_proceso
    ON cotizacion_proceso (id_proceso);



