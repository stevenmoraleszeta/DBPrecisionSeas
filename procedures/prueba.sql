-- =========================================
-- PRUEBAS INTEGRALES DE TABLAS Y PROCEDURES
-- (PostgreSQL)
-- =========================================

BEGIN;

-- Opcional: trabajar en un schema
-- CREATE SCHEMA IF NOT EXISTS seas;
-- SET search_path TO seas, public;

-- Limpieza defensiva por si ya existen datos de runs anteriores
DELETE FROM cotizacion_proceso     WHERE num_cotizacion LIKE 'COT-TEST-%';
DELETE FROM cotizacion_importacion WHERE num_cotizacion LIKE 'COT-TEST-%';
DELETE FROM cotizacion_material    WHERE num_cotizacion LIKE 'COT-TEST-%';
DELETE FROM cotizacion             WHERE num_cotizacion LIKE 'COT-TEST-%';
DELETE FROM contacto               WHERE email = 'maria@acme.com' OR email = 'maria.actualizada@acme.com';
DELETE FROM material               WHERE descripcion = 'Aluminio 5052 (test)';
DELETE FROM importacion            WHERE descripcion = 'Flete marítimo (test)';
DELETE FROM proceso_maquina        WHERE descripcion = 'Corte láser (test)';
DELETE FROM empresa                WHERE cod_empresa = 'ACME';

-- =========================================
-- 1) EMPRESA + CONTACTO (CRUD + lecturas)
-- =========================================
SELECT sp_upsert_empresa(
  'ACME','ACME S.A.','San José','2222-2222','fact@acme.com','3-101-123456','Observación inicial'
);

DO $$
DECLARE
  v_emp empresa;
  v_id_contacto INT;
  v_contacto contacto;
BEGIN
  -- READ empresa
  SELECT * INTO v_emp FROM get_empresa('ACME');
  IF v_emp.cod_empresa IS DISTINCT FROM 'ACME' THEN
    RAISE EXCEPTION 'Fallo get_empresa';
  END IF;

  -- CREATE contacto
  SELECT sp_create_contacto('ACME','María López','8888-8888','maria@acme.com','Compras','VIP') INTO v_id_contacto;
  IF v_id_contacto IS NULL OR v_id_contacto <= 0 THEN
    RAISE EXCEPTION 'Fallo sp_create_contacto';
  END IF;

  -- READ contacto
  SELECT * INTO v_contacto FROM get_contacto(v_id_contacto);
  IF v_contacto.nombre_contacto <> 'María López' THEN
    RAISE EXCEPTION 'Fallo get_contacto';
  END IF;

  -- UPDATE contacto
  PERFORM sp_update_contacto(v_id_contacto,'ACME','María López','7777-7777','maria.actualizada@acme.com','Compras','VIP++');
  SELECT * INTO v_contacto FROM get_contacto(v_id_contacto);
  IF v_contacto.telefono <> '7777-7777' THEN
    RAISE EXCEPTION 'Fallo sp_update_contacto';
  END IF;

  -- LIST contactos por empresa
  IF NOT EXISTS (SELECT 1 FROM list_contactos('ACME', NULL, 50, 0)) THEN
    RAISE EXCEPTION 'Fallo list_contactos';
  END IF;
END $$;

-- =========================================
-- 2) CATÁLOGOS: MATERIAL / IMPORTACIÓN / PROCESO
-- =========================================
DO $$
DECLARE
  v_id_mat INT;
  v_id_imp INT;
  v_id_proc INT;
