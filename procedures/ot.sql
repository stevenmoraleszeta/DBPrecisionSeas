-- =========================================
-- PROCEDIMIENTOS ALMACENADOS PARA OT (Orden de Trabajo)
-- =========================================
-- Basado en el patrón de cotizacion.sql
-- Incluye operaciones CRUD completas y funciones de búsqueda

-- CREATE (cabezal). Inicializa campos en valores por defecto
CREATE OR REPLACE FUNCTION sp_create_ot(
  p_num_ot VARCHAR, p_id_cotizacion INT, p_po VARCHAR, p_id_empresa INT, 
  p_id_contacto INT, p_descripcion TEXT, p_cantidad INT,
  p_estado VARCHAR, p_fecha_inicio DATE, p_fecha_fin DATE, p_prioridad VARCHAR,
  p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id_ot INT;
BEGIN
  INSERT INTO ot (
    num_ot, id_cotizacion, po, id_empresa, id_contacto, descripcion, cantidad,
    estado, fecha_inicio, fecha_fin, prioridad, observaciones
  ) VALUES (
    p_num_ot, p_id_cotizacion, p_po, p_id_empresa, p_id_contacto, p_descripcion,
    COALESCE(p_cantidad,0), COALESCE(p_estado,'Pendiente'),
    p_fecha_inicio, p_fecha_fin, COALESCE(p_prioridad,'Normal'), p_observaciones
  ) RETURNING id_ot INTO v_id_ot;
  
  RETURN v_id_ot;
END; $$ LANGUAGE plpgsql;

-- UPDATE (cabezal, sin tocar campos calculados)
CREATE OR REPLACE FUNCTION sp_update_ot_info(
  p_id_ot INT, p_id_cotizacion INT, p_po VARCHAR, p_id_empresa INT, 
  p_id_contacto INT, p_descripcion TEXT, p_cantidad INT,
  p_estado VARCHAR, p_fecha_inicio DATE, p_fecha_fin DATE, p_prioridad VARCHAR,
  p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE ot
  SET id_cotizacion = p_id_cotizacion, po = p_po, id_empresa = p_id_empresa,
      id_contacto = p_id_contacto, descripcion = p_descripcion, 
      cantidad = COALESCE(p_cantidad,0),
      estado = COALESCE(p_estado,'Pendiente'), fecha_inicio = p_fecha_inicio,
      fecha_fin = p_fecha_fin, prioridad = COALESCE(p_prioridad,'Normal'),
      observaciones = p_observaciones
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;

-- READ (uno por id_ot)
CREATE OR REPLACE FUNCTION get_ot(p_id_ot INT)
RETURNS ot AS $$
  SELECT * FROM ot WHERE id_ot = p_id_ot;
$$ LANGUAGE sql STABLE;

-- READ (uno por num_ot)
CREATE OR REPLACE FUNCTION get_ot_by_num(p_num_ot VARCHAR)
RETURNS ot AS $$
  SELECT * FROM ot WHERE num_ot = p_num_ot;
$$ LANGUAGE sql STABLE;

-- READ (lista con información relacionada)
CREATE OR REPLACE FUNCTION list_ots(
  p_id_empresa INT DEFAULT NULL, p_id_cotizacion INT DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL, p_search TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id_ot INT,
  num_ot VARCHAR,
  id_cotizacion INT,
  po VARCHAR,
  id_empresa INT,
  id_contacto INT,
  descripcion TEXT,
  cantidad INT,

  estado VARCHAR,
  fecha_inicio DATE,
  fecha_fin DATE,
  prioridad VARCHAR,
  observaciones TEXT,
  empresa JSON,
  contacto JSON,
  cotizacion JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id_ot,
    o.num_ot,
    o.id_cotizacion,
    o.po,
    o.id_empresa,
    o.id_contacto,
    o.descripcion,
    o.cantidad,

    o.estado,
    o.fecha_inicio,
    o.fecha_fin,
    o.prioridad,
    o.observaciones,
    CASE 
      WHEN e.id_empresa IS NOT NULL THEN 
        json_build_object(
          'id_empresa', e.id_empresa,
          'cod_empresa', e.cod_empresa,
          'nombre_empresa', e.nombre_empresa
        )
      ELSE NULL
    END AS empresa,
    CASE 
      WHEN c.id_contacto IS NOT NULL THEN 
        json_build_object(
          'id_contacto', c.id_contacto,
          'nombre_contacto', c.nombre_contacto,
          'email', c.email
        )
      ELSE NULL
    END AS contacto,
    CASE 
      WHEN co.id_cotizacion IS NOT NULL THEN 
        json_build_object(
          'id_cotizacion', co.id_cotizacion,
          'num_cotizacion', co.num_cotizacion,
          'desc_servicio', co.desc_servicio
        )
      ELSE NULL
    END AS cotizacion
  FROM ot o
  LEFT JOIN empresa e ON o.id_empresa = e.id_empresa
  LEFT JOIN contacto c ON o.id_contacto = c.id_contacto
  LEFT JOIN cotizacion co ON o.id_cotizacion = co.id_cotizacion
  WHERE (p_id_empresa IS NULL OR o.id_empresa = p_id_empresa)
    AND (p_id_cotizacion IS NULL OR o.id_cotizacion = p_id_cotizacion)
    AND (p_estado IS NULL OR o.estado = p_estado)
    AND (p_search IS NULL OR 
         o.num_ot ILIKE '%' || p_search || '%' OR
         o.po ILIKE '%' || p_search || '%' OR
         o.descripcion ILIKE '%' || p_search || '%')
  ORDER BY o.id_ot DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- DELETE (elimina OT y todas sus relaciones)
CREATE OR REPLACE FUNCTION sp_delete_ot(p_id_ot INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot WHERE id_ot = p_id_ot;
  -- Las tablas relacionales se eliminan automáticamente por CASCADE
END; $$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de OT
CREATE OR REPLACE FUNCTION get_ot_stats(
  p_id_empresa INT DEFAULT NULL
) RETURNS TABLE(
  total_ots INT,
  pendientes INT,
  en_progreso INT,
  completadas INT,
  canceladas INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT AS total_ots,
    COUNT(CASE WHEN estado = 'Pendiente' THEN 1 END)::INT AS pendientes,
    COUNT(CASE WHEN estado = 'En Progreso' THEN 1 END)::INT AS en_progreso,
    COUNT(CASE WHEN estado = 'Completada' THEN 1 END)::INT AS completadas,
    COUNT(CASE WHEN estado = 'Cancelada' THEN 1 END)::INT AS canceladas
  FROM ot
  WHERE (p_id_empresa IS NULL OR id_empresa = p_id_empresa);
END; $$ LANGUAGE plpgsql;

-- Función para buscar OT por número de cotización
CREATE OR REPLACE FUNCTION get_ots_by_cotizacion(p_id_cotizacion INT)
RETURNS TABLE(
  id_ot INT,
  num_ot VARCHAR,
  po VARCHAR,
  estado VARCHAR,
  fecha_inicio DATE,
  fecha_fin DATE,
  prioridad VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id_ot,
    o.num_ot,
    o.po,
    o.estado,
    o.fecha_inicio,
    o.fecha_fin,
    o.prioridad
  FROM ot o
  WHERE o.id_cotizacion = p_id_cotizacion
  ORDER BY o.id_ot DESC;
END; $$ LANGUAGE plpgsql;
