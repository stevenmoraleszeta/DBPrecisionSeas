-- UPSERT
CREATE OR REPLACE FUNCTION sp_upsert_empresa(
  p_cod_empresa VARCHAR, p_nombre VARCHAR, p_direccion TEXT, p_telefono VARCHAR,
  p_email_factura VARCHAR, p_cedula VARCHAR, p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id_empresa INT;
BEGIN
  INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones)
  VALUES (p_cod_empresa, p_nombre, p_direccion, p_telefono, p_email_factura, p_cedula, p_observaciones)
  ON CONFLICT (cod_empresa) DO UPDATE
  SET nombre_empresa = EXCLUDED.nombre_empresa,
      direccion      = EXCLUDED.direccion,
      telefono       = EXCLUDED.telefono,
      email_factura  = EXCLUDED.email_factura,
      cedula         = EXCLUDED.cedula,
      observaciones  = EXCLUDED.observaciones
  RETURNING id_empresa INTO v_id_empresa;
  
  RETURN v_id_empresa;
END; $$ LANGUAGE plpgsql;

-- UPDATE (por ID)
CREATE OR REPLACE FUNCTION sp_update_empresa(
  p_id_empresa INT, p_cod_empresa VARCHAR, p_nombre VARCHAR, p_direccion TEXT, 
  p_telefono VARCHAR, p_email_factura VARCHAR, p_cedula VARCHAR, p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE empresa 
  SET cod_empresa = p_cod_empresa,
      nombre_empresa = p_nombre,
      direccion = p_direccion,
      telefono = p_telefono,
      email_factura = p_email_factura,
      cedula = p_cedula,
      observaciones = p_observaciones
  WHERE id_empresa = p_id_empresa;
  
  -- Verificar que se actualizó al menos una fila
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Empresa con ID % no encontrada', p_id_empresa;
  END IF;
END; $$ LANGUAGE plpgsql;

-- READ (uno por cod_empresa)
CREATE OR REPLACE FUNCTION get_empresa_by_cod(p_cod_empresa VARCHAR)
RETURNS empresa AS $$
  SELECT * FROM empresa WHERE cod_empresa = p_cod_empresa;
$$ LANGUAGE sql STABLE;

-- READ (uno por id_empresa)
CREATE OR REPLACE FUNCTION get_empresa(p_id_empresa INT)
RETURNS empresa AS $$
  SELECT * FROM empresa WHERE id_empresa = p_id_empresa;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_empresas(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF empresa AS $$
  SELECT *
  FROM empresa
  WHERE p_search IS NULL
     OR (cod_empresa ILIKE '%'||p_search||'%' OR nombre_empresa ILIKE '%'||p_search||'%')
  ORDER BY nombre_empresa NULLS LAST, cod_empresa
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE
CREATE OR REPLACE FUNCTION sp_delete_empresa(p_id_empresa INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM empresa WHERE id_empresa = p_id_empresa;
END; $$ LANGUAGE plpgsql;
