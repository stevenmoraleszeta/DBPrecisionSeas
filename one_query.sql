-- =========================================
-- ONE QUERY - PRECISION SEAS ERP DATABASE
-- =========================================
-- Este archivo contiene todo el código necesario para crear
-- la base de datos completa en una sola ejecución
-- =========================================

-- =========================================
-- 1. CREAR BASE DE DATOS
-- =========================================
--CREATE DATABASE db_precision_seas;

-- =========================================
-- 2. CONECTAR A LA BASE DE DATOS CREADA
-- =========================================
--\c db_precision_seas;

-- =========================================
-- 3. CREAR TABLAS
-- =========================================

-- EMPRESA
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

-- CONTACTO (N:1 EMPRESA)
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

-- COTIZACION (cabezal)
CREATE TABLE cotizacion (
    id_cotizacion    SERIAL PRIMARY KEY,
    num_cotizacion   VARCHAR(30) UNIQUE NOT NULL,
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

-- Catálogos: MATERIAL / IMPORTACION
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

-- PROCESO/MAQUINA
CREATE TABLE proceso_maquina (
    id_proceso        SERIAL PRIMARY KEY,
    descripcion       VARCHAR(200) NOT NULL,
    tarifa_x_minuto   NUMERIC(10,2) DEFAULT 0
);

-- Detalles (Many-to-Many)

-- COTIZACION <-> MATERIAL
CREATE TABLE cotizacion_material (
    id_cotizacion   INT NOT NULL,
    id_material     INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_mat PRIMARY KEY (id_cotizacion, id_material),

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
CREATE TABLE cotizacion_importacion (
    id_cotizacion   INT NOT NULL,
    id_importacion  INT NOT NULL,
    cantidad        INT DEFAULT 0,
    dimension       VARCHAR(100),
    precio          NUMERIC(12,2) DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_imp PRIMARY KEY (id_cotizacion, id_importacion),

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
CREATE TABLE cotizacion_proceso (
    id_cotizacion   INT NOT NULL,
    id_proceso      INT NOT NULL,
    tiempo          INT DEFAULT 0,
    total           NUMERIC(12,2) DEFAULT 0,

    CONSTRAINT pk_cot_proceso PRIMARY KEY (id_cotizacion, id_proceso),

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
-- 4. CREAR PROCEDIMIENTOS ALMACENADOS
-- =========================================

-- EMPRESA
CREATE OR REPLACE FUNCTION sp_upsert_empresa(
  p_cod_empresa VARCHAR, p_nombre VARCHAR, p_direccion TEXT, p_telefono VARCHAR,
  p_email_factura VARCHAR, p_cedula VARCHAR, p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id_empresa INT;
BEGIN
  INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones)
  VALUES (p_cod_empresa, p_nombre, p_direccion, p_telefono, p_email_factura, p_cedula, p_observaciones)
  ON CONFLICT (cod_empresa) DO UPDATE
  SET nombre_empresa = EXCLUDED.nombre_empresa,
      direccion      = EXCLUDED.direccion,
      telefono       = EXCLUDED.telefono,
      email_factura  = EXCLUDED.email_factura,
      cedula         = EXCLUDED.cedula,
      observaciones  = EXCLUDED.observaciones
  RETURNING id_empresa INTO v_id_empresa;
  
  RETURN v_id_empresa;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_empresa_by_cod(p_cod_empresa VARCHAR)
RETURNS empresa AS $$
  SELECT * FROM empresa WHERE cod_empresa = p_cod_empresa;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_empresa(p_id_empresa INT)
RETURNS empresa AS $$
  SELECT * FROM empresa WHERE id_empresa = p_id_empresa;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_empresas(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF empresa AS $$
  SELECT *
  FROM empresa
  WHERE p_search IS NULL
     OR (cod_empresa ILIKE '%'||p_search||'%' OR nombre_empresa ILIKE '%'||p_search||'%')
  ORDER BY nombre_empresa NULLS LAST, cod_empresa
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_empresa(p_id_empresa INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM empresa WHERE id_empresa = p_id_empresa;
END; $$ LANGUAGE plpgsql;

-- CONTACTO
CREATE OR REPLACE FUNCTION sp_create_contacto(
  p_id_empresa INT, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas)
  VALUES (p_id_empresa, p_nombre_contacto, p_telefono, p_email, p_puesto, p_notas)
  RETURNING id_contacto INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_contacto(
  p_id_contacto INT, p_id_empresa INT, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE contacto
  SET id_empresa = p_id_empresa, nombre_contacto = p_nombre_contacto, telefono = p_telefono,
      email = p_email, puesto = p_puesto, notas = p_notas
  WHERE id_contacto = p_id_contacto;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_contacto(p_id_contacto INT)
RETURNS contacto AS $$
  SELECT * FROM contacto WHERE id_contacto = p_id_contacto;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_contactos(
  p_id_empresa INT DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF contacto AS $$
  SELECT *
  FROM contacto
  WHERE (p_id_empresa IS NULL OR id_empresa = p_id_empresa)
    AND (p_search IS NULL OR (nombre_contacto ILIKE '%'||p_search||'%' OR email ILIKE '%'||p_search||'%'))
  ORDER BY nombre_contacto
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_contacto(p_id_contacto INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM contacto WHERE id_contacto = p_id_contacto;
END; $$ LANGUAGE plpgsql;

-- COTIZACION
CREATE OR REPLACE FUNCTION sp_create_cotizacion(
  p_num_cotizacion VARCHAR, p_id_empresa INT, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR
) RETURNS INT AS $$
DECLARE v_id_cotizacion INT;
BEGIN
  INSERT INTO cotizacion (
    num_cotizacion, id_empresa, id_contacto, direccion, telefono, desc_servicio, cantidad,
    moneda, validez_oferta, tiempo_entrega, forma_pago,
    subtotal, descuento, iva, total, observa_cliente, observa_interna
  ) VALUES (
    p_num_cotizacion, p_id_empresa, p_id_contacto, p_direccion, p_telefono, p_desc_servicio,
    COALESCE(p_cantidad,0), p_moneda, p_validez_oferta, p_tiempo_entrega, p_forma_pago,
    0, 0, 0, 0, NULL, NULL
  ) RETURNING id_cotizacion INTO v_id_cotizacion;
  
  RETURN v_id_cotizacion;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_cotizacion_info(
  p_id_cotizacion INT, p_id_empresa INT, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR,
  p_observa_cliente TEXT, p_observa_interna TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET id_empresa = p_id_empresa, id_contacto = p_id_contacto, direccion = p_direccion,
      telefono = p_telefono, desc_servicio = p_desc_servicio, cantidad = COALESCE(p_cantidad,0),
      moneda = p_moneda, validez_oferta = p_validez_oferta, tiempo_entrega = p_tiempo_entrega,
      forma_pago = p_forma_pago, observa_cliente = p_observa_cliente, observa_interna = p_observa_interna
  WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cotizacion(p_id_cotizacion INT)
RETURNS cotizacion AS $$
  SELECT * FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_cotizacion_by_num(p_num_cotizacion VARCHAR)
RETURNS cotizacion AS $$
  SELECT * FROM cotizacion WHERE num_cotizacion = p_num_cotizacion;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_cotizaciones(
  p_id_empresa INT DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF cotizacion AS $$
  SELECT *
  FROM cotizacion
  WHERE (p_id_empresa IS NULL OR id_empresa = p_id_empresa)
    AND (p_search IS NULL OR (num_cotizacion ILIKE '%'||p_search||'%' OR desc_servicio ILIKE '%'||p_search||'%'))
  ORDER BY num_cotizacion DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_cotizacion(p_id_cotizacion INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_set_montos_cotizacion(
  p_id_cotizacion INT, p_subtotal NUMERIC, p_descuento NUMERIC, p_iva NUMERIC, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET subtotal = COALESCE(p_subtotal,0),
      descuento = COALESCE(p_descuento,0),
      iva = COALESCE(p_iva,0),
      total = COALESCE(p_total,0)
  WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;

-- COTIZACION MATERIAL
CREATE OR REPLACE FUNCTION sp_add_cotizacion_material(
  p_id_cotizacion INT, p_id_material INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  v_total := COALESCE(p_cantidad,0) * COALESCE(p_precio,0);

  INSERT INTO cotizacion_material (id_cotizacion, id_material, cantidad, dimension, precio, total)
  VALUES (p_id_cotizacion, p_id_material, COALESCE(p_cantidad,0), p_dimension, COALESCE(p_precio,0), v_total)
  ON CONFLICT (id_cotizacion, id_material) DO UPDATE
  SET cantidad = EXCLUDED.cantidad,
      dimension = EXCLUDED.dimension,
      precio = EXCLUDED.precio,
      total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_remove_cotizacion_material(
  p_id_cotizacion INT, p_id_material INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_material
  WHERE id_cotizacion = p_id_cotizacion AND id_material = p_id_material;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cotizacion_materiales(p_id_cotizacion INT)
RETURNS TABLE(id_material INT, descripcion TEXT, cantidad INT, dimension VARCHAR, precio NUMERIC, total NUMERIC) AS $$
  SELECT cm.id_material, m.descripcion, cm.cantidad, cm.dimension, cm.precio, cm.total
  FROM cotizacion_material cm
  JOIN material m ON m.id_material = cm.id_material
  WHERE cm.id_cotizacion = p_id_cotizacion
  ORDER BY cm.id_material;
$$ LANGUAGE sql STABLE;

-- COTIZACION IMPORTACION
CREATE OR REPLACE FUNCTION sp_add_cotizacion_importacion(
  p_id_cotizacion INT, p_id_importacion INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  v_total := COALESCE(p_cantidad,0) * COALESCE(p_precio,0);

  INSERT INTO cotizacion_importacion (id_cotizacion, id_importacion, cantidad, dimension, precio, total)
  VALUES (p_id_cotizacion, p_id_importacion, COALESCE(p_cantidad,0), p_dimension, COALESCE(p_precio,0), v_total)
  ON CONFLICT (id_cotizacion, id_importacion) DO UPDATE
  SET cantidad = EXCLUDED.cantidad,
      dimension = EXCLUDED.dimension,
      precio = EXCLUDED.precio,
      total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_remove_cotizacion_importacion(
  p_id_cotizacion INT, p_id_importacion INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_importacion
  WHERE id_cotizacion = p_id_cotizacion AND id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cotizacion_importaciones(p_id_cotizacion INT)
RETURNS TABLE(id_importacion INT, descripcion TEXT, cantidad INT, dimension VARCHAR, precio NUMERIC, total NUMERIC) AS $$
  SELECT ci.id_importacion, i.descripcion, ci.cantidad, ci.dimension, ci.precio, ci.total
  FROM cotizacion_importacion ci
  JOIN importacion i ON i.id_importacion = ci.id_importacion
  WHERE ci.id_cotizacion = p_id_cotizacion
  ORDER BY ci.id_importacion;
$$ LANGUAGE sql STABLE;

-- COTIZACION PROCESO
CREATE OR REPLACE FUNCTION sp_add_cotizacion_proceso(
  p_id_cotizacion INT, p_id_proceso INT, p_tiempo INT
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  SELECT COALESCE(p_tiempo,0) * COALESCE(tarifa_x_minuto,0) INTO v_total
  FROM proceso_maquina WHERE id_proceso = p_id_proceso;

  INSERT INTO cotizacion_proceso (id_cotizacion, id_proceso, tiempo, total)
  VALUES (p_id_cotizacion, p_id_proceso, COALESCE(p_tiempo,0), v_total)
  ON CONFLICT (id_cotizacion, id_proceso) DO UPDATE
  SET tiempo = EXCLUDED.tiempo,
      total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_remove_cotizacion_proceso(
  p_id_cotizacion INT, p_id_proceso INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_proceso
  WHERE id_cotizacion = p_id_cotizacion AND id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_cotizacion_procesos(p_id_cotizacion INT)
RETURNS TABLE(id_proceso INT, descripcion VARCHAR, tarifa_x_minuto NUMERIC, tiempo INT, total NUMERIC) AS $$
  SELECT cp.id_proceso, pm.descripcion, pm.tarifa_x_minuto, cp.tiempo, cp.total
  FROM cotizacion_proceso cp
  JOIN proceso_maquina pm ON pm.id_proceso = cp.id_proceso
  WHERE cp.id_cotizacion = p_id_cotizacion
  ORDER BY cp.id_proceso;
$$ LANGUAGE sql STABLE;

-- MATERIAL
CREATE OR REPLACE FUNCTION sp_create_material(
  p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO material (descripcion, cantidad, unidad)
  VALUES (p_descripcion, COALESCE(p_cantidad,0), p_unidad)
  RETURNING id_material INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_material(
  p_id_material INT, p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS VOID AS $$
BEGIN
  UPDATE material
  SET descripcion = p_descripcion, cantidad = COALESCE(p_cantidad,0), unidad = p_unidad
  WHERE id_material = p_id_material;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_material(p_id_material INT)
RETURNS material AS $$
  SELECT * FROM material WHERE id_material = p_id_material;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_materiales(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF material AS $$
  SELECT *
  FROM material
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_material
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_material(p_id_material INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM material WHERE id_material = p_id_material;
END; $$ LANGUAGE plpgsql;

-- IMPORTACION
CREATE OR REPLACE FUNCTION sp_create_importacion(
  p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO importacion (descripcion, cantidad, unidad)
  VALUES (p_descripcion, COALESCE(p_cantidad,0), p_unidad)
  RETURNING id_importacion INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_importacion(
  p_id_importacion INT, p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS VOID AS $$
BEGIN
  UPDATE importacion
  SET descripcion = p_descripcion, cantidad = COALESCE(p_cantidad,0), unidad = p_unidad
  WHERE id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_importacion(p_id_importacion INT)
RETURNS importacion AS $$
  SELECT * FROM importacion WHERE id_importacion = p_id_importacion;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_importaciones(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF importacion AS $$
  SELECT *
  FROM importacion
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_importacion
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_importacion(p_id_importacion INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM importacion WHERE id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;

-- PROCESO MAQUINA
CREATE OR REPLACE FUNCTION sp_create_proceso(
  p_descripcion VARCHAR, p_tarifa_x_minuto NUMERIC
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO proceso_maquina (descripcion, tarifa_x_minuto)
  VALUES (p_descripcion, COALESCE(p_tarifa_x_minuto,0))
  RETURNING id_proceso INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_proceso(
  p_id_proceso INT, p_descripcion VARCHAR, p_tarifa_x_minuto NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE proceso_maquina
  SET descripcion = p_descripcion, tarifa_x_minuto = COALESCE(p_tarifa_x_minuto,0)
  WHERE id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_proceso(p_id_proceso INT)
RETURNS proceso_maquina AS $$
  SELECT * FROM proceso_maquina WHERE id_proceso = p_id_proceso;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_procesos(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF proceso_maquina AS $$
  SELECT *
  FROM proceso_maquina
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_proceso
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION sp_delete_proceso(p_id_proceso INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM proceso_maquina WHERE id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;

-- =========================================
-- 5. INSERTAR DATOS DE PRUEBA
-- =========================================

-- Insertar empresas de prueba
INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones) VALUES
('EMP001', 'Marina del Sur S.A.', 'Av. Costanera 123, Valparaíso', '+56 32 123 4567', 'facturacion@marinadelsur.cl', '96.789.123-4', 'Cliente principal del puerto'),
('EMP002', 'Astilleros del Pacífico', 'Calle del Mar 456, San Antonio', '+56 35 987 6543', 'admin@astilleros.cl', '78.456.789-1', 'Especialistas en reparación naval'),
('EMP003', 'Pesquera Austral', 'Puerto Pesquero 789, Talcahuano', '+56 41 555 1234', 'contabilidad@pesqueraus.cl', '65.123.456-7', 'Flota pesquera comercial');

-- Insertar contactos de prueba
INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas) VALUES
(1, 'Juan Pérez', '+56 9 1234 5678', 'juan.perez@marinadelsur.cl', 'Gerente General', 'Contacto principal'),
(1, 'María González', '+56 9 8765 4321', 'maria.gonzalez@marinadelsur.cl', 'Jefa de Compras', 'Responsable de cotizaciones'),
(2, 'Carlos Rodríguez', '+56 9 5555 1234', 'carlos.rodriguez@astilleros.cl', 'Director Técnico', 'Especialista en proyectos'),
(3, 'Ana Silva', '+56 9 1111 2222', 'ana.silva@pesqueraus.cl', 'Gerente de Operaciones', 'Maneja toda la flota');

-- Insertar cotizaciones de prueba
INSERT INTO cotizacion (num_cotizacion, id_empresa, id_contacto, desc_servicio, cantidad, moneda, validez_oferta, tiempo_entrega, forma_pago, subtotal, descuento, iva, total) VALUES
('COT-001', 1, 1, 'Reparación de casco de embarcación pesquera', 1, 'USD', '30 días', '4-6 semanas', '50% anticipo, 50% contra entrega', 15000.00, 0.00, 2850.00, 17850.00),
('COT-002', 2, 3, 'Instalación de sistema de propulsión', 1, 'USD', '45 días', '8-10 semanas', '30% anticipo, 40% avance, 30% final', 25000.00, 1250.00, 4750.00, 28500.00),
('COT-003', 3, 4, 'Mantenimiento preventivo de motores', 5, 'USD', '60 días', '2-3 semanas', '100% contra entrega', 5000.00, 0.00, 950.00, 5950.00);

-- Insertar materiales de prueba
INSERT INTO material (descripcion, cantidad, unidad) VALUES
('Acero inoxidable 316L', 100, 'kg'),
('Pintura anticorrosiva marina', 50, 'litros'),
('Tornillos de acero galvanizado', 200, 'unidades'),
('Cables eléctricos marinos', 500, 'metros');

-- Insertar importaciones de prueba
INSERT INTO importacion (descripcion, cantidad, unidad) VALUES
('Motores diesel marinos', 2, 'unidades'),
('Sistemas de navegación GPS', 1, 'conjunto'),
('Equipos de comunicación VHF', 3, 'unidades');

-- Insertar procesos de prueba
INSERT INTO proceso_maquina (descripcion, tarifa_x_minuto) VALUES
('Corte de acero con plasma', 2.50),
('Soldadura TIG', 3.00),
('Pintado con pistola', 1.75),
('Mecanizado CNC', 4.50);

-- =========================================
-- 6. MENSAJE DE CONFIRMACIÓN
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '🎉 BASE DE DATOS CREADA EXITOSAMENTE';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Base de datos: db_precision_seas';
  RAISE NOTICE '✅ Todas las tablas creadas';
  RAISE NOTICE '✅ Todos los procedimientos almacenados creados';
  RAISE NOTICE '✅ Datos de prueba insertados';
  RAISE NOTICE '✅ Índices y restricciones configurados';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 La base de datos está lista para usar!';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Entidades disponibles:';
  RAISE NOTICE '   • empresa (3 registros de prueba)';
  RAISE NOTICE '   • contacto (4 registros de prueba)';
  RAISE NOTICE '   • cotizacion (3 registros de prueba)';
  RAISE NOTICE '   • material (4 registros de prueba)';
  RAISE NOTICE '   • importacion (3 registros de prueba)';
  RAISE NOTICE '   • proceso_maquina (4 registros de prueba)';
  RAISE NOTICE '';
END $$;
