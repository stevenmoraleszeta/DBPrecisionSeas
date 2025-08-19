-- CREATE
CREATE OR REPLACE FUNCTION sp_create_contacto(
  p_cod_empresa VARCHAR, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO contacto (cod_empresa, nombre_contacto, telefono, email, puesto, notas)
  VALUES (p_cod_empresa, p_nombre_contacto, p_telefono, p_email, p_puesto, p_notas)
  RETURNING id_contacto INTO v_id;
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- UPDATE
CREATE OR REPLACE FUNCTION sp_update_contacto(
  p_id_contacto INT, p_cod_empresa VARCHAR, p_nombre_contacto VARCHAR, p_telefono VARCHAR,
  p_email VARCHAR, p_puesto VARCHAR, p_notas TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE contacto
  SET cod_empresa = p_cod_empresa, nombre_contacto = p_nombre_contacto, telefono = p_telefono,
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
  p_cod_empresa VARCHAR DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF contacto AS $$
  SELECT *
  FROM contacto
  WHERE (p_cod_empresa IS NULL OR cod_empresa = p_cod_empresa)
    AND (p_search IS NULL OR (nombre_contacto ILIKE '%'||p_search||'%' OR email ILIKE '%'||p_search||'%'))
  ORDER BY nombre_contacto
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_contacto(p_id_contacto INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM contacto WHERE id_contacto = p_id_contacto;
END; $$ LANGUAGE plpgsql;
