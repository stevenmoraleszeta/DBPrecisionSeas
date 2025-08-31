-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA REGISTRO_TIEMPO
-- =========================================
-- Maneja el control de tiempo de colaboradores (pueden estar asociados a OT o ser independientes)
-- Permite registrar bloques de trabajo y calcular tiempo total

-- CREATE - Registrar tiempo de trabajo
CREATE OR REPLACE FUNCTION sp_create_registro_tiempo(
  p_id_ot INT DEFAULT NULL, p_id_colaborador INT, p_fecha_inicio TIMESTAMP,
  p_fecha_fin TIMESTAMP, p_tiempo_trabajado INT, p_descripcion TEXT, p_estado VARCHAR
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

-- READ - Obtener registro específico
CREATE OR REPLACE FUNCTION get_registro_tiempo(p_id INT)
RETURNS registro_tiempo AS $$
  SELECT * FROM registro_tiempo WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los registros de tiempo de una OT (si se proporciona id_ot) o todos los registros independientes
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

-- READ - Listar registros por colaborador
CREATE OR REPLACE FUNCTION list_registros_por_colaborador(
  p_id_colaborador INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
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

-- READ - Listar registros por estado
CREATE OR REPLACE FUNCTION list_registros_por_estado(
  p_id_ot INT DEFAULT NULL, p_estado VARCHAR, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
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

-- UPDATE - Actualizar registro de tiempo
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

-- UPDATE - Marcar registro como completado
CREATE OR REPLACE FUNCTION sp_completar_registro_tiempo(
  p_id INT, p_fecha_fin TIMESTAMP, p_tiempo_trabajado INT
) RETURNS VOID AS $$
BEGIN
  UPDATE registro_tiempo
  SET fecha_fin = p_fecha_fin,
      tiempo_trabajado = COALESCE(p_tiempo_trabajado,0),
      estado = 'Completado'
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar registro de tiempo
CREATE OR REPLACE FUNCTION sp_delete_registro_tiempo(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM registro_tiempo WHERE id = p_id;
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
