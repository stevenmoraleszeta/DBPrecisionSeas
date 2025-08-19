-- UPSERT (total = tiempo * tarifa vigente del proceso)
CREATE OR REPLACE FUNCTION sp_add_cotizacion_proceso(
  p_num_cotizacion VARCHAR, p_id_proceso INT, p_tiempo_min INT
) RETURNS VOID AS $$
DECLARE v_tarifa NUMERIC := 0; v_total NUMERIC := 0;
BEGIN
  SELECT tarifa_x_minuto INTO v_tarifa FROM proceso_maquina WHERE id_proceso = p_id_proceso;
  v_total := COALESCE(p_tiempo_min,0) * COALESCE(v_tarifa,0);

  INSERT INTO cotizacion_proceso (num_cotizacion, id_proceso, tiempo, total)
  VALUES (p_num_cotizacion, p_id_proceso, COALESCE(p_tiempo_min,0), v_total)
  ON CONFLICT (num_cotizacion, id_proceso) DO UPDATE
  SET tiempo = EXCLUDED.tiempo, total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

-- DELETE (línea)
CREATE OR REPLACE FUNCTION sp_remove_cotizacion_proceso(
  p_num_cotizacion VARCHAR, p_id_proceso INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_proceso
  WHERE num_cotizacion = p_num_cotizacion AND id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;

-- READ (lista por cotización)
CREATE OR REPLACE FUNCTION get_cotizacion_procesos(p_num_cotizacion VARCHAR)
RETURNS TABLE(id_proceso INT, descripcion VARCHAR, tiempo INT, tarifa_x_minuto NUMERIC, total NUMERIC) AS $$
  SELECT cp.id_proceso, p.descripcion, cp.tiempo, p.tarifa_x_minuto, cp.total
  FROM cotizacion_proceso cp
  JOIN proceso_maquina p ON p.id_proceso = cp.id_proceso
  WHERE cp.num_cotizacion = p_num_cotizacion
  ORDER BY cp.id_proceso;
$$ LANGUAGE sql STABLE;
