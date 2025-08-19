-- CREATE
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

-- UPDATE
CREATE OR REPLACE FUNCTION sp_update_importacion(
  p_id_importacion INT, p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS VOID AS $$
BEGIN
  UPDATE importacion
  SET descripcion = p_descripcion, cantidad = COALESCE(p_cantidad,0), unidad = p_unidad
  WHERE id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;

-- READ (uno)
CREATE OR REPLACE FUNCTION get_importacion(p_id_importacion INT)
RETURNS importacion AS $$
  SELECT * FROM importacion WHERE id_importacion = p_id_importacion;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_importaciones(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF importacion AS $$
  SELECT *
  FROM importacion
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_importacion
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_importacion(p_id_importacion INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM importacion WHERE id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;
