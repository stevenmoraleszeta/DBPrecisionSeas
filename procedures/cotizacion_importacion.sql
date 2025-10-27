-- INSERT (calcula total de la línea = cantidad * precio)
-- Allows duplicate entries - same import can be added multiple times to the same cotization
CREATE OR REPLACE FUNCTION sp_add_cotizacion_importacion(
  p_id_cotizacion INT, p_id_importacion INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  v_total := COALESCE(p_cantidad,0) * COALESCE(p_precio,0);

  INSERT INTO cotizacion_importacion (id_cotizacion, id_importacion, cantidad, dimension, precio, total)
  VALUES (p_id_cotizacion, p_id_importacion, COALESCE(p_cantidad,0), p_dimension, COALESCE(p_precio,0), v_total);
END; $$ LANGUAGE plpgsql;

-- DELETE (línea por ID único)
CREATE OR REPLACE FUNCTION sp_remove_cotizacion_importacion(
  p_id INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_importacion
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- READ (lista por cotización)
CREATE OR REPLACE FUNCTION get_cotizacion_importaciones(p_id_cotizacion INT)
RETURNS TABLE(id INT, id_importacion INT, descripcion TEXT, cantidad INT, dimension VARCHAR, precio NUMERIC, total NUMERIC) AS $$
  SELECT ci.id, ci.id_importacion, i.descripcion, ci.cantidad, ci.dimension, ci.precio, ci.total
  FROM cotizacion_importacion ci
  JOIN importacion i ON i.id_importacion = ci.id_importacion
  WHERE ci.id_cotizacion = p_id_cotizacion
  ORDER BY ci.id_importacion;
$$ LANGUAGE sql STABLE;