BEGIN
  SELECT sp_create_material('Aluminio 5052 (test)', 0, 'kg')  INTO v_id_mat;
  SELECT sp_create_importacion('Flete marítimo (test)', 0, 'serv') INTO v_id_imp;
  SELECT sp_create_proceso('Corte láser (test)', 0.75)        INTO v_id_proc;

  IF v_id_mat IS NULL OR v_id_imp IS NULL OR v_id_proc IS NULL THEN
    RAISE EXCEPTION 'Fallo creación de catálogos';
  END IF;

  -- UPDATEs simples
  PERFORM sp_update_material(v_id_mat, 'Aluminio 5052 (test)', 10, 'kg');
  PERFORM sp_update_importacion(v_id_imp, 'Flete marítimo (test)', 5, 'serv');
  PERFORM sp_update_proceso(v_id_proc, 'Corte láser (test)', 1.00);

  -- READ uno
  IF (SELECT (get_material(v_id_mat)).id_material) IS DISTINCT FROM v_id_mat THEN
    RAISE EXCEPTION 'Fallo get_material';
  END IF;
  IF (SELECT (get_importacion(v_id_imp)).id_importacion) IS DISTINCT FROM v_id_imp THEN
    RAISE EXCEPTION 'Fallo get_importacion';
  END IF;
  IF (SELECT (get_proceso(v_id_proc)).id_proceso) IS DISTINCT FROM v_id_proc THEN
    RAISE EXCEPTION 'Fallo get_proceso';
  END IF;

  -- LISTs
  IF NOT EXISTS (SELECT 1 FROM list_materiales(NULL, 10, 0)) THEN
    RAISE EXCEPTION 'Fallo list_materiales';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM list_importaciones(NULL, 10, 0)) THEN
    RAISE EXCEPTION 'Fallo list_importaciones';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM list_procesos(NULL, 10, 0)) THEN
    RAISE EXCEPTION 'Fallo list_procesos';
  END IF;
END $$;

-- =========================================
-- 3) COTIZACIÓN (cabezal) + DETALLES (sin recálculo automático)
-- =========================================
DO $$
DECLARE
  v_id_contacto  INT;
  v_id_mat       INT;
  v_id_imp       INT;
  v_id_proc      INT;
  v_subdet       NUMERIC(12,2);
  v_esperado     NUMERIC(12,2);
  v_cot          cotizacion;
