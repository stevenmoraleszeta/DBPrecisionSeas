-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA OT_PLANO_SOLIDO
-- =========================================
-- Maneja archivos (planos, archivos SOLID) relacionados con OT
-- Preparado para futuras funcionalidades de subida de archivos

-- CREATE - Agregar archivo a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_plano_solido(
  p_id_ot INT, p_nombre_archivo VARCHAR, p_tipo_archivo VARCHAR,
  p_ruta_archivo TEXT, p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_plano_solido (
    id_ot, nombre_archivo, tipo_archivo, ruta_archivo, observaciones
  ) VALUES (
    p_id_ot, p_nombre_archivo, p_tipo_archivo, p_ruta_archivo, p_observaciones
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener archivo específico
CREATE OR REPLACE FUNCTION get_ot_plano_solido(p_id INT)
RETURNS ot_plano_solido AS $$
  SELECT * FROM ot_plano_solido WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los archivos de una OT
CREATE OR REPLACE FUNCTION list_ot_planos_solidos(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
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
    ops.id,
    ops.id_ot,
    ops.nombre_archivo,
    ops.tipo_archivo,
    ops.ruta_archivo,
    ops.fecha_subida,
    ops.observaciones
  FROM ot_plano_solido ops
  WHERE ops.id_ot = p_id_ot
  ORDER BY ops.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- READ - Buscar archivos por tipo
CREATE OR REPLACE FUNCTION list_ot_archivos_por_tipo(
  p_id_ot INT, p_tipo_archivo VARCHAR, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
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
    ops.id,
    ops.id_ot,
    ops.nombre_archivo,
    ops.tipo_archivo,
    ops.ruta_archivo,
    ops.fecha_subida,
    ops.observaciones
  FROM ot_plano_solido ops
  WHERE ops.id_ot = p_id_ot AND ops.tipo_archivo = p_tipo_archivo
  ORDER BY ops.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar información del archivo
CREATE OR REPLACE FUNCTION sp_update_ot_plano_solido(
  p_id INT, p_nombre_archivo VARCHAR, p_tipo_archivo VARCHAR,
  p_ruta_archivo TEXT, p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_plano_solido
  SET nombre_archivo = p_nombre_archivo,
      tipo_archivo = p_tipo_archivo,
      ruta_archivo = p_ruta_archivo,
      observaciones = p_observaciones
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar archivo
CREATE OR REPLACE FUNCTION sp_delete_ot_plano_solido(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_plano_solido WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de archivos por OT
CREATE OR REPLACE FUNCTION get_ot_archivos_stats(p_id_ot INT)
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
  FROM ot_plano_solido
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;

-- Función para obtener archivos recientes
CREATE OR REPLACE FUNCTION get_ot_archivos_recientes(
  p_id_ot INT, p_dias INT DEFAULT 30
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
    ops.id,
    ops.nombre_archivo,
    ops.tipo_archivo,
    ops.fecha_subida,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ops.fecha_subida))::INT AS dias_desde_subida
  FROM ot_plano_solido ops
  WHERE ops.id_ot = p_id_ot 
    AND ops.fecha_subida >= CURRENT_TIMESTAMP - INTERVAL '1 day' * p_dias
  ORDER BY ops.fecha_subida DESC;
END; $$ LANGUAGE plpgsql;
