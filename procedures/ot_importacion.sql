-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA OT_IMPORTACION
-- =========================================
-- Basado en el patrón de cotizacion_importacion.sql
-- Incluye operaciones CRUD completas para la relación OT-Importación

-- CREATE - Agregar importación a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_importacion(
  p_id_ot INT, p_id_importacion INT, p_cantidad INT, p_dimension VARCHAR,
  p_precio NUMERIC, p_total NUMERIC
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_importacion (
    id_ot, id_importacion, cantidad, dimension, precio, total
  ) VALUES (
    p_id_ot, p_id_importacion, COALESCE(p_cantidad,0), p_dimension,
    COALESCE(p_precio,0), COALESCE(p_total,0)
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener importación específica de una OT
CREATE OR REPLACE FUNCTION get_ot_importacion(p_id INT)
RETURNS ot_importacion AS $$
  SELECT * FROM ot_importacion WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todas las importaciones de una OT
CREATE OR REPLACE FUNCTION list_ot_importaciones(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  id_importacion INT,
  cantidad INT,
  dimension VARCHAR,
  precio NUMERIC,
  total NUMERIC,
  importacion_info JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    oi.id,
    oi.id_ot,
    oi.id_importacion,
    oi.cantidad,
    oi.dimension,
    oi.precio,
    oi.total,
    json_build_object(
      'id_importacion', i.id_importacion,
      'descripcion', i.descripcion,
      'unidad', i.unidad
    ) AS importacion_info
  FROM ot_importacion oi
  JOIN importacion i ON oi.id_importacion = i.id_importacion
  WHERE oi.id_ot = p_id_ot
  ORDER BY oi.id
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar importación de una OT
CREATE OR REPLACE FUNCTION sp_update_ot_importacion(
  p_id INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_importacion
  SET cantidad = COALESCE(p_cantidad,0),
      dimension = p_dimension,
      precio = COALESCE(p_precio,0),
      total = COALESCE(p_total,0)
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar importación de una OT
CREATE OR REPLACE FUNCTION sp_delete_ot_importacion(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_importacion WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para calcular totales de importaciones de una OT
CREATE OR REPLACE FUNCTION get_ot_importacion_totals(p_id_ot INT)
RETURNS TABLE(
  total_importaciones INT,
  subtotal_importaciones NUMERIC,
  total_general NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT AS total_importaciones,
    COALESCE(SUM(total), 0) AS subtotal_importaciones,
    COALESCE(SUM(total), 0) AS total_general
  FROM ot_importacion
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;
