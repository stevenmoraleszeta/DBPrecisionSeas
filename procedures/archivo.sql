-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA ARCHIVO
-- =========================================
-- Maneja archivos que pueden estar relacionados con OT o ser independientes
-- Sistema completo de gestión de archivos con almacenamiento local

-- CREATE - Agregar archivo completo
DROP FUNCTION IF EXISTS sp_create_archivo(VARCHAR, VARCHAR, VARCHAR, VARCHAR, BIGINT, TEXT, INTEGER, TEXT);
CREATE OR REPLACE FUNCTION sp_create_archivo(
  p_nombre_archivo VARCHAR, 
  p_nombre_original VARCHAR,
  p_tipo_archivo VARCHAR,
  p_tipo_mime VARCHAR,
  p_tamano_archivo BIGINT,
  p_ruta_archivo TEXT,
  p_id_ot INT DEFAULT NULL,
  p_observaciones TEXT DEFAULT NULL
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO archivo (
    id_ot, nombre_archivo, nombre_original, tipo_archivo, tipo_mime,
    tamano_archivo, ruta_archivo, observaciones, activo
  ) VALUES (
    p_id_ot, p_nombre_archivo, p_nombre_original, p_tipo_archivo, p_tipo_mime,
    p_tamano_archivo, p_ruta_archivo, p_observaciones, TRUE
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- CREATE - Agregar archivo simple (compatibilidad)
DROP FUNCTION IF EXISTS sp_create_archivo_simple(VARCHAR, VARCHAR, TEXT, INTEGER, TEXT);
CREATE OR REPLACE FUNCTION sp_create_archivo_simple(
  p_nombre_archivo VARCHAR, 
  p_tipo_archivo VARCHAR,
  p_ruta_archivo TEXT, 
  p_id_ot INT DEFAULT NULL, 
  p_observaciones TEXT DEFAULT NULL
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO archivo (
    id_ot, nombre_archivo, nombre_original, tipo_archivo, tipo_mime,
    tamano_archivo, ruta_archivo, observaciones, activo
  ) VALUES (
    p_id_ot, p_nombre_archivo, p_nombre_archivo, p_tipo_archivo, 'application/octet-stream',
    0, p_ruta_archivo, p_observaciones, TRUE
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener archivo por ID
DROP FUNCTION IF EXISTS get_archivo(INTEGER);
CREATE OR REPLACE FUNCTION get_archivo(p_id INT) 
RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo
  FROM archivo a
  WHERE a.id = p_id AND a.activo = TRUE;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener archivo por nombre
DROP FUNCTION IF EXISTS get_archivo_by_nombre(VARCHAR);
CREATE OR REPLACE FUNCTION get_archivo_by_nombre(p_nombre VARCHAR) 
RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo
  FROM archivo a
  WHERE a.nombre_archivo = p_nombre AND a.activo = TRUE;
END; $$ LANGUAGE plpgsql;

-- LIST - Listar archivos por OT
DROP FUNCTION IF EXISTS list_archivos(INTEGER, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION list_archivos(
  p_id_ot INT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN,
  total_count BIGINT
) AS $$
DECLARE v_total_count BIGINT;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total_count
  FROM archivo a
  WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) AND a.activo = TRUE;
  
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo, v_total_count
  FROM archivo a
  WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) AND a.activo = TRUE
  ORDER BY a.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- LIST - Listar archivos por tipo
DROP FUNCTION IF EXISTS list_archivos_por_tipo(VARCHAR, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION list_archivos_por_tipo(
  p_tipo_archivo VARCHAR,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN,
  total_count BIGINT
) AS $$
DECLARE v_total_count BIGINT;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total_count
  FROM archivo a
  WHERE a.tipo_archivo = p_tipo_archivo AND a.activo = TRUE;
  
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo, v_total_count
  FROM archivo a
  WHERE a.tipo_archivo = p_tipo_archivo AND a.activo = TRUE
  ORDER BY a.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- LIST - Listar archivos independientes (sin OT)
DROP FUNCTION IF EXISTS list_archivos_independientes(INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION list_archivos_independientes(
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN,
  total_count BIGINT
) AS $$
DECLARE v_total_count BIGINT;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total_count
  FROM archivo a
  WHERE a.id_ot IS NULL AND a.activo = TRUE;
  
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo, v_total_count
  FROM archivo a
  WHERE a.id_ot IS NULL AND a.activo = TRUE
  ORDER BY a.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar información del archivo
DROP FUNCTION IF EXISTS sp_update_archivo(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BIGINT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION sp_update_archivo(
  p_id INT,
  p_nombre_archivo VARCHAR DEFAULT NULL,
  p_nombre_original VARCHAR DEFAULT NULL,
  p_tipo_archivo VARCHAR DEFAULT NULL,
  p_tipo_mime VARCHAR DEFAULT NULL,
  p_tamano_archivo BIGINT DEFAULT NULL,
  p_ruta_archivo TEXT DEFAULT NULL,
  p_observaciones TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE v_updated INT;
BEGIN
  UPDATE archivo SET
    nombre_archivo = COALESCE(p_nombre_archivo, nombre_archivo),
    nombre_original = COALESCE(p_nombre_original, nombre_original),
    tipo_archivo = COALESCE(p_tipo_archivo, tipo_archivo),
    tipo_mime = COALESCE(p_tipo_mime, tipo_mime),
    tamano_archivo = COALESCE(p_tamano_archivo, tamano_archivo),
    ruta_archivo = COALESCE(p_ruta_archivo, ruta_archivo),
    observaciones = COALESCE(p_observaciones, observaciones),
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id = p_id AND activo = TRUE;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar solo observaciones
DROP FUNCTION IF EXISTS sp_update_archivo_observaciones(INTEGER, TEXT);
CREATE OR REPLACE FUNCTION sp_update_archivo_observaciones(
  p_id INT,
  p_observaciones TEXT
) RETURNS BOOLEAN AS $$
DECLARE v_updated INT;
BEGIN
  UPDATE archivo SET
    observaciones = p_observaciones,
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id = p_id AND activo = TRUE;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Asociar archivo a OT
DROP FUNCTION IF EXISTS sp_asociar_archivo_ot(INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION sp_asociar_archivo_ot(
  p_id INT,
  p_id_ot INT
) RETURNS BOOLEAN AS $$
DECLARE v_updated INT;
BEGIN
  UPDATE archivo SET
    id_ot = p_id_ot,
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id = p_id AND activo = TRUE;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Desasociar archivo de OT
DROP FUNCTION IF EXISTS sp_desasociar_archivo_ot(INTEGER);
CREATE OR REPLACE FUNCTION sp_desasociar_archivo_ot(
  p_id INT
) RETURNS BOOLEAN AS $$
DECLARE v_updated INT;
BEGIN
  UPDATE archivo SET
    id_ot = NULL,
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id = p_id AND activo = TRUE;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END; $$ LANGUAGE plpgsql;

-- SOFT DELETE - Desactivar archivo (soft delete)
DROP FUNCTION IF EXISTS sp_delete_archivo(INTEGER);
CREATE OR REPLACE FUNCTION sp_delete_archivo(p_id INT) 
RETURNS BOOLEAN AS $$
DECLARE v_updated INT;
BEGIN
  UPDATE archivo SET
    activo = FALSE,
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id = p_id AND activo = TRUE;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END; $$ LANGUAGE plpgsql;

-- HARD DELETE - Eliminar archivo permanentemente
DROP FUNCTION IF EXISTS sp_hard_delete_archivo(INTEGER);
CREATE OR REPLACE FUNCTION sp_hard_delete_archivo(p_id INT) 
RETURNS BOOLEAN AS $$
DECLARE v_deleted INT;
BEGIN
  DELETE FROM archivo WHERE id = p_id;
  
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted > 0;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar archivos por OT
DROP FUNCTION IF EXISTS sp_delete_archivos_ot(INTEGER);
CREATE OR REPLACE FUNCTION sp_delete_archivos_ot(p_id_ot INT) 
RETURNS INTEGER AS $$
DECLARE v_deleted INT;
BEGIN
  UPDATE archivo SET
    activo = FALSE,
    fecha_modificacion = CURRENT_TIMESTAMP
  WHERE id_ot = p_id_ot AND activo = TRUE;
  
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END; $$ LANGUAGE plpgsql;

-- STATS - Estadísticas de archivos
DROP FUNCTION IF EXISTS get_archivo_stats(INTEGER);
CREATE OR REPLACE FUNCTION get_archivo_stats(p_id_ot INT DEFAULT NULL) 
RETURNS TABLE (
  total_archivos BIGINT,
  total_tamano BIGINT,
  archivos_por_tipo JSON,
  archivos_recientes BIGINT,
  archivos_por_ot JSON
) AS $$
DECLARE v_total_archivos BIGINT;
DECLARE v_total_tamano BIGINT;
DECLARE v_archivos_por_tipo JSON;
DECLARE v_archivos_recientes BIGINT;
DECLARE v_archivos_por_ot JSON;
BEGIN
  -- Total de archivos
  SELECT COUNT(*) INTO v_total_archivos
  FROM archivo a
  WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) AND a.activo = TRUE;
  
  -- Total de tamaño
  SELECT COALESCE(SUM(tamano_archivo), 0) INTO v_total_tamano
  FROM archivo a
  WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) AND a.activo = TRUE;
  
  -- Archivos por tipo
  SELECT json_agg(
    json_build_object(
      'tipo', tipo_archivo,
      'cantidad', cantidad
    )
  ) INTO v_archivos_por_tipo
  FROM (
    SELECT tipo_archivo, COUNT(*) as cantidad
    FROM archivo a
    WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) AND a.activo = TRUE
    GROUP BY tipo_archivo
    ORDER BY cantidad DESC
  ) t;
  
  -- Archivos recientes (últimos 7 días)
  SELECT COUNT(*) INTO v_archivos_recientes
  FROM archivo a
  WHERE (p_id_ot IS NULL OR a.id_ot = p_id_ot) 
    AND a.activo = TRUE 
    AND a.fecha_subida >= CURRENT_DATE - INTERVAL '7 days';
  
  -- Archivos por OT
  SELECT json_agg(
    json_build_object(
      'id_ot', id_ot,
      'cantidad', cantidad
    )
  ) INTO v_archivos_por_ot
  FROM (
    SELECT id_ot, COUNT(*) as cantidad
    FROM archivo a
    WHERE a.activo = TRUE
    GROUP BY id_ot
    ORDER BY cantidad DESC
    LIMIT 10
  ) t;
  
  RETURN QUERY SELECT 
    v_total_archivos, v_total_tamano, v_archivos_por_tipo, 
    v_archivos_recientes, v_archivos_por_ot;
END; $$ LANGUAGE plpgsql;

-- SEARCH - Buscar archivos
DROP FUNCTION IF EXISTS search_archivos(VARCHAR, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION search_archivos(
  p_search_term VARCHAR,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id INTEGER,
  id_ot INTEGER,
  nombre_archivo VARCHAR,
  nombre_original VARCHAR,
  tipo_archivo VARCHAR,
  tipo_mime VARCHAR,
  tamano_archivo BIGINT,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  fecha_modificacion TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN,
  total_count BIGINT
) AS $$
DECLARE v_total_count BIGINT;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total_count
  FROM archivo a
  WHERE a.activo = TRUE 
    AND (
      a.nombre_archivo ILIKE '%' || p_search_term || '%' OR
      a.nombre_original ILIKE '%' || p_search_term || '%' OR
      a.tipo_archivo ILIKE '%' || p_search_term || '%' OR
      a.observaciones ILIKE '%' || p_search_term || '%'
    );
  
  RETURN QUERY
  SELECT 
    a.id, a.id_ot, a.nombre_archivo, a.nombre_original, a.tipo_archivo,
    a.tipo_mime, a.tamano_archivo, a.ruta_archivo, a.fecha_subida,
    a.fecha_modificacion, a.observaciones, a.activo, v_total_count
  FROM archivo a
  WHERE a.activo = TRUE 
    AND (
      a.nombre_archivo ILIKE '%' || p_search_term || '%' OR
      a.nombre_original ILIKE '%' || p_search_term || '%' OR
      a.tipo_archivo ILIKE '%' || p_search_term || '%' OR
      a.observaciones ILIKE '%' || p_search_term || '%'
    )
  ORDER BY a.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- CLEANUP - Limpiar archivos inactivos (más de 30 días)
DROP FUNCTION IF EXISTS sp_cleanup_archivos_inactivos();
CREATE OR REPLACE FUNCTION sp_cleanup_archivos_inactivos() 
RETURNS INTEGER AS $$
DECLARE v_deleted INT;
BEGIN
  DELETE FROM archivo 
  WHERE activo = FALSE 
    AND fecha_modificacion < CURRENT_DATE - INTERVAL '30 days';
  
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END; $$ LANGUAGE plpgsql;


