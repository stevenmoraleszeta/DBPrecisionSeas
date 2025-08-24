-- CREATE
CREATE OR REPLACE FUNCTION sp_create_contacto(
  p_id_empresa INT, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas)
  VALUES (p_id_empresa, p_nombre_contacto, p_telefono, p_email, p_puesto, p_notas)
  RETURNING id_contacto INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- UPDATE
CREATE OR REPLACE FUNCTION sp_update_contacto(
  p_id_contacto INT, p_id_empresa INT, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE contacto
  SET id_empresa = p_id_empresa, nombre_contacto = p_nombre_contacto, telefono = p_telefono,
      email = p_email, puesto = p_puesto, notas = p_notas
  WHERE id_contacto = p_id_contacto;
END; $$ LANGUAGE plpgsql;

-- READ (uno)
CREATE OR REPLACE FUNCTION get_contacto(p_id_contacto INT)
RETURNS contacto AS $$
  SELECT * FROM contacto WHERE id_contacto = p_id_contacto;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_contactos(
  p_id_empresa INT DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF contacto AS $$
  SELECT *
  FROM contacto
  WHERE (p_id_empresa IS NULL OR id_empresa = p_id_empresa)
    AND (p_search IS NULL OR (nombre_contacto ILIKE '%'||p_search||'%' OR email ILIKE '%'||p_search||'%'))
  ORDER BY nombre_contacto
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- READ (lista con datos de empresa)
CREATE OR REPLACE FUNCTION list_contactos_with_empresa(
  p_id_empresa INT DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE (
  id_contacto INT,
  id_empresa INT,
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
    c.id_contacto,
    c.id_empresa,
    c.nombre_contacto,
    c.telefono,
    c.email,
    c.puesto,
    c.notas,
    CASE 
      WHEN c.id_empresa IS NOT NULL THEN
        json_build_object(
          'id_empresa', e.id_empresa,
          'nombre_empresa', e.nombre_empresa
        )
      ELSE NULL
    END as empresa
  FROM contacto c
  LEFT JOIN empresa e ON c.id_empresa = e.id_empresa
  WHERE (p_id_empresa IS NULL OR c.id_empresa = p_id_empresa)
    AND (p_search IS NULL OR (c.nombre_contacto ILIKE '%'||p_search||'%' OR c.email ILIKE '%'||p_search||'%'))
  ORDER BY c.nombre_contacto
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_contacto(p_id_contacto INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM contacto WHERE id_contacto = p_id_contacto;
END; $$ LANGUAGE plpgsql;
