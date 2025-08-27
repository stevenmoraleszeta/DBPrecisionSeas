-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA OT_PROCESO
-- =========================================
-- Basado en el patrón de cotizacion_proceso.sql
-- Incluye operaciones CRUD completas para la relación OT-Proceso

-- CREATE - Agregar proceso a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_proceso(
  p_id_ot INT, p_id_proceso INT, p_tiempo INT, p_total NUMERIC
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_proceso (
    id_ot, id_proceso, tiempo, total
  ) VALUES (
    p_id_ot, p_id_proceso, COALESCE(p_tiempo,0), COALESCE(p_total,0)
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener proceso específico de una OT
CREATE OR REPLACE FUNCTION get_ot_proceso(p_id INT)
RETURNS ot_proceso AS $$
  SELECT * FROM ot_proceso WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los procesos de una OT
CREATE OR REPLACE FUNCTION list_ot_procesos(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  id_proceso INT,
  tiempo INT,
  total NUMERIC,
  proceso_info JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    op.id,
    op.id_ot,
    op.id_proceso,
    op.tiempo,
    op.total,
    json_build_object(
      'id_proceso', pm.id_proceso,
      'descripcion', pm.descripcion,
      'tarifa_x_minuto', pm.tarifa_x_minuto
    ) AS proceso_info
  FROM ot_proceso op
  JOIN proceso_maquina pm ON op.id_proceso = pm.id_proceso
  WHERE op.id_ot = p_id_ot
  ORDER BY op.id
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar proceso de una OT
CREATE OR REPLACE FUNCTION sp_update_ot_proceso(
  p_id INT, p_tiempo INT, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_proceso
  SET tiempo = COALESCE(p_tiempo,0),
      total = COALESCE(p_total,0)
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar proceso de una OT
CREATE OR REPLACE FUNCTION sp_delete_ot_proceso(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_proceso WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para calcular totales de procesos de una OT
CREATE OR REPLACE FUNCTION get_ot_proceso_totals(p_id_ot INT)
RETURNS TABLE(
  total_procesos INT,
  tiempo_total INT,
  subtotal_procesos NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT AS total_procesos,
    COALESCE(SUM(tiempo), 0) AS tiempo_total,
    COALESCE(SUM(total), 0) AS subtotal_procesos
  FROM ot_proceso
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;

-- Función para calcular tiempo total en horas y minutos
CREATE OR REPLACE FUNCTION get_ot_tiempo_formateado(p_id_ot INT)
RETURNS TABLE(
  tiempo_total_minutos INT,
  tiempo_horas INT,
  tiempo_minutos INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(tiempo), 0) AS tiempo_total_minutos,
    (COALESCE(SUM(tiempo), 0) / 60)::INT AS tiempo_horas,
    (COALESCE(SUM(tiempo), 0) % 60)::INT AS tiempo_minutos
  FROM ot_proceso
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;
