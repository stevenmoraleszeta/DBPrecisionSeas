-- UPSERT
CREATE OR REPLACE FUNCTION sp_add_cotizacion_importacion(
  p_num_cotizacion VARCHAR, p_id_importacion INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  v_total := COALESCE(p_cantidad,0) * COALESCE(p_precio,0);

  INSERT INTO cotizacion_importacion (num_cotizacion, id_importacion, cantidad, dimension, precio, total)
  VALUES (p_num_cotizacion, p_id_importacion, COALESCE(p_cantidad,0), p_dimension, COALESCE(p_precio,0), v_total)
  ON CONFLICT (num_cotizacion, id_importacion) DO UPDATE
  SET cantidad = EXCLUDED.cantidad,
      dimension = EXCLUDED.dimension,
      precio = EXCLUDED.precio,
      total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

-- DELETE (línea)
CREATE OR REPLACE FUNCTION sp_remove_cotizacion_importacion(
  p_num_cotizacion VARCHAR, p_id_importacion INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_importacion
  WHERE num_cotizacion = p_num_cotizacion AND id_importacion = p_id_importacion;
END; $$ LANGUAGE plpgsql;

-- READ (lista por cotización)
CREATE OR REPLACE FUNCTION get_cotizacion_importaciones(p_num_cotizacion VARCHAR)
RETURNS TABLE(id_importacion INT, descripcion TEXT, cantidad INT, dimension VARCHAR, precio NUMERIC, total NUMERIC) AS $$
  SELECT ci.id_importacion, i.descripcion, ci.cantidad, ci.dimension, ci.precio, ci.total
  FROM cotizacion_importacion ci
  JOIN importacion i ON i.id_importacion = ci.id_importacion
  WHERE ci.num_cotizacion = p_num_cotizacion
  ORDER BY ci.id_importacion;
$$ LANGUAGE sql STABLE;
