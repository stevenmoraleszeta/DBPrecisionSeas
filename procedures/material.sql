-- CREATE
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

-- UPDATE
CREATE OR REPLACE FUNCTION sp_update_material(
  p_id_material INT, p_descripcion TEXT, p_cantidad INT, p_unidad VARCHAR
) RETURNS VOID AS $$
BEGIN
  UPDATE material
  SET descripcion = p_descripcion, cantidad = COALESCE(p_cantidad,0), unidad = p_unidad
  WHERE id_material = p_id_material;
END; $$ LANGUAGE plpgsql;

-- READ (uno)
CREATE OR REPLACE FUNCTION get_material(p_id_material INT)
RETURNS material AS $$
  SELECT * FROM material WHERE id_material = p_id_material;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_materiales(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF material AS $$
  SELECT *
  FROM material
  WHERE p_search IS NULL OR descripcion ILIKE '%'||p_search||'%'
  ORDER BY id_material
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_material(p_id_material INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM material WHERE id_material = p_id_material;
END; $$ LANGUAGE plpgsql;
