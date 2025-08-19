-- CREATE (cabezal). Inicializa montos en 0; la app los actualizará.
CREATE OR REPLACE FUNCTION sp_create_cotizacion(
  p_num_cotizacion VARCHAR, p_cod_empresa VARCHAR, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR
) RETURNS VOID AS $$
BEGIN
  INSERT INTO cotizacion (
    num_cotizacion, cod_empresa, id_contacto, direccion, telefono, desc_servicio, cantidad,
    moneda, validez_oferta, tiempo_entrega, forma_pago,
    subtotal, descuento, iva, total, observa_cliente, observa_interna
  ) VALUES (
    p_num_cotizacion, p_cod_empresa, p_id_contacto, p_direccion, p_telefono, p_desc_servicio,
    COALESCE(p_cantidad,0), p_moneda, p_validez_oferta, p_tiempo_entrega, p_forma_pago,
    0, 0, 0, 0, NULL, NULL
  );
END; $$ LANGUAGE plpgsql;

-- UPDATE (cabezal, sin tocar montos)
CREATE OR REPLACE FUNCTION sp_update_cotizacion_info(
  p_num_cotizacion VARCHAR, p_cod_empresa VARCHAR, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR,
  p_observa_cliente TEXT, p_observa_interna TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET cod_empresa = p_cod_empresa, id_contacto = p_id_contacto, direccion = p_direccion,
      telefono = p_telefono, desc_servicio = p_desc_servicio, cantidad = COALESCE(p_cantidad,0),
      moneda = p_moneda, validez_oferta = p_validez_oferta, tiempo_entrega = p_tiempo_entrega,
      forma_pago = p_forma_pago, observa_cliente = p_observa_cliente, observa_interna = p_observa_interna
  WHERE num_cotizacion = p_num_cotizacion;
END; $$ LANGUAGE plpgsql;

-- READ (uno)
CREATE OR REPLACE FUNCTION get_cotizacion(p_num_cotizacion VARCHAR)
RETURNS cotizacion AS $$
  SELECT * FROM cotizacion WHERE num_cotizacion = p_num_cotizacion;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_cotizaciones(
  p_cod_empresa VARCHAR DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS SETOF cotizacion AS $$
  SELECT *
  FROM cotizacion
  WHERE (p_cod_empresa IS NULL OR cod_empresa = p_cod_empresa)
    AND (p_search IS NULL OR (num_cotizacion ILIKE '%'||p_search||'%' OR desc_servicio ILIKE '%'||p_search||'%'))
  ORDER BY num_cotizacion DESC
  LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- DELETE (cabezal; detalles caen por ON DELETE CASCADE)
CREATE OR REPLACE FUNCTION sp_delete_cotizacion(p_num_cotizacion VARCHAR)
RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion WHERE num_cotizacion = p_num_cotizacion;
END; $$ LANGUAGE plpgsql;

-- Setters simples de montos (la app calcula; aquí solo se guardan)
CREATE OR REPLACE FUNCTION sp_set_montos_cotizacion(
  p_num_cotizacion VARCHAR, p_subtotal NUMERIC, p_descuento NUMERIC, p_iva NUMERIC, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET subtotal = COALESCE(p_subtotal,0),
      descuento = COALESCE(p_descuento,0),
      iva = COALESCE(p_iva,0),
      total = COALESCE(p_total,0)
  WHERE num_cotizacion = p_num_cotizacion;
END; $$ LANGUAGE plpgsql;