BEGIN
  -- Tomar IDs de lo creado antes
  SELECT id_contacto INTO v_id_contacto FROM contacto WHERE email = 'maria.actualizada@acme.com' LIMIT 1;
  SELECT id_material INTO v_id_mat FROM material WHERE descripcion = 'Aluminio 5052 (test)' LIMIT 1;
  SELECT id_importacion INTO v_id_imp FROM importacion WHERE descripcion = 'Flete marítimo (test)' LIMIT 1;
  SELECT id_proceso INTO v_id_proc FROM proceso_maquina WHERE descripcion = 'Corte láser (test)' LIMIT 1;

  -- CREATE cotización
  PERFORM sp_create_cotizacion(
    'COT-TEST-001','ACME', v_id_contacto,
    'Zona Franca','2222-2222','Fabricación piezas (test)', 1,
    'USD','30 días','10 días hábiles','50% anticipo'
  );

  -- Agregar DETALLES (líneas calculan su total propio)
  -- Material: 3 * 10 = 30
  PERFORM sp_add_cotizacion_material('COT-TEST-001', v_id_mat, 3, '1/8"', 10.00);
  -- Importación: 1 * 150 = 150
  PERFORM sp_add_cotizacion_importacion('COT-TEST-001', v_id_imp, 1, NULL, 150.00);
  -- Proceso: 90 min * tarifa(1.00) = 90
  PERFORM sp_add_cotizacion_proceso('COT-TEST-001', v_id_proc, 90);

  -- Verificar subtotales de LÍNEAS
  SELECT COALESCE((
    SELECT SUM(total) FROM cotizacion_material WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  + COALESCE((
    SELECT SUM(total) FROM cotizacion_importacion WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  + COALESCE((
    SELECT SUM(total) FROM cotizacion_proceso WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  INTO v_subdet;

  v_esperado := 30.00 + 150.00 + 90.00; -- = 270.00
  IF v_subdet <> v_esperado THEN
    RAISE EXCEPTION 'Fallo sumatoria de detalles: % <> %', v_subdet, v_esperado;
  END IF;

  -- La APP calcula montos y los fija con sp_set_montos_cotizacion
  -- Descuento 20, IVA 0, Total = 270 - 20 = 250
  PERFORM sp_set_montos_cotizacion('COT-TEST-001', v_subdet, 20.00, 0.00, v_subdet - 20.00);

  SELECT * INTO v_cot FROM get_cotizacion('COT-TEST-001');
  IF v_cot.subtotal <> 270.00 OR v_cot.descuento <> 20.00 OR v_cot.iva <> 0.00 OR v_cot.total <> 250.00 THEN
    RAISE EXCEPTION 'Fallo sp_set_montos_cotizacion (%/%/%/%)',
      v_cot.subtotal, v_cot.descuento, v_cot.iva, v_cot.total;
  END IF;

  -- LIST de detalles (deben retornar filas)
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_materiales('COT-TEST-001')) THEN
    RAISE EXCEPTION 'Fallo get_cotizacion_materiales';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_importaciones('COT-TEST-001')) THEN
    RAISE EXCEPTION 'Fallo get_cotizacion_importaciones';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_procesos('COT-TEST-001')) THEN
    RAISE EXCEPTION 'Fallo get_cotizacion_procesos';
  END IF;

  -- Quitar una línea y volver a fijar montos desde app
  PERFORM sp_remove_cotizacion_material('COT-TEST-001', v_id_mat);

  -- Recalcular en la app (aquí simulamos con SELECTs)
  SELECT COALESCE((
    SELECT SUM(total) FROM cotizacion_material WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  + COALESCE((
    SELECT SUM(total) FROM cotizacion_importacion WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  + COALESCE((
    SELECT SUM(total) FROM cotizacion_proceso WHERE num_cotizacion = 'COT-TEST-001'
  ),0)
  INTO v_subdet;

  -- Ahora esperado = 0 + 150 + 90 = 240
  IF v_subdet <> 240.00 THEN
    RAISE EXCEPTION 'Fallo sumatoria tras borrar material: % <> 240.00', v_subdet;
  END IF;

  -- Fijar nuevos montos: descuento 10, iva 0, total = 230
  PERFORM sp_set_montos_cotizacion('COT-TEST-001', v_subdet, 10.00, 0.00, 230.00);

  SELECT * INTO v_cot FROM get_cotizacion('COT-TEST-001');
  IF v_cot.subtotal <> 240.00 OR v_cot.total <> 230.00 THEN
    RAISE EXCEPTION 'Fallo actualización de montos post-borrado';
  END IF;

END $$;

-- =========================================
-- 4) DELETEs de prueba y validaciones finales
-- =========================================
DO $$
DECLARE
  v_cnt INT;
BEGIN
  -- Borrar cotización (detalles caen por CASCADE)
  PERFORM sp_delete_cotizacion('COT-TEST-001');

  SELECT COUNT(*) INTO v_cnt FROM cotizacion WHERE num_cotizacion = 'COT-TEST-001';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'Fallo sp_delete_cotizacion';
  END IF;

  -- Borrar catálogos
  PERFORM sp_delete_material( (SELECT id_material FROM material WHERE descripcion='Aluminio 5052 (test)' LIMIT 1) );
  PERFORM sp_delete_importacion( (SELECT id_importacion FROM importacion WHERE descripcion='Flete marítimo (test)' LIMIT 1) );
  PERFORM sp_delete_proceso( (SELECT id_proceso FROM proceso_maquina WHERE descripcion='Corte láser (test)' LIMIT 1) );

  -- Borrar contacto y empresa
  PERFORM sp_delete_contacto( (SELECT id_contacto FROM contacto WHERE email='maria.actualizada@acme.com' LIMIT 1) );
  PERFORM sp_delete_empresa('ACME');

  -- Comprobar que ya no existe ACME
  IF EXISTS (SELECT 1 FROM empresa WHERE cod_empresa='ACME') THEN
    RAISE EXCEPTION 'Fallo sp_delete_empresa';
  END IF;

  RAISE NOTICE '✅ Todas las pruebas pasaron correctamente.';
END $$;

-- Al finalizar las pruebas:
ROLLBACK;
-- Si deseas conservar los datos de prueba, reemplaza la línea anterior por: COMMIT;
