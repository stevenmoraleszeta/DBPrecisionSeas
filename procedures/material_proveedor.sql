-- material_proveedor: funciones (la tabla está en create.sql)

-- Lista con join de datos de contacto y empresa (para UI sin columna empresa visible)
CREATE OR REPLACE FUNCTION list_material_proveedores(
  p_id_material INT,
  p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 100,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id INT,
  id_material INT,
  id_contacto INT,
  nombre_contacto VARCHAR,
  telefono VARCHAR,
  email VARCHAR,
  puesto VARCHAR,
  notas TEXT,
  empresa JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mp.id,
    mp.id_material,
    c.id_contacto,
    c.nombre_contacto,
    c.telefono,
    c.email,
    c.puesto,
    mp.notas,
    CASE WHEN c.id_empresa IS NOT NULL THEN json_build_object(
      'id_empresa', e.id_empresa,
      'nombre_empresa', e.nombre_empresa
    ) ELSE NULL END AS empresa
  FROM material_proveedor mp
  JOIN contacto c ON c.id_contacto = mp.id_contacto
  LEFT JOIN empresa e ON e.id_empresa = c.id_empresa
  WHERE mp.id_material = p_id_material
    AND (
      p_search IS NULL OR 
      c.nombre_contacto ILIKE '%'||p_search||'%' OR
      c.email ILIKE '%'||p_search||'%'
    )
  ORDER BY c.nombre_contacto
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql STABLE;

-- Crear vínculo (requiere que el contacto exista)
CREATE OR REPLACE FUNCTION sp_create_material_proveedor(
  p_id_material INT,
  p_id_contacto INT,
  p_notas TEXT DEFAULT NULL
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO material_proveedor (id_material, id_contacto, notas)
  VALUES (p_id_material, p_id_contacto, p_notas)
  RETURNING id INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- Actualizar vínculo (cambiar contacto o notas)
CREATE OR REPLACE FUNCTION sp_update_material_proveedor(
  p_id INT,
  p_id_contacto INT,
  p_notas TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  UPDATE material_proveedor
  SET id_contacto = p_id_contacto,
      notas = p_notas
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Eliminar vínculo
CREATE OR REPLACE FUNCTION sp_delete_material_proveedor(
  p_id INT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM material_proveedor WHERE id = p_id;
END; $$ LANGUAGE plpgsql;


