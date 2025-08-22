-- UPSERT (calcula total de la línea = cantidad * precio)
CREATE OR REPLACE FUNCTION sp_add_cotizacion_material(
  p_id_cotizacion INT, p_id_material INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC
) RETURNS VOID AS $$
DECLARE v_total NUMERIC;
BEGIN
  v_total := COALESCE(p_cantidad,0) * COALESCE(p_precio,0);

  INSERT INTO cotizacion_material (id_cotizacion, id_material, cantidad, dimension, precio, total)
  VALUES (p_id_cotizacion, p_id_material, COALESCE(p_cantidad,0), p_dimension, COALESCE(p_precio,0), v_total)
  ON CONFLICT (id_cotizacion, id_material) DO UPDATE
  SET cantidad = EXCLUDED.cantidad,
      dimension = EXCLUDED.dimension,
      precio = EXCLUDED.precio,
      total = EXCLUDED.total;
END; $$ LANGUAGE plpgsql;

-- DELETE (línea)
CREATE OR REPLACE FUNCTION sp_remove_cotizacion_material(
  p_id_cotizacion INT, p_id_material INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion_material
  WHERE id_cotizacion = p_id_cotizacion AND id_material = p_id_material;
END; $$ LANGUAGE plpgsql;

-- READ (lista por cotización)
CREATE OR REPLACE FUNCTION get_cotizacion_materiales(p_id_cotizacion INT)
RETURNS TABLE(id_material INT, descripcion TEXT, cantidad INT, dimension VARCHAR, precio NUMERIC, total NUMERIC) AS $$
  SELECT cm.id_material, m.descripcion, cm.cantidad, cm.dimension, cm.precio, cm.total
  FROM cotizacion_material cm
  JOIN material m ON m.id_material = cm.id_material
  WHERE cm.id_cotizacion = p_id_cotizacion
  ORDER BY cm.id_material;
$$ LANGUAGE sql STABLE;
