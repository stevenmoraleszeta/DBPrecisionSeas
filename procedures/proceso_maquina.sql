-- CREATE
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

-- UPDATE
CREATE OR REPLACE FUNCTION sp_update_proceso(
  p_id_proceso INT, p_descripcion VARCHAR, p_tarifa_x_minuto NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE proceso_maquina
  SET descripcion = p_descripcion, tarifa_x_minuto = COALESCE(p_tarifa_x_minuto,0)
  WHERE id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;

-- READ (uno)
CREATE OR REPLACE FUNCTION get_proceso(p_id_proceso INT)
RETURNS proceso_maquina AS $$
  SELECT * FROM proceso_maquina WHERE id_proceso = p_id_proceso;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_procesos(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF proceso_maquina AS $$
  SELECT *
  FROM proceso_maquina
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_proceso
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_proceso(p_id_proceso INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM proceso_maquina WHERE id_proceso = p_id_proceso;
END; $$ LANGUAGE plpgsql;
