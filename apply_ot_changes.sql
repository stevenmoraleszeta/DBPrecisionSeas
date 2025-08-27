-- =========================================
-- APLICAR CAMBIOS DE OT (Orden de Trabajo) A BASE DE DATOS EXISTENTE
-- =========================================
-- Este archivo aplica la nueva sección OT a una base de datos PostgreSQL existente
-- Ejecutar en la base de datos donde quieres agregar la funcionalidad OT

-- =========================================
-- VERIFICACIÓN DE CONEXIÓN
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '🔍 Verificando conexión a base de datos...';
  RAISE NOTICE '✅ Conectado a: %', current_database();
  RAISE NOTICE '✅ Usuario: %', current_user;
  RAISE NOTICE '✅ Versión PostgreSQL: %', version();
END $$;

-- =========================================
-- VERIFICACIÓN DE TABLAS EXISTENTES
-- =========================================

DO $$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  RAISE NOTICE '🔍 Verificando estructura existente...';
  
  -- Verificar si las tablas principales existen
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'empresa'
  ) INTO v_table_exists;
  
  IF NOT v_table_exists THEN
    RAISE EXCEPTION '❌ La tabla "empresa" no existe. Ejecuta primero create.sql para crear la base de datos completa.';
  END IF;
  
  RAISE NOTICE '✅ Tabla "empresa" encontrada';
  
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'cotizacion'
  ) INTO v_table_exists;
  
  IF NOT v_table_exists THEN
    RAISE EXCEPTION '❌ La tabla "cotizacion" no existe. Ejecuta primero create.sql para crear la base de datos completa.';
  END IF;
  
  RAISE NOTICE '✅ Tabla "cotizacion" encontrada';
  
  RAISE NOTICE '✅ Estructura base verificada correctamente';
END $$;

-- =========================================
-- CREACIÓN DE TABLAS OT
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '🏗️ Creando tablas de OT...';
END $$;

-- Tabla principal OT
CREATE TABLE IF NOT EXISTS ot (
    id_ot            SERIAL PRIMARY KEY,
    num_ot           VARCHAR(30) UNIQUE NOT NULL,
    id_cotizacion    INT,
    po               VARCHAR(100),
    id_empresa       INT,
    id_contacto      INT,
    descripcion      TEXT,
    cantidad         INT DEFAULT 0,
    id_colaborador   INT,
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

-- Tabla relacional OT-Material
CREATE TABLE IF NOT EXISTS ot_material (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_material     INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT uk_ot_mat UNIQUE (id_ot, id_material),

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

-- Tabla relacional OT-Importación
CREATE TABLE IF NOT EXISTS ot_importacion (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_importacion  INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT uk_ot_imp UNIQUE (id_ot, id_importacion),

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

-- Tabla relacional OT-Proceso
CREATE TABLE IF NOT EXISTS ot_proceso (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_proceso      INT NOT NULL,
    tiempo          INT DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT uk_ot_proceso UNIQUE (id_ot, id_proceso),

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

-- Tabla para archivos de OT
CREATE TABLE IF NOT EXISTS ot_plano_solido (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    nombre_archivo  VARCHAR(255),
    tipo_archivo    VARCHAR(50),
    ruta_archivo    TEXT,
    fecha_subida    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones   TEXT,

    CONSTRAINT fk_otps_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Tabla para control de tiempo de OT
CREATE TABLE IF NOT EXISTS ot_registro_tiempo (
    id SERIAL PRIMARY KEY,
    id_ot           INT NOT NULL,
    id_colaborador  INT,
    fecha_inicio    TIMESTAMP,
    fecha_fin       TIMESTAMP,
    tiempo_trabajado INT DEFAULT 0, -- en minutos
    descripcion     TEXT,
    estado          VARCHAR(50) DEFAULT 'En Progreso',

    CONSTRAINT fk_otrt_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

DO $$
BEGIN
  RAISE NOTICE '✅ Todas las tablas de OT creadas correctamente';
END $$;

-- =========================================
-- CREACIÓN DE ÍNDICES
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '🔍 Creando índices para OT...';
END $$;

-- Índices para tabla principal OT
CREATE INDEX IF NOT EXISTS idx_ot_id_cotizacion ON ot (id_cotizacion);
CREATE INDEX IF NOT EXISTS idx_ot_id_empresa ON ot (id_empresa);
CREATE INDEX IF NOT EXISTS idx_ot_id_contacto ON ot (id_contacto);
CREATE INDEX IF NOT EXISTS idx_ot_id_colaborador ON ot (id_colaborador);

-- Índices para tablas relacionales
CREATE INDEX IF NOT EXISTS idx_ot_material_material ON ot_material (id_material);
CREATE INDEX IF NOT EXISTS idx_ot_importacion_importacion ON ot_importacion (id_importacion);
CREATE INDEX IF NOT EXISTS idx_ot_proceso_proceso ON ot_proceso (id_proceso);

-- Índices para tablas específicas
CREATE INDEX IF NOT EXISTS idx_ot_plano_solido_ot ON ot_plano_solido (id_ot);
CREATE INDEX IF NOT EXISTS idx_ot_registro_tiempo_ot ON ot_registro_tiempo (id_ot);
CREATE INDEX IF NOT EXISTS idx_ot_registro_tiempo_colaborador ON ot_registro_tiempo (id_colaborador);

DO $$
BEGIN
  RAISE NOTICE '✅ Todos los índices de OT creados correctamente';
END $$;

-- =========================================
-- VERIFICACIÓN DE PROCEDIMIENTOS EXISTENTES
-- =========================================

DO $$
DECLARE
  v_function_exists BOOLEAN;
BEGIN
  RAISE NOTICE '🔍 Verificando procedimientos almacenados existentes...';
  
  -- Verificar si existe algún procedimiento de cotización
  SELECT EXISTS (
    SELECT FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name = 'sp_create_cotizacion'
  ) INTO v_function_exists;
  
  IF NOT v_function_exists THEN
    RAISE NOTICE '⚠️ No se encontraron procedimientos de cotización. Ejecuta los archivos de procedures/ para crear todos los procedimientos.';
  ELSE
    RAISE NOTICE '✅ Procedimientos de cotización encontrados';
  END IF;
END $$;

-- =========================================
-- MENSAJE FINAL
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '🎉 CAMBIOS DE OT APLICADOS EXITOSAMENTE';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Tablas de OT creadas:';
  RAISE NOTICE '   • ot (tabla principal)';
  RAISE NOTICE '   • ot_material (relación OT-Material)';
  RAISE NOTICE '   • ot_importacion (relación OT-Importación)';
  RAISE NOTICE '   • ot_proceso (relación OT-Proceso)';
  RAISE NOTICE '   • ot_plano_solido (archivos)';
  RAISE NOTICE '   • ot_registro_tiempo (control de tiempo)';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Índices creados para optimizar consultas';
  RAISE NOTICE '✅ Restricciones de integridad referencial configuradas';
  RAISE NOTICE '';
  RAISE NOTICE '📋 PRÓXIMOS PASOS:';
  RAISE NOTICE '   1. Ejecutar los archivos de procedures/ para crear los procedimientos almacenados';
  RAISE NOTICE '   2. Ejecutar insert_test_data.sql para agregar datos de prueba (opcional)';
  RAISE NOTICE '   3. Ejecutar prueba.sql para validar toda la funcionalidad';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 La base de datos está lista para usar la nueva sección OT!';
  RAISE NOTICE '';
END $$;
