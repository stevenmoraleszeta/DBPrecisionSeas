-- CREATE (cabezal). Inicializa montos en 0; la app los actualizará.
CREATE OR REPLACE FUNCTION sp_create_cotizacion(
  p_num_cotizacion VARCHAR, p_id_empresa INT, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR
) RETURNS INT AS $$
DECLARE v_id_cotizacion INT;
BEGIN
  INSERT INTO cotizacion (
    num_cotizacion, id_empresa, id_contacto, direccion, telefono, desc_servicio, cantidad,
    moneda, validez_oferta, tiempo_entrega, forma_pago,
    subtotal, descuento, iva, total, observa_cliente, observa_interna
  ) VALUES (
    p_num_cotizacion, p_id_empresa, p_id_contacto, p_direccion, p_telefono, p_desc_servicio,
    COALESCE(p_cantidad,0), p_moneda, p_validez_oferta, p_tiempo_entrega, p_forma_pago,
    0, 0, 0, 0, NULL, NULL
  ) RETURNING id_cotizacion INTO v_id_cotizacion;
  
  RETURN v_id_cotizacion;
END; $$ LANGUAGE plpgsql;

-- UPDATE (cabezal, sin tocar montos)
CREATE OR REPLACE FUNCTION sp_update_cotizacion_info(
  p_id_cotizacion INT, p_id_empresa INT, p_id_contacto INT,
  p_direccion TEXT, p_telefono VARCHAR, p_desc_servicio TEXT, p_cantidad INT,
  p_moneda VARCHAR, p_validez_oferta VARCHAR, p_tiempo_entrega VARCHAR, p_forma_pago VARCHAR,
  p_observa_cliente TEXT, p_observa_interna TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET id_empresa = p_id_empresa, id_contacto = p_id_contacto, direccion = p_direccion,
      telefono = p_telefono, desc_servicio = p_desc_servicio, cantidad = COALESCE(p_cantidad,0),
      moneda = p_moneda, validez_oferta = p_validez_oferta, tiempo_entrega = p_tiempo_entrega,
      forma_pago = p_forma_pago, observa_cliente = p_observa_cliente, observa_interna = p_observa_interna
  WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;

-- READ (uno por id_cotizacion)
CREATE OR REPLACE FUNCTION get_cotizacion(p_id_cotizacion INT)
RETURNS cotizacion AS $$
  SELECT * FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
$$ LANGUAGE sql STABLE;

-- READ (uno por num_cotizacion)
CREATE OR REPLACE FUNCTION get_cotizacion_by_num(p_num_cotizacion VARCHAR)
RETURNS cotizacion AS $$
  SELECT * FROM cotizacion WHERE num_cotizacion = p_num_cotizacion;
$$ LANGUAGE sql STABLE;

-- READ (lista)
CREATE OR REPLACE FUNCTION list_cotizaciones(
  p_id_empresa INT DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id_cotizacion INT,
  num_cotizacion VARCHAR,
  id_empresa INT,
  id_contacto INT,
  direccion TEXT,
  telefono VARCHAR,
  desc_servicio TEXT,
  cantidad INT,
  moneda VARCHAR,
  validez_oferta VARCHAR,
  tiempo_entrega VARCHAR,
  forma_pago VARCHAR,
  subtotal NUMERIC,
  descuento NUMERIC,
  iva NUMERIC,
  total NUMERIC,
  observa_cliente TEXT,
  observa_interna TEXT,
  empresa JSON,
  contacto JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id_cotizacion,
    c.num_cotizacion,
    c.id_empresa,
    c.id_contacto,
    c.direccion,
    c.telefono,
    c.desc_servicio,
    c.cantidad,
    c.moneda,
    c.validez_oferta,
    c.tiempo_entrega,
    c.forma_pago,
    c.subtotal,
    c.descuento,
    c.iva,
    c.total,
    c.observa_cliente,
    c.observa_interna,
    CASE 
      WHEN e.id_empresa IS NOT NULL THEN 
        json_build_object(
          'id_empresa', e.id_empresa,
          'nombre_empresa', e.nombre_empresa,
          'cod_empresa', e.cod_empresa
        )
      ELSE NULL
    END as empresa,
    CASE 
      WHEN co.id_contacto IS NOT NULL THEN 
        json_build_object(
          'id_contacto', co.id_contacto,
          'nombre_contacto', co.nombre_contacto,
          'puesto', co.puesto
        )
      ELSE NULL
    END as contacto
  FROM cotizacion c
  LEFT JOIN empresa e ON c.id_empresa = e.id_empresa
  LEFT JOIN contacto co ON c.id_contacto = co.id_contacto
  WHERE (p_id_empresa IS NULL OR c.id_empresa = p_id_empresa)
    AND (p_search IS NULL OR (c.num_cotizacion ILIKE '%'||p_search||'%' OR c.desc_servicio ILIKE '%'||p_search||'%'))
  ORDER BY c.num_cotizacion DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- DELETE (cabezal; detalles caen por ON DELETE CASCADE)
CREATE OR REPLACE FUNCTION sp_delete_cotizacion(p_id_cotizacion INT)
RETURNS VOID AS $$
BEGIN
  DELETE FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;

-- Setters simples de montos (la app calcula; aquí solo se guardan)
CREATE OR REPLACE FUNCTION sp_set_montos_cotizacion(
  p_id_cotizacion INT, p_subtotal NUMERIC, p_descuento NUMERIC, p_iva NUMERIC, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE cotizacion
  SET subtotal = COALESCE(p_subtotal,0),
      descuento = COALESCE(p_descuento,0),
      iva = COALESCE(p_iva,0),
      total = COALESCE(p_total,0)
  WHERE id_cotizacion = p_id_cotizacion;
END; $$ LANGUAGE plpgsql;
