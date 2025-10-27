CREATE DATABASE db_precision_seas;

-- =========================================
-- EMPRESA
-- =========================================
CREATE TABLE empresa (
    id_empresa       SERIAL PRIMARY KEY,
    cod_empresa      VARCHAR(20) UNIQUE NOT NULL,
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
    id_empresa       INT,
    nombre_contacto  VARCHAR(150),
    telefono         VARCHAR(50),
    email            VARCHAR(150),
    puesto           VARCHAR(150),
    notas            TEXT,

    CONSTRAINT fk_contacto_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_contacto_id_empresa ON contacto (id_empresa);

-- =========================================
-- COTIZACION (cabezal)
-- =========================================
CREATE TABLE cotizacion (
    id_cotizacion    SERIAL PRIMARY KEY,
    num_cotizacion   VARCHAR(30) UNIQUE NOT NULL,
    -- Usar id_empresa como FK (nullable por el ON DELETE SET NULL)
    id_empresa       INT,
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

    CONSTRAINT fk_cotizacion_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_cotizacion_contacto
        FOREIGN KEY (id_contacto)
        REFERENCES contacto(id_contacto)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_cotizacion_id_empresa ON cotizacion (id_empresa);
CREATE INDEX idx_cotizacion_id_contacto ON cotizacion (id_contacto);

-- =========================================
-- OT (Orden de Trabajo) - NUEVA SECCIÓN
-- =========================================
CREATE TABLE ot (
    id_ot            SERIAL PRIMARY KEY,
    num_ot           VARCHAR(30) UNIQUE NOT NULL,
    id_cotizacion    INT,
    po               VARCHAR(100),
    id_empresa       INT,
    id_contacto      INT,
    descripcion      TEXT,
    cantidad         INT DEFAULT 0,
    estado           VARCHAR(50) DEFAULT 'Pendiente',
    fecha_inicio     DATE,
    fecha_fin        DATE,
    prioridad        VARCHAR(20) DEFAULT 'Normal',
    observaciones    TEXT,

    CONSTRAINT fk_ot_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizacion(id_cotizacion)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_ot_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_ot_contacto
        FOREIGN KEY (id_contacto)
        REFERENCES contacto(id_contacto)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_ot_id_cotizacion ON ot (id_cotizacion);
CREATE INDEX idx_ot_id_empresa ON ot (id_empresa);
CREATE INDEX idx_ot_id_contacto ON ot (id_contacto);


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
-- Detalles (Many-to-Many) - COTIZACIONES
-- =========================================

-- COTIZACION <-> MATERIAL
-- ✅ ESTRUCTURA CORREGIDA: Campo 'id' único para operaciones CRUD
-- ✅ Permite duplicados: el mismo material puede aparecer múltiples veces en la misma cotización
CREATE TABLE cotizacion_material (
    id SERIAL PRIMARY KEY,  -- ✅ Campo ID único para APIs REST
    id_cotizacion   INT NOT NULL,
    id_material     INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_cm_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizacion(id_cotizacion)
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
-- ✅ ESTRUCTURA CORREGIDA: Campo 'id' único para operaciones CRUD
-- ✅ Permite duplicados: la misma importación puede aparecer múltiples veces en la misma cotización
CREATE TABLE cotizacion_importacion (
    id SERIAL PRIMARY KEY,  -- ✅ Campo ID único para APIs REST
    id_cotizacion   INT NOT NULL,
    id_importacion  INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_ci_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizacion(id_cotizacion)
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
-- ✅ ESTRUCTURA CORREGIDA: Campo 'id' único para operaciones CRUD
-- ✅ Permite duplicados: el mismo proceso puede aparecer múltiples veces en la misma cotización
CREATE TABLE cotizacion_proceso (
    id SERIAL PRIMARY KEY,  -- ✅ Campo ID único para APIs REST
    id_cotizacion   INT NOT NULL,
    id_proceso      INT NOT NULL,
    tiempo          INT DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_cp_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizacion(id_cotizacion)
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

-- =========================================
-- Detalles (Many-to-Many) - OT (Orden de Trabajo)
-- =========================================

-- OT <-> MATERIAL
-- Permite duplicados: el mismo material puede aparecer múltiples veces en la misma OT
CREATE TABLE ot_material (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_material     INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_otm_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_otm_material
        FOREIGN KEY (id_material)
        REFERENCES material(id_material)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_ot_material_material ON ot_material (id_material);

-- OT <-> IMPORTACION
-- Permite duplicados: la misma importación puede aparecer múltiples veces en la misma OT
CREATE TABLE ot_importacion (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_importacion  INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_oti_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_oti_importacion
        FOREIGN KEY (id_importacion)
        REFERENCES importacion(id_importacion)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_ot_importacion_importacion ON ot_importacion (id_importacion);

-- OT <-> PROCESO/MAQUINA
-- Permite duplicados: el mismo proceso puede aparecer múltiples veces en la misma OT
CREATE TABLE ot_proceso (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_proceso      INT NOT NULL,
    tiempo          INT DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT fk_otp_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_otp_proceso
        FOREIGN KEY (id_proceso)
        REFERENCES proceso_maquina(id_proceso)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_ot_proceso_proceso ON ot_proceso (id_proceso);

-- =========================================
-- USUARIO (para colaboradores)
-- =========================================
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(100) NOT NULL,
    apellido_usuario VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    cargo VARCHAR(100),
    departamento VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Inactivo', 'Suspendido')),
    password VARCHAR(255),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_usuario_estado ON usuario(estado);
CREATE INDEX idx_usuario_departamento ON usuario(departamento);
CREATE INDEX idx_usuario_email_login ON usuario(email);

-- Crear trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_usuario_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_usuario_timestamp
    BEFORE UPDATE ON usuario
    FOR EACH ROW
    EXECUTE FUNCTION update_usuario_timestamp();

-- =========================================
-- Tablas específicas de OT
-- =========================================

-- ARCHIVOS (para archivos, puede estar asociado a OT o ser independiente)
CREATE TABLE archivo (
    id SERIAL PRIMARY KEY,
    id_ot           INT NULL,
    nombre_archivo  VARCHAR(255) NOT NULL,
    nombre_original VARCHAR(255) NOT NULL,
    tipo_archivo    VARCHAR(50) NOT NULL,
    tipo_mime       VARCHAR(100) NOT NULL,
    tamano_archivo  BIGINT NOT NULL DEFAULT 0,
    ruta_archivo    TEXT NOT NULL,
    fecha_subida    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones   TEXT,
    activo          BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_archivo_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Índices para la tabla archivo
CREATE INDEX idx_archivo_ot ON archivo (id_ot);
CREATE INDEX idx_archivo_tipo ON archivo (tipo_archivo);
CREATE INDEX idx_archivo_activo ON archivo (activo);
CREATE INDEX idx_archivo_tipo_mime ON archivo (tipo_mime);
CREATE INDEX idx_archivo_fecha_subida ON archivo (fecha_subida);

-- Comentarios para documentar la tabla

-- REGISTRO TIEMPO (para colaboradores, puede estar asociado a OT o ser independiente)
CREATE TABLE registro_tiempo (
    id SERIAL PRIMARY KEY,
    id_ot           INT NULL,
    id_colaborador  INT,
    fecha_inicio    TIMESTAMP,
    fecha_fin       TIMESTAMP,
    fecha_inicio_esperada TIMESTAMP,
    fecha_fin_esperada TIMESTAMP,
    tiempo_trabajado INT DEFAULT 0, -- en minutos
    descripcion     TEXT,
    estado          VARCHAR(50) DEFAULT 'En Progreso',

    CONSTRAINT fk_rt_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_rt_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX idx_registro_tiempo_ot ON registro_tiempo (id_ot);
CREATE INDEX idx_registro_tiempo_colaborador ON registro_tiempo (id_colaborador);




