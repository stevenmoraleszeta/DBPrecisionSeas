-- =========================================
-- SCRIPT DE MIGRACIÓN: OT_PLANO_SOLIDO y OT_REGISTRO_TIEMPO
-- =========================================
-- Este script migra las tablas antiguas a las nuevas con id_ot permitiendo NULL
-- Ejecutar en pgAdmin o psql

-- =========================================
-- 1. CREAR NUEVAS TABLAS
-- =========================================

-- Crear tabla plano_solido
CREATE TABLE IF NOT EXISTS plano_solido (
    id SERIAL PRIMARY KEY,
    id_ot           INT NULL,
    nombre_archivo  VARCHAR(255),
    tipo_archivo    VARCHAR(50),
    ruta_archivo    TEXT,
    fecha_subida    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones   TEXT,

    CONSTRAINT fk_ps_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Crear tabla registro_tiempo
CREATE TABLE IF NOT EXISTS registro_tiempo (
    id SERIAL PRIMARY KEY,
    id_ot           INT NULL,
    id_colaborador  INT,
    fecha_inicio    TIMESTAMP,
    fecha_fin       TIMESTAMP,
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

-- =========================================
-- 2. CREAR ÍNDICES
-- =========================================

-- Índices para plano_solido
CREATE INDEX IF NOT EXISTS idx_plano_solido_ot ON plano_solido (id_ot);

-- Índices para registro_tiempo
CREATE INDEX IF NOT EXISTS idx_registro_tiempo_ot ON registro_tiempo (id_ot);
CREATE INDEX IF NOT EXISTS idx_registro_tiempo_colaborador ON registro_tiempo (id_colaborador);

-- =========================================
-- 3. MIGRAR DATOS EXISTENTES
-- =========================================

-- Migrar datos de ot_plano_solido a plano_solido
INSERT INTO plano_solido (id_ot, nombre_archivo, tipo_archivo, ruta_archivo, fecha_subida, observaciones)
SELECT id_ot, nombre_archivo, tipo_archivo, ruta_archivo, fecha_subida, observaciones
FROM ot_plano_solido
ON CONFLICT DO NOTHING;

-- Migrar datos de ot_registro_tiempo a registro_tiempo
INSERT INTO registro_tiempo (id_ot, id_colaborador, fecha_inicio, fecha_fin, tiempo_trabajado, descripcion, estado)
SELECT id_ot, id_colaborador, fecha_inicio, fecha_fin, tiempo_trabajado, descripcion, estado
FROM ot_registro_tiempo
ON CONFLICT DO NOTHING;

-- =========================================
-- 4. CREAR PROCEDIMIENTOS ALMACENADOS
-- =========================================

-- Procedimientos para plano_solido
CREATE OR REPLACE FUNCTION sp_create_plano_solido(
    p_id_ot INT DEFAULT NULL, p_nombre_archivo VARCHAR DEFAULT NULL, p_tipo_archivo VARCHAR DEFAULT NULL,
    p_ruta_archivo TEXT DEFAULT NULL, p_observaciones TEXT DEFAULT NULL
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO plano_solido (
        id_ot, nombre_archivo, tipo_archivo, ruta_archivo, observaciones
    ) VALUES (
        p_id_ot, p_nombre_archivo, p_tipo_archivo, p_ruta_archivo, p_observaciones
    ) RETURNING id INTO v_id;
    
    RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_plano_solido(p_id INT)
RETURNS plano_solido AS $$
    SELECT * FROM plano_solido WHERE id = p_id;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_planos_solidos(
    p_id_ot INT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
    id INT,
    id_ot INT,
    nombre_archivo VARCHAR,
    tipo_archivo VARCHAR,
    ruta_archivo TEXT,
    fecha_subida TIMESTAMP,
    observaciones TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ps.id,
        ps.id_ot,
        ps.nombre_archivo,
        ps.tipo_archivo,
        ps.ruta_archivo,
        ps.fecha_subida,
        ps.observaciones
    FROM plano_solido ps
    WHERE (p_id_ot IS NULL OR ps.id_ot = p_id_ot)
    ORDER BY ps.fecha_subida DESC
    LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_plano_solido(
    p_id INT, p_nombre_archivo VARCHAR, p_tipo_archivo VARCHAR,
    p_ruta_archivo TEXT, p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE plano_solido
    SET nombre_archivo = p_nombre_archivo,
        tipo_archivo = p_tipo_archivo,
        ruta_archivo = p_ruta_archivo,
        observaciones = p_observaciones
    WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_delete_plano_solido(p_id INT) RETURNS VOID AS $$
BEGIN
    DELETE FROM plano_solido WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Procedimientos para registro_tiempo
CREATE OR REPLACE FUNCTION sp_create_registro_tiempo(
    p_id_ot INT DEFAULT NULL, p_id_colaborador INT DEFAULT NULL, p_fecha_inicio TIMESTAMP DEFAULT NULL,
    p_fecha_fin TIMESTAMP DEFAULT NULL, p_tiempo_trabajado INT DEFAULT NULL, p_descripcion TEXT DEFAULT NULL, p_estado VARCHAR DEFAULT NULL
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO registro_tiempo (
        id_ot, id_colaborador, fecha_inicio, fecha_fin, tiempo_trabajado, descripcion, estado
    ) VALUES (
        p_id_ot, p_id_colaborador, p_fecha_inicio, p_fecha_fin,
        COALESCE(p_tiempo_trabajado,0), p_descripcion, COALESCE(p_estado,'En Progreso')
    ) RETURNING id INTO v_id;
    
    RETURN v_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_registro_tiempo(p_id INT)
RETURNS registro_tiempo AS $$
    SELECT * FROM registro_tiempo WHERE id = p_id;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION list_registros_tiempo(
    p_id_ot INT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
    id INT,
    id_ot INT,
    id_colaborador INT,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    tiempo_trabajado INT,
    descripcion TEXT,
    estado VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rt.id,
        rt.id_ot,
        rt.id_colaborador,
        rt.fecha_inicio,
        rt.fecha_fin,
        rt.tiempo_trabajado,
        rt.descripcion,
        rt.estado
    FROM registro_tiempo rt
    WHERE (p_id_ot IS NULL OR rt.id_ot = p_id_ot)
    ORDER BY rt.fecha_inicio DESC
    LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_update_registro_tiempo(
    p_id INT, p_fecha_inicio TIMESTAMP, p_fecha_fin TIMESTAMP,
    p_tiempo_trabajado INT, p_descripcion TEXT, p_estado VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE registro_tiempo
    SET fecha_inicio = p_fecha_inicio,
        fecha_fin = p_fecha_fin,
        tiempo_trabajado = COALESCE(p_tiempo_trabajado,0),
        descripcion = p_descripcion,
        estado = COALESCE(p_estado,'En Progreso')
    WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_delete_registro_tiempo(p_id INT) RETURNS VOID AS $$
BEGIN
    DELETE FROM registro_tiempo WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de archivos por OT
CREATE OR REPLACE FUNCTION get_archivos_stats(p_id_ot INT DEFAULT NULL)
RETURNS TABLE(
    total_archivos INT,
    archivos_planos INT,
    archivos_solid INT,
    otros_archivos INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INT AS total_archivos,
        COUNT(CASE WHEN tipo_archivo ILIKE '%plano%' THEN 1 END)::INT AS archivos_planos,
        COUNT(CASE WHEN tipo_archivo ILIKE '%solid%' THEN 1 END)::INT AS archivos_solid,
        COUNT(CASE WHEN tipo_archivo NOT ILIKE '%plano%' AND tipo_archivo NOT ILIKE '%solid%' THEN 1 END)::INT AS otros_archivos
    FROM plano_solido
    WHERE (p_id_ot IS NULL OR id_ot = p_id_ot);
END; $$ LANGUAGE plpgsql;

-- Función para obtener archivos recientes
CREATE OR REPLACE FUNCTION get_archivos_recientes(
    p_id_ot INT DEFAULT NULL, p_dias INT DEFAULT 30
) RETURNS TABLE(
    id INT,
    nombre_archivo VARCHAR,
    tipo_archivo VARCHAR,
    fecha_subida TIMESTAMP,
    dias_desde_subida INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ps.id,
        ps.nombre_archivo,
        ps.tipo_archivo,
        ps.fecha_subida,
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ps.fecha_subida))::INT AS dias_desde_subida
    FROM plano_solido ps
    WHERE (p_id_ot IS NULL OR ps.id_ot = p_id_ot)
        AND ps.fecha_subida >= CURRENT_TIMESTAMP - INTERVAL '1 day' * p_dias
    ORDER BY ps.fecha_subida DESC;
END; $$ LANGUAGE plpgsql;

-- Función para calcular tiempo total trabajado en una OT
CREATE OR REPLACE FUNCTION get_tiempo_total_trabajado(p_id_ot INT DEFAULT NULL)
RETURNS TABLE(
    total_registros INT,
    tiempo_total_minutos INT,
    tiempo_total_horas NUMERIC,
    registros_completados INT,
    registros_en_progreso INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INT AS total_registros,
        COALESCE(SUM(tiempo_trabajado), 0) AS tiempo_total_minutos,
        ROUND(COALESCE(SUM(tiempo_trabajado), 0) / 60.0, 2) AS tiempo_total_horas,
        COUNT(CASE WHEN estado = 'Completado' THEN 1 END)::INT AS registros_completados,
        COUNT(CASE WHEN estado = 'En Progreso' THEN 1 END)::INT AS registros_en_progreso
    FROM registro_tiempo
    WHERE (p_id_ot IS NULL OR id_ot = p_id_ot);
END; $$ LANGUAGE plpgsql;

-- Función para obtener tiempo trabajado por colaborador
CREATE OR REPLACE FUNCTION get_tiempo_por_colaborador(p_id_ot INT DEFAULT NULL)
RETURNS TABLE(
    id_colaborador INT,
    total_registros INT,
    tiempo_total_minutos INT,
    tiempo_total_horas NUMERIC,
    ultima_actividad TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rt.id_colaborador,
        COUNT(*)::INT AS total_registros,
        COALESCE(SUM(rt.tiempo_trabajado), 0) AS tiempo_total_minutos,
        ROUND(COALESCE(SUM(rt.tiempo_trabajado), 0) / 60.0, 2) AS tiempo_total_horas,
        MAX(rt.fecha_inicio) AS ultima_actividad
    FROM registro_tiempo rt
    WHERE (p_id_ot IS NULL OR rt.id_ot = p_id_ot)
    GROUP BY rt.id_colaborador
    ORDER BY tiempo_total_minutos DESC;
END; $$ LANGUAGE plpgsql;

-- Función para obtener registros del día actual
CREATE OR REPLACE FUNCTION get_registros_hoy(p_id_ot INT DEFAULT NULL)
RETURNS TABLE(
    id INT,
    id_colaborador INT,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    tiempo_trabajado INT,
    descripcion TEXT,
    estado VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rt.id,
        rt.id_colaborador,
        rt.fecha_inicio,
        rt.fecha_fin,
        rt.tiempo_trabajado,
        rt.descripcion,
        rt.estado
    FROM registro_tiempo rt
    WHERE (p_id_ot IS NULL OR rt.id_ot = p_id_ot)
        AND DATE(rt.fecha_inicio) = CURRENT_DATE
    ORDER BY rt.fecha_inicio DESC;
END; $$ LANGUAGE plpgsql;

-- Función para listar archivos por tipo
CREATE OR REPLACE FUNCTION list_archivos_por_tipo(
    p_id_ot INT DEFAULT NULL, p_tipo_archivo VARCHAR DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
    id INT,
    id_ot INT,
    nombre_archivo VARCHAR,
    tipo_archivo VARCHAR,
    ruta_archivo TEXT,
    fecha_subida TIMESTAMP,
    observaciones TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ps.id,
        ps.id_ot,
        ps.nombre_archivo,
        ps.tipo_archivo,
        ps.ruta_archivo,
        ps.fecha_subida,
        ps.observaciones
    FROM plano_solido ps
    WHERE (p_id_ot IS NULL OR ps.id_ot = p_id_ot) AND ps.tipo_archivo = p_tipo_archivo
    ORDER BY ps.fecha_subida DESC
    LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- Función para listar registros por colaborador
CREATE OR REPLACE FUNCTION list_registros_por_colaborador(
    p_id_colaborador INT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
    id INT,
    id_ot INT,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    tiempo_trabajado INT,
    descripcion TEXT,
    estado VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rt.id,
        rt.id_ot,
        rt.fecha_inicio,
        rt.fecha_fin,
        rt.tiempo_trabajado,
        rt.descripcion,
        rt.estado
    FROM registro_tiempo rt
    WHERE rt.id_colaborador = p_id_colaborador
    ORDER BY rt.fecha_inicio DESC
    LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- Función para listar registros por estado
CREATE OR REPLACE FUNCTION list_registros_por_estado(
    p_id_ot INT DEFAULT NULL, p_estado VARCHAR DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
    id INT,
    id_ot INT,
    id_colaborador INT,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    tiempo_trabajado INT,
    descripcion TEXT,
    estado VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rt.id,
        rt.id_ot,
        rt.id_colaborador,
        rt.fecha_inicio,
        rt.fecha_fin,
        rt.tiempo_trabajado,
        rt.descripcion,
        rt.estado
    FROM registro_tiempo rt
    WHERE (p_id_ot IS NULL OR rt.id_ot = p_id_ot) AND rt.estado = p_estado
    ORDER BY rt.fecha_inicio DESC
    LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- Función para marcar registro como completado
CREATE OR REPLACE FUNCTION sp_completar_registro_tiempo(
    p_id INT DEFAULT NULL, p_fecha_fin TIMESTAMP DEFAULT NULL, p_tiempo_trabajado INT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE registro_tiempo
    SET fecha_fin = p_fecha_fin,
        tiempo_trabajado = COALESCE(p_tiempo_trabajado,0),
        estado = 'Completado'
    WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- =========================================
-- 5. VERIFICAR MIGRACIÓN
-- =========================================

-- Verificar que los datos se migraron correctamente
DO $$
DECLARE
    v_planos_count INT;
    v_registros_count INT;
    v_planos_original INT;
    v_registros_original INT;
BEGIN
    -- Contar registros en las tablas originales
    SELECT COUNT(*) INTO v_planos_original FROM ot_plano_solido;
    SELECT COUNT(*) INTO v_registros_original FROM ot_registro_tiempo;
    
    -- Contar registros en las nuevas tablas
    SELECT COUNT(*) INTO v_planos_count FROM plano_solido;
    SELECT COUNT(*) INTO v_registros_count FROM registro_tiempo;
    
    -- Mostrar resultados
    RAISE NOTICE 'Migración completada:';
    RAISE NOTICE 'Planos: % -> %', v_planos_original, v_planos_count;
    RAISE NOTICE 'Registros de tiempo: % -> %', v_registros_original, v_registros_count;
    
    -- Verificar que coinciden
    IF v_planos_count = v_planos_original AND v_registros_count = v_registros_original THEN
        RAISE NOTICE '✅ Migración exitosa - Todos los datos se migraron correctamente';
    ELSE
        RAISE NOTICE '⚠️  Advertencia: Los conteos no coinciden. Revisar la migración.';
    END IF;
END $$;

-- =========================================
-- 6. LIMPIEZA (OPCIONAL - DESCOMENTAR SI DESEAS ELIMINAR LAS TABLAS ANTIGUAS)
-- =========================================

-- ⚠️  ADVERTENCIA: Solo ejecutar después de verificar que la migración fue exitosa
-- ⚠️  ADVERTENCIA: Esto eliminará permanentemente las tablas antiguas

/*
-- Eliminar las tablas antiguas (solo si la migración fue exitosa)
DROP TABLE IF EXISTS ot_plano_solido CASCADE;
DROP TABLE IF EXISTS ot_registro_tiempo CASCADE;

-- Eliminar las funciones antiguas
DROP FUNCTION IF EXISTS sp_create_ot_plano_solido(INT, VARCHAR, VARCHAR, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_ot_plano_solido(INT);
DROP FUNCTION IF EXISTS list_ot_planos_solidos(INT, INT, INT);
DROP FUNCTION IF EXISTS sp_update_ot_plano_solido(INT, VARCHAR, VARCHAR, TEXT, TEXT);
DROP FUNCTION IF EXISTS sp_delete_ot_plano_solido(INT);

DROP FUNCTION IF EXISTS sp_create_ot_registro_tiempo(INT, INT, TIMESTAMP, TIMESTAMP, INT, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS get_ot_registro_tiempo(INT);
DROP FUNCTION IF EXISTS list_ot_registros_tiempo(INT, INT, INT);
DROP FUNCTION IF EXISTS sp_update_ot_registro_tiempo(INT, TIMESTAMP, TIMESTAMP, INT, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS sp_delete_ot_registro_tiempo(INT);

RAISE NOTICE '🗑️  Tablas y funciones antiguas eliminadas';
*/

-- =========================================
-- RESUMEN DE LA MIGRACIÓN
-- =========================================
-- ✅ Nuevas tablas creadas: plano_solido, registro_tiempo
-- ✅ Datos migrados desde las tablas antiguas
-- ✅ Nuevos procedimientos almacenados creados
-- ✅ Índices creados para optimizar consultas
-- ✅ Constraint de id_ot permitiendo NULL (ON DELETE SET NULL)
-- 
-- FUNCIONES CREADAS:
-- 
-- Para plano_solido:
-- - sp_create_plano_solido: Crear archivo
-- - get_plano_solido: Obtener archivo por ID
-- - list_planos_solidos: Listar archivos con filtros
-- - list_archivos_por_tipo: Listar por tipo específico
-- - sp_update_plano_solido: Actualizar archivo
-- - sp_delete_plano_solido: Eliminar archivo
-- - get_archivos_stats: Estadísticas de archivos
-- - get_archivos_recientes: Archivos recientes
-- 
-- Para registro_tiempo:
-- - sp_create_registro_tiempo: Crear registro
-- - get_registro_tiempo: Obtener registro por ID
-- - list_registros_tiempo: Listar registros con filtros
-- - list_registros_por_colaborador: Listar por colaborador
-- - list_registros_por_estado: Listar por estado
-- - sp_update_registro_tiempo: Actualizar registro
-- - sp_completar_registro_tiempo: Marcar como completado
-- - sp_delete_registro_tiempo: Eliminar registro
-- - get_tiempo_total_trabajado: Tiempo total trabajado
-- - get_tiempo_por_colaborador: Tiempo por colaborador
-- - get_registros_hoy: Registros del día actual
-- 
-- Las nuevas tablas permiten:
-- - Archivos y registros de tiempo independientes (id_ot = NULL)
-- - Archivos y registros asociados a OT (id_ot = valor)
-- - Eliminación de OT sin perder archivos/registros (se establece id_ot = NULL)
-- 
-- Para completar la migración, ejecutar la sección 6 (LIMPIEZA) después de verificar
-- que todo funciona correctamente en tu aplicación.
