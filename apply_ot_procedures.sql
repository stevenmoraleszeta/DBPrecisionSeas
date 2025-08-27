-- =========================================
-- APLICAR PROCEDIMIENTOS ALMACENADOS DE OT
-- =========================================
-- Este archivo crea todos los procedimientos almacenados para la sección OT
-- Ejecutar después de apply_ot_changes.sql

-- =========================================
-- VERIFICACIÓN DE TABLAS OT
-- =========================================

DO $$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  RAISE NOTICE '🔍 Verificando tablas de OT...';
  
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'ot'
  ) INTO v_table_exists;
  
  IF NOT v_table_exists THEN
    RAISE EXCEPTION '❌ La tabla "ot" no existe. Ejecuta primero apply_ot_changes.sql para crear las tablas.';
  END IF;
  
  RAISE NOTICE '✅ Tabla "ot" encontrada';
  RAISE NOTICE '✅ Procediendo a crear procedimientos almacenados...';
END $$;

-- =========================================
-- PROCEDIMIENTOS PRINCIPALES DE OT
-- =========================================

-- CREATE (cabezal). Inicializa campos en valores por defecto
CREATE OR REPLACE FUNCTION sp_create_ot(
  p_num_ot VARCHAR, p_id_cotizacion INT, p_po VARCHAR, p_id_empresa INT, 
  p_id_contacto INT, p_descripcion TEXT, p_cantidad INT, p_id_colaborador INT,
  p_estado VARCHAR, p_fecha_inicio DATE, p_fecha_fin DATE, p_prioridad VARCHAR,
  p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id_ot INT;
BEGIN
  INSERT INTO ot (
    num_ot, id_cotizacion, po, id_empresa, id_contacto, descripcion, cantidad,
    id_colaborador, estado, fecha_inicio, fecha_fin, prioridad, observaciones
  ) VALUES (
    p_num_ot, p_id_cotizacion, p_po, p_id_empresa, p_id_contacto, p_descripcion,
    COALESCE(p_cantidad,0), p_id_colaborador, COALESCE(p_estado,'Pendiente'),
    p_fecha_inicio, p_fecha_fin, COALESCE(p_prioridad,'Normal'), p_observaciones
  ) RETURNING id_ot INTO v_id_ot;
  
  RETURN v_id_ot;
END; $$ LANGUAGE plpgsql;

-- UPDATE (cabezal, sin tocar campos calculados)
CREATE OR REPLACE FUNCTION sp_update_ot_info(
  p_id_ot INT, p_id_cotizacion INT, p_po VARCHAR, p_id_empresa INT, 
  p_id_contacto INT, p_descripcion TEXT, p_cantidad INT, p_id_colaborador INT,
  p_estado VARCHAR, p_fecha_inicio DATE, p_fecha_fin DATE, p_prioridad VARCHAR,
  p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE ot
  SET id_cotizacion = p_id_cotizacion, po = p_po, id_empresa = p_id_empresa,
      id_contacto = p_id_contacto, descripcion = p_descripcion, 
      cantidad = COALESCE(p_cantidad,0), id_colaborador = p_id_colaborador,
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
  id_colaborador INT,
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
    o.id_colaborador,
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

-- =========================================
-- PROCEDIMIENTOS DE OT-MATERIAL
-- =========================================

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

-- =========================================
-- PROCEDIMIENTOS DE OT-IMPORTACION
-- =========================================

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

-- =========================================
-- PROCEDIMIENTOS DE OT-PROCESO
-- =========================================

-- CREATE - Agregar proceso a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_proceso(
  p_id_ot INT, p_id_proceso INT, p_tiempo INT, p_total NUMERIC
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_proceso (
    id_ot, id_proceso, tiempo, total
  ) VALUES (
    p_id_ot, p_id_proceso, COALESCE(p_tiempo,0), COALESCE(p_total,0)
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener proceso específico de una OT
CREATE OR REPLACE FUNCTION get_ot_proceso(p_id INT)
RETURNS ot_proceso AS $$
  SELECT * FROM ot_proceso WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los procesos de una OT
CREATE OR REPLACE FUNCTION list_ot_procesos(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  id_proceso INT,
  tiempo INT,
  total NUMERIC,
  proceso_info JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    op.id,
    op.id_ot,
    op.id_proceso,
    op.tiempo,
    op.total,
    json_build_object(
      'id_proceso', pm.id_proceso,
      'descripcion', pm.descripcion,
      'tarifa_x_minuto', pm.tarifa_x_minuto
    ) AS proceso_info
  FROM ot_proceso op
  JOIN proceso_maquina pm ON op.id_proceso = pm.id_proceso
  WHERE op.id_ot = p_id_ot
  ORDER BY op.id
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar proceso de una OT
CREATE OR REPLACE FUNCTION sp_update_ot_proceso(
  p_id INT, p_tiempo INT, p_total NUMERIC
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_proceso
  SET tiempo = COALESCE(p_tiempo,0),
      total = COALESCE(p_total,0)
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar proceso de una OT
CREATE OR REPLACE FUNCTION sp_delete_ot_proceso(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_proceso WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- Función para calcular totales de procesos de una OT
CREATE OR REPLACE FUNCTION get_ot_proceso_totals(p_id_ot INT)
RETURNS TABLE(
  total_procesos INT,
  tiempo_total INT,
  subtotal_procesos NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT AS total_procesos,
    COALESCE(SUM(tiempo), 0) AS tiempo_total,
    COALESCE(SUM(total), 0) AS subtotal_procesos
  FROM ot_proceso
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;

-- Función para calcular tiempo total en horas y minutos
CREATE OR REPLACE FUNCTION get_ot_tiempo_formateado(p_id_ot INT)
RETURNS TABLE(
  tiempo_total_minutos INT,
  tiempo_horas INT,
  tiempo_minutos INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(tiempo), 0) AS tiempo_total_minutos,
    (COALESCE(SUM(tiempo), 0) / 60)::INT AS tiempo_horas,
    (COALESCE(SUM(tiempo), 0) % 60)::INT AS tiempo_minutos
  FROM ot_proceso
  WHERE id_ot = p_id_ot;
END; $$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTOS DE OT-PLANO-SOLIDO
-- =========================================

-- CREATE - Agregar archivo a una OT
CREATE OR REPLACE FUNCTION sp_create_ot_plano_solido(
  p_id_ot INT, p_nombre_archivo VARCHAR, p_tipo_archivo VARCHAR,
  p_ruta_archivo TEXT, p_observaciones TEXT
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_plano_solido (
    id_ot, nombre_archivo, tipo_archivo, ruta_archivo, observaciones
  ) VALUES (
    p_id_ot, p_nombre_archivo, p_tipo_archivo, p_ruta_archivo, p_observaciones
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener archivo específico
CREATE OR REPLACE FUNCTION get_ot_plano_solido(p_id INT)
RETURNS ot_plano_solido AS $$
  SELECT * FROM ot_plano_solido WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los archivos de una OT
CREATE OR REPLACE FUNCTION list_ot_planos_solidos(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  nombre_archivo VARCHAR,
  tipo_archivo VARCHAR,
  ruta_archivo TEXT,
  fecha_subida TIMESTAMP,
  observaciones TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ops.id,
    ops.id_ot,
    ops.nombre_archivo,
    ops.tipo_archivo,
    ops.ruta_archivo,
    ops.fecha_subida,
    ops.observaciones
  FROM ot_plano_solido ops
  WHERE ops.id_ot = p_id_ot
  ORDER BY ops.fecha_subida DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar información del archivo
CREATE OR REPLACE FUNCTION sp_update_ot_plano_solido(
  p_id INT, p_nombre_archivo VARCHAR, p_tipo_archivo VARCHAR,
  p_ruta_archivo TEXT, p_observaciones TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_plano_solido
  SET nombre_archivo = p_nombre_archivo,
      tipo_archivo = p_tipo_archivo,
      ruta_archivo = p_ruta_archivo,
      observaciones = p_observaciones
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar archivo
CREATE OR REPLACE FUNCTION sp_delete_ot_plano_solido(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_plano_solido WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTOS DE OT-REGISTRO-TIEMPO
-- =========================================

-- CREATE - Registrar tiempo de trabajo
CREATE OR REPLACE FUNCTION sp_create_ot_registro_tiempo(
  p_id_ot INT, p_id_colaborador INT, p_fecha_inicio TIMESTAMP,
  p_fecha_fin TIMESTAMP, p_tiempo_trabajado INT, p_descripcion TEXT, p_estado VARCHAR
) RETURNS INT AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO ot_registro_tiempo (
    id_ot, id_colaborador, fecha_inicio, fecha_fin, tiempo_trabajado, descripcion, estado
  ) VALUES (
    p_id_ot, p_id_colaborador, p_fecha_inicio, p_fecha_fin,
    COALESCE(p_tiempo_trabajado,0), p_descripcion, COALESCE(p_estado,'En Progreso')
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END; $$ LANGUAGE plpgsql;

-- READ - Obtener registro específico
CREATE OR REPLACE FUNCTION get_ot_registro_tiempo(p_id INT)
RETURNS ot_registro_tiempo AS $$
  SELECT * FROM ot_registro_tiempo WHERE id = p_id;
$$ LANGUAGE sql STABLE;

-- READ - Listar todos los registros de tiempo de una OT
CREATE OR REPLACE FUNCTION list_ot_registros_tiempo(
  p_id_ot INT, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(
  id INT,
  id_ot INT,
  id_colaborador INT,
  fecha_inicio TIMESTAMP,
  fecha_fin TIMESTAMP,
  tiempo_trabajado INT,
  descripcion TEXT,
  estado VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ort.id,
    ort.id_ot,
    ort.id_colaborador,
    ort.fecha_inicio,
    ort.fecha_fin,
    ort.tiempo_trabajado,
    ort.descripcion,
    ort.estado
  FROM ot_registro_tiempo ort
  WHERE ort.id_ot = p_id_ot
  ORDER BY ort.fecha_inicio DESC
  LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql;

-- UPDATE - Actualizar registro de tiempo
CREATE OR REPLACE FUNCTION sp_update_ot_registro_tiempo(
  p_id INT, p_fecha_inicio TIMESTAMP, p_fecha_fin TIMESTAMP,
  p_tiempo_trabajado INT, p_descripcion TEXT, p_estado VARCHAR
) RETURNS VOID AS $$
BEGIN
  UPDATE ot_registro_tiempo
  SET fecha_inicio = p_fecha_inicio,
      fecha_fin = p_fecha_fin,
      tiempo_trabajado = COALESCE(p_tiempo_trabajado,0),
      descripcion = p_descripcion,
      estado = COALESCE(p_estado,'En Progreso')
  WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- DELETE - Eliminar registro de tiempo
CREATE OR REPLACE FUNCTION sp_delete_ot_registro_tiempo(p_id INT) RETURNS VOID AS $$
BEGIN
  DELETE FROM ot_registro_tiempo WHERE id = p_id;
END; $$ LANGUAGE plpgsql;

-- =========================================
-- MENSAJE FINAL
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '🎉 PROCEDIMIENTOS DE OT CREADOS EXITOSAMENTE';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Procedimientos principales de OT:';
  RAISE NOTICE '   • sp_create_ot() - Crear OT';
  RAISE NOTICE '   • sp_update_ot_info() - Actualizar OT';
  RAISE NOTICE '   • get_ot() - Obtener OT por ID';
  RAISE NOTICE '   • get_ot_by_num() - Obtener OT por número';
  RAISE NOTICE '   • list_ots() - Listar OTs';
  RAISE NOTICE '   • sp_delete_ot() - Eliminar OT';
  RAISE NOTICE '   • get_ot_stats() - Estadísticas de OT';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Procedimientos de detalles:';
  RAISE NOTICE '   • Material, Importación, Proceso';
  RAISE NOTICE '   • Archivos (planos, documentos)';
  RAISE NOTICE '   • Control de tiempo (colaboradores)';
  RAISE NOTICE '';
  RAISE NOTICE '📋 PRÓXIMOS PASOS:';
  RAISE NOTICE '   1. Ejecutar insert_test_data.sql para agregar datos de prueba (opcional)';
  RAISE NOTICE '   2. Ejecutar prueba.sql para validar toda la funcionalidad';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 La sección OT está completamente funcional!';
  RAISE NOTICE '';
END $$;
