-- INSERT (calcula total de la línea = tiempo * tarifa)
-- Allows duplicate entries - same process can be added multiple times to the same cotization
CREATE OR REPLACE FUNCTION sp_add_cotizacion_proceso(
  p_id_cotizacion INT, p_id_proceso INT, p_tiempo INT
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  SELECT COALESCE(p_tiempo,0) * COALESCE(tarifa_x_minuto,0) INTO v_total
  FROM proceso_maquina WHERE id_proceso = p_id_proceso;

  INSERT INTO cotizacion_proceso (id_cotizacion, id_proceso, tiempo, total)
  VALUES (p_id_cotizacion, p_id_proceso, COALESCE(p_tiempo,0), v_total);
END; $$ LANGUAGE plpgsql;

-- DELETE (línea por ID único)
CREATE OR REPLACE FUNCTION sp_remove_cotizacion_proceso(
  p_id INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_proceso
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- READ (lista por cotización)
CREATE OR REPLACE FUNCTION get_cotizacion_procesos(p_id_cotizacion INT)
RETURNS TABLE(id INT, id_proceso INT, descripcion VARCHAR, tarifa_x_minuto NUMERIC, tiempo INT, total NUMERIC) AS $$
  SELECT cp.id, cp.id_proceso, pm.descripcion, pm.tarifa_x_minuto, cp.tiempo, cp.total
  FROM cotizacion_proceso cp
  JOIN proceso_maquina pm ON pm.id_proceso = cp.id_proceso
  WHERE cp.id_cotizacion = p_id_cotizacion
  ORDER BY cp.id_proceso;
$$ LANGUAGE sql STABLE;
