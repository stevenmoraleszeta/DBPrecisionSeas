-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA OT_MATERIAL
-- =========================================
-- Basado en el patrón de cotizacion_material.sql
-- Incluye operaciones CRUD completas para la relación OT-Material

-- CREATE - Agregar material a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_material(
  p_id_ot INT, p_id_material INT, p_cantidad INT, p_dimension VARCHAR,
  p_precio NUMERIC, p_total NUMERIC
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_material (
    id_ot, id_material, cantidad, dimension, precio, total
  ) VALUES (
    p_id_ot, p_id_material, COALESCE(p_cantidad,0), p_dimension,
    COALESCE(p_precio,0), COALESCE(p_total,0)
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener material específico de una OT
CREATE OR REPLACE FUNCTION get_ot_material(p_id INT)
RETURNS ot_material AS $$
  SELECT * FROM ot_material WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los materiales de una OT
CREATE OR REPLACE FUNCTION list_ot_materials(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  id_material INT,
  cantidad INT,
  dimension VARCHAR,
  precio NUMERIC,
  total NUMERIC,
  material_info JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    om.id,
    om.id_ot,
    om.id_material,
    om.cantidad,
    om.dimension,
    om.precio,
    om.total,
    json_build_object(
      'id_material', m.id_material,
      'descripcion', m.descripcion,
      'unidad', m.unidad
    ) AS material_info
  FROM ot_material om
  JOIN material m ON om.id_material = m.id_material
  WHERE om.id_ot = p_id_ot
  ORDER BY om.id
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar material de una OT
CREATE OR REPLACE FUNCTION sp_update_ot_material(
  p_id INT, p_cantidad INT, p_dimension VARCHAR, p_precio NUMERIC, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_material
  SET cantidad = COALESCE(p_cantidad,0),
      dimension = p_dimension,
      precio = COALESCE(p_precio,0),
      total = COALESCE(p_total,0)
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar material de una OT
CREATE OR REPLACE FUNCTION sp_delete_ot_material(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_material WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para calcular totales de materiales de una OT
CREATE OR REPLACE FUNCTION get_ot_material_totals(p_id_ot INT)
RETURNS TABLE(
  total_materiales INT,
  subtotal_materiales NUMERIC,
  total_general NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT AS total_materiales,
    COALESCE(SUM(total), 0) AS subtotal_materiales,
    COALESCE(SUM(total), 0) AS total_general
  FROM ot_material
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;
