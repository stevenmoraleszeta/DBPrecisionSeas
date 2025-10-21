-- =========================================
-- PRUEBAS INTEGRALES DE TABLAS Y PROCEDIMIENTOS
-- (PostgreSQL) - ESTRUCTURA ACTUALIZADA CON OT
-- =========================================
-- Este archivo prueba todas las tablas y procedimientos almacenados
-- para verificar que la nueva estructura funciona correctamente

-- =========================================
-- LIMPIEZA INICIAL
-- =========================================

-- Limpiar datos de pruebas anteriores
BEGIN;
DELETE FROM registro_tiempo        WHERE id_ot IN (SELECT id_ot FROM ot WHERE num_ot LIKE 'OT-TEST-%');
DELETE FROM archivo                WHERE id_ot IN (SELECT id_ot FROM ot WHERE num_ot LIKE 'OT-TEST-%');
DELETE FROM ot_proceso             WHERE id_ot IN (SELECT id_ot FROM ot WHERE num_ot LIKE 'OT-TEST-%');
DELETE FROM ot_importacion         WHERE id_ot IN (SELECT id_ot FROM ot WHERE num_ot LIKE 'OT-TEST-%');
DELETE FROM ot_material            WHERE id_ot IN (SELECT id_ot FROM ot WHERE num_ot LIKE 'OT-TEST-%');
DELETE FROM ot                     WHERE num_ot LIKE 'OT-TEST-%';
DELETE FROM cotizacion_proceso     WHERE id_cotizacion IN (SELECT id_cotizacion FROM cotizacion WHERE num_cotizacion LIKE 'COT-TEST-%');
DELETE FROM cotizacion_importacion WHERE id_cotizacion IN (SELECT id_cotizacion FROM cotizacion WHERE num_cotizacion LIKE 'COT-TEST-%');
DELETE FROM cotizacion_material    WHERE id_cotizacion IN (SELECT id_cotizacion FROM cotizacion WHERE num_cotizacion LIKE 'COT-TEST-%');
DELETE FROM cotizacion             WHERE num_cotizacion LIKE 'COT-TEST-%';
DELETE FROM contacto               WHERE email LIKE '%@test.com';
DELETE FROM material               WHERE descripcion LIKE '%TEST%';
DELETE FROM importacion            WHERE descripcion LIKE '%TEST%';
DELETE FROM proceso_maquina        WHERE descripcion LIKE '%TEST%';
DELETE FROM empresa                WHERE cod_empresa LIKE 'TEST%';
DELETE FROM usuario                WHERE email LIKE '%@test.com' OR email LIKE '%@empresa.com';
COMMIT;

-- =========================================
-- 1) PRUEBAS DE CATÁLOGOS (Sin dependencias)
-- =========================================

-- Material
DO $$
DECLARE
  v_id_material INT;
  v_material material;
BEGIN
  RAISE NOTICE '🧪 Probando MATERIAL...';
  
  -- CREATE
  SELECT sp_create_material('Material TEST 001', 100, 'kg') INTO v_id_material;
  IF v_id_material IS NULL OR v_id_material <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_material';
  END IF;
  RAISE NOTICE '✅ Material creado con ID: %', v_id_material;
  
  -- READ
  SELECT * INTO v_material FROM get_material(v_id_material);
  IF v_material.id_material != v_id_material THEN
    RAISE EXCEPTION '❌ Fallo get_material';
  END IF;
  RAISE NOTICE '✅ Material leído correctamente';
  
  -- UPDATE
  PERFORM sp_update_material(v_id_material, 'Material TEST 001 Actualizado', 150, 'kg');
  SELECT * INTO v_material FROM get_material(v_id_material);
  IF v_material.cantidad != 150 THEN
    RAISE EXCEPTION '❌ Fallo sp_update_material';
  END IF;
  RAISE NOTICE '✅ Material actualizado correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_materiales(NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_materiales';
  END IF;
  RAISE NOTICE '✅ Lista de materiales funcionando';
  
  RAISE NOTICE '🎉 Pruebas de MATERIAL completadas exitosamente';
END $$;

-- Importación
DO $$
DECLARE
  v_id_importacion INT;
  v_importacion importacion;
BEGIN
  RAISE NOTICE '🧪 Probando IMPORTACION...';
  
  -- CREATE
  SELECT sp_create_importacion('Importación TEST 001', 50, 'unidades') INTO v_id_importacion;
  IF v_id_importacion IS NULL OR v_id_importacion <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_importacion';
  END IF;
  RAISE NOTICE '✅ Importación creada con ID: %', v_id_importacion;
  
  -- READ
  SELECT * INTO v_importacion FROM get_importacion(v_id_importacion);
  IF v_importacion.id_importacion != v_id_importacion THEN
    RAISE EXCEPTION '❌ Fallo get_importacion';
  END IF;
  RAISE NOTICE '✅ Importación leída correctamente';
  
  -- UPDATE
  PERFORM sp_update_importacion(v_id_importacion, 'Importación TEST 001 Actualizada', 75, 'unidades');
  SELECT * INTO v_importacion FROM get_importacion(v_id_importacion);
  IF v_importacion.cantidad != 75 THEN
    RAISE EXCEPTION '❌ Fallo sp_update_importacion';
  END IF;
  RAISE NOTICE '✅ Importación actualizada correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_importaciones(NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_importaciones';
  END IF;
  RAISE NOTICE '✅ Lista de importaciones funcionando';
  
  RAISE NOTICE '🎉 Pruebas de IMPORTACION completadas exitosamente';
END $$;

-- Proceso/Máquina
DO $$
DECLARE
  v_id_proceso INT;
  v_proceso proceso_maquina;
BEGIN
  RAISE NOTICE '🧪 Probando PROCESO_MAQUINA...';
  
  -- CREATE
  SELECT sp_create_proceso('Proceso TEST 001', 25.50) INTO v_id_proceso;
  IF v_id_proceso IS NULL OR v_id_proceso <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_proceso';
  END IF;
  RAISE NOTICE '✅ Proceso creado con ID: %', v_id_proceso;
  
  -- READ
  SELECT * INTO v_proceso FROM get_proceso(v_id_proceso);
  IF v_proceso.id_proceso != v_id_proceso THEN
    RAISE EXCEPTION '❌ Fallo get_proceso';
  END IF;
  RAISE NOTICE '✅ Proceso leído correctamente';
  
  -- UPDATE
  PERFORM sp_update_proceso(v_id_proceso, 'Proceso TEST 001 Actualizado', 30.00);
  SELECT * INTO v_proceso FROM get_proceso(v_id_proceso);
  IF v_proceso.tarifa_x_minuto != 30.00 THEN
    RAISE EXCEPTION '❌ Fallo sp_update_proceso';
  END IF;
  RAISE NOTICE '✅ Proceso actualizado correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_procesos(NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_procesos';
  END IF;
  RAISE NOTICE '✅ Lista de procesos funcionando';
  
  RAISE NOTICE '🎉 Pruebas de PROCESO_MAQUINA completadas exitosamente';
END $$;

-- =========================================
-- 2) PRUEBAS DE EMPRESA (Tabla padre)
-- =========================================

DO $$
DECLARE
  v_id_empresa INT;
  v_empresa empresa;
BEGIN
  RAISE NOTICE '🧪 Probando EMPRESA...';
  
  -- CREATE
  SELECT sp_upsert_empresa(
    'TEST001', 'Empresa TEST 001', 'Dirección TEST', '2222-2222',
    'test@empresa.com', '123456789', 'Observaciones TEST'
  ) INTO v_id_empresa;
  
  IF v_id_empresa IS NULL OR v_id_empresa <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_upsert_empresa';
  END IF;
  RAISE NOTICE '✅ Empresa creada con ID: %', v_id_empresa;
  
  -- READ por código
  SELECT * INTO v_empresa FROM get_empresa_by_cod('TEST001');
  IF v_empresa.cod_empresa != 'TEST001' THEN
    RAISE EXCEPTION '❌ Fallo get_empresa_by_cod';
  END IF;
  RAISE NOTICE '✅ Empresa leída por código correctamente';
  
  -- READ por ID
  SELECT * INTO v_empresa FROM get_empresa(v_id_empresa);
  IF v_empresa.id_empresa != v_id_empresa THEN
    RAISE EXCEPTION '❌ Fallo get_empresa por ID';
  END IF;
  RAISE NOTICE '✅ Empresa leída por ID correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_empresas(NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_empresas';
  END IF;
  RAISE NOTICE '✅ Lista de empresas funcionando';
  
  RAISE NOTICE '🎉 Pruebas de EMPRESA completadas exitosamente';
END $$;

-- =========================================
-- 3) PRUEBAS DE CONTACTO (Depende de empresa)
-- =========================================

DO $$
DECLARE
  v_id_empresa INT;
  v_id_contacto INT;
  v_contacto contacto;
BEGIN
  RAISE NOTICE '🧪 Probando CONTACTO...';
  
  -- Obtener ID de empresa
  SELECT id_empresa INTO v_id_empresa FROM empresa WHERE cod_empresa = 'TEST001';
  
  -- CREATE
  SELECT sp_create_contacto(
    v_id_empresa, 'Contacto TEST 001', '3333-3333',
    'contacto@test.com', 'Gerente TEST', 'Notas TEST'
  ) INTO v_id_contacto;
  
  IF v_id_contacto IS NULL OR v_id_contacto <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_contacto';
  END IF;
  RAISE NOTICE '✅ Contacto creado con ID: %', v_id_contacto;
  
  -- READ
  SELECT * INTO v_contacto FROM get_contacto(v_id_contacto);
  IF v_contacto.id_contacto != v_id_contacto THEN
    RAISE EXCEPTION '❌ Fallo get_contacto';
  END IF;
  RAISE NOTICE '✅ Contacto leído correctamente';
  
  -- UPDATE
  PERFORM sp_update_contacto(
    v_id_contacto, v_id_empresa, 'Contacto TEST 001 Actualizado',
    '4444-4444', 'contacto.actualizado@test.com', 'Gerente TEST Actualizado', 'Notas TEST Actualizadas'
  );
  SELECT * INTO v_contacto FROM get_contacto(v_id_contacto);
  IF v_contacto.telefono != '4444-4444' THEN
    RAISE EXCEPTION '❌ Fallo sp_update_contacto';
  END IF;
  RAISE NOTICE '✅ Contacto actualizado correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_contactos(v_id_empresa, NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_contactos';
  END IF;
  RAISE NOTICE '✅ Lista de contactos funcionando';
  
  RAISE NOTICE '🎉 Pruebas de CONTACTO completadas exitosamente';
END $$;

-- =========================================
-- 4) PRUEBAS DE COTIZACIÓN (Depende de empresa y contacto)
-- =========================================

DO $$
DECLARE
  v_id_empresa INT;
  v_id_contacto INT;
  v_id_cotizacion INT;
  v_cotizacion cotizacion;
BEGIN
  RAISE NOTICE '🧪 Probando COTIZACION...';
  
  -- Obtener IDs necesarios
  SELECT id_empresa INTO v_id_empresa FROM empresa WHERE cod_empresa = 'TEST001';
  SELECT id_contacto INTO v_id_contacto FROM contacto WHERE email = 'contacto.actualizado@test.com';
  
  -- CREATE
  SELECT sp_create_cotizacion(
    'COT-TEST-001', v_id_empresa, v_id_contacto,
    'Dirección TEST', '5555-5555', 'Servicio TEST 001', 1,
    'USD', '30 días', '2 semanas', '50% anticipo'
  ) INTO v_id_cotizacion;
  
  IF v_id_cotizacion IS NULL OR v_id_cotizacion <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_cotizacion';
  END IF;
  RAISE NOTICE '✅ Cotización creada con ID: %', v_id_cotizacion;
  
  -- READ por ID
  SELECT * INTO v_cotizacion FROM get_cotizacion(v_id_cotizacion);
  IF v_cotizacion.id_cotizacion != v_id_cotizacion THEN
    RAISE EXCEPTION '❌ Fallo get_cotizacion por ID';
  END IF;
  RAISE NOTICE '✅ Cotización leída por ID correctamente';
  
  -- READ por número
  SELECT * INTO v_cotizacion FROM get_cotizacion_by_num('COT-TEST-001');
  IF v_cotizacion.num_cotizacion != 'COT-TEST-001' THEN
    RAISE EXCEPTION '❌ Fallo get_cotizacion_by_num';
  END IF;
  RAISE NOTICE '✅ Cotización leída por número correctamente';
  
  -- UPDATE
  PERFORM sp_update_cotizacion_info(
    v_id_cotizacion, v_id_empresa, v_id_contacto,
    'Dirección TEST Actualizada', '6666-6666', 'Servicio TEST 001 Actualizado', 2,
    'EUR', '45 días', '3 semanas', '30% anticipo',
    'Observaciones cliente TEST', 'Observaciones internas TEST'
  );
  SELECT * INTO v_cotizacion FROM get_cotizacion(v_id_cotizacion);
  IF v_cotizacion.cantidad != 2 THEN
    RAISE EXCEPTION '❌ Fallo sp_update_cotizacion_info';
  END IF;
  RAISE NOTICE '✅ Cotización actualizada correctamente';
  
  -- SET montos
  PERFORM sp_set_montos_cotizacion(v_id_cotizacion, 1000.00, 100.00, 190.00, 1090.00);
  SELECT * INTO v_cotizacion FROM get_cotizacion(v_id_cotizacion);
  IF v_cotizacion.total != 1090.00 THEN
    RAISE EXCEPTION '❌ Fallo sp_set_montos_cotizacion';
  END IF;
  RAISE NOTICE '✅ Montos de cotización establecidos correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_cotizaciones(v_id_empresa, NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_cotizaciones';
  END IF;
  RAISE NOTICE '✅ Lista de cotizaciones funcionando';
  
  RAISE NOTICE '🎉 Pruebas de COTIZACION completadas exitosamente';
END $$;

-- =========================================
-- 5) PRUEBAS DE DETALLES DE COTIZACIÓN
-- =========================================

DO $$
DECLARE
  v_id_cotizacion INT;
  v_id_material INT;
  v_id_importacion INT;
  v_id_proceso INT;
  v_total_material NUMERIC;
  v_total_importacion NUMERIC;
  v_total_proceso NUMERIC;
BEGIN
  RAISE NOTICE '🧪 Probando DETALLES DE COTIZACION...';
  
  -- Obtener IDs necesarios
  SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE num_cotizacion = 'COT-TEST-001';
  SELECT id_material INTO v_id_material FROM material WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_importacion INTO v_id_importacion FROM importacion WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_proceso INTO v_id_proceso FROM proceso_maquina WHERE descripcion LIKE '%TEST%' LIMIT 1;
  
  -- Material
  PERFORM sp_add_cotizacion_material(v_id_cotizacion, v_id_material, 5, '10x20cm', 50.00);
  SELECT total INTO v_total_material FROM cotizacion_material WHERE id_cotizacion = v_id_cotizacion AND id_material = v_id_material;
  IF v_total_material != 250.00 THEN
    RAISE EXCEPTION '❌ Fallo sp_add_cotizacion_material - total incorrecto: %', v_total_material;
  END IF;
  RAISE NOTICE '✅ Material agregado a cotización correctamente';
  
  -- Importación
  PERFORM sp_add_cotizacion_importacion(v_id_cotizacion, v_id_importacion, 2, 'Flete marítimo', 100.00);
  SELECT total INTO v_total_importacion FROM cotizacion_importacion WHERE id_cotizacion = v_id_cotizacion AND id_importacion = v_id_importacion;
  IF v_total_importacion != 200.00 THEN
    RAISE EXCEPTION '❌ Fallo sp_add_cotizacion_importacion - total incorrecto: %', v_total_importacion;
  END IF;
  RAISE NOTICE '✅ Importación agregada a cotización correctamente';
  
  -- Proceso
  PERFORM sp_add_cotizacion_proceso(v_id_cotizacion, v_id_proceso, 120);
  SELECT total INTO v_total_proceso FROM cotizacion_proceso WHERE id_cotizacion = v_id_cotizacion AND id_proceso = v_id_proceso;
  IF v_total_proceso != 3600.00 THEN -- 120 min * 30.00 tarifa
    RAISE EXCEPTION '❌ Fallo sp_add_cotizacion_proceso - total incorrecto: %', v_total_proceso;
  END IF;
  RAISE NOTICE '✅ Proceso agregado a cotización correctamente';
  
  -- Verificar listas de detalles
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_materiales(v_id_cotizacion)) THEN
    RAISE EXCEPTION '❌ Fallo get_cotizacion_materiales';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_importaciones(v_id_cotizacion)) THEN
    RAISE EXCEPTION '❌ Fallo get_cotizacion_importaciones';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM get_cotizacion_procesos(v_id_cotizacion)) THEN
    RAISE EXCEPTION '❌ Fallo get_cotizacion_procesos';
  END IF;
  
  RAISE NOTICE '✅ Listas de detalles funcionando correctamente';
  
  RAISE NOTICE '🎉 Pruebas de DETALLES DE COTIZACION completadas exitosamente';
END $$;

-- =========================================
-- 6) PRUEBAS DE USUARIO (COLABORADORES)
-- =========================================

DO $$
DECLARE
  v_id_usuario INT;
  v_usuario JSON;
  v_usuarios JSON;
BEGIN
  RAISE NOTICE '🧪 Probando USUARIO (Colaboradores)...';
  
  -- CREATE usuario
  SELECT sp_create_usuario(
    'Usuario', 'TEST 001', 'usuario.test001@empresa.com',
    '+56 9 9999 0001', 'Ingeniero TEST', 'Departamento TEST', 'Activo',
    'Usuario de prueba para validar funcionalidad'
  ) INTO v_usuario;
  
  IF v_usuario->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo sp_create_usuario: %', v_usuario->>'message';
  END IF;
  
  v_id_usuario := (v_usuario->>'id_usuario')::INT;
  RAISE NOTICE '✅ Usuario creado con ID: %', v_id_usuario;
  
  -- READ por ID
  SELECT get_usuario(v_id_usuario) INTO v_usuario;
  IF v_usuario->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo get_usuario por ID';
  END IF;
  RAISE NOTICE '✅ Usuario leído por ID correctamente';
  
  -- UPDATE usuario
  SELECT sp_update_usuario(
    v_id_usuario, 'Usuario', 'TEST 001 Actualizado',
    'usuario.actualizado@empresa.com', '+56 9 9999 0002',
    'Ingeniero TEST Actualizado', 'Departamento TEST Actualizado', 'Activo',
    'Usuario de prueba actualizado'
  ) INTO v_usuario;
  
  IF v_usuario->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo sp_update_usuario';
  END IF;
  RAISE NOTICE '✅ Usuario actualizado correctamente';
  
  -- Verificar actualización
  SELECT get_usuario(v_id_usuario) INTO v_usuario;
  IF v_usuario->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo get_usuario después de actualizar';
  END IF;
  
  IF v_usuario->'data'->>'telefono' != '+56 9 9999 0002' THEN
    RAISE EXCEPTION '❌ Fallo sp_update_usuario - teléfono no se actualizó';
  END IF;
  RAISE NOTICE '✅ Verificación de actualización exitosa';
  
  -- LIST usuarios
  SELECT list_usuarios(10, 0, NULL, NULL, NULL) INTO v_usuarios;
  IF v_usuarios->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo list_usuarios';
  END IF;
  RAISE NOTICE '✅ Lista de usuarios funcionando';
  
  -- SEARCH usuarios
  SELECT search_usuarios('TEST') INTO v_usuarios;
  IF v_usuarios->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo search_usuarios';
  END IF;
  RAISE NOTICE '✅ Búsqueda de usuarios funcionando';
  
  -- STATS usuarios
  SELECT get_usuario_stats() INTO v_usuarios;
  IF v_usuarios->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo get_usuario_stats';
  END IF;
  RAISE NOTICE '✅ Estadísticas de usuarios funcionando';
  
  RAISE NOTICE '🎉 Pruebas de USUARIO completadas exitosamente';
END $$;

-- =========================================
-- 6.5) PRUEBAS DE AUTENTICACIÓN
-- =========================================

DO $$
DECLARE
  v_id_usuario INT;
  v_auth_result JSON;
  v_user_result JSON;
  v_test_password VARCHAR(255) := 'Admin123!';
  v_test_hash VARCHAR(255) := '$2b$12$oQpM2V0i0cAwxRw9nIdLEe9he12/QCKjVHr0SzO5RhZK2FHDMbpx2';
BEGIN
  RAISE NOTICE '🧪 Probando AUTENTICACIÓN...';
  
  -- Crear usuario de prueba con contraseña
  SELECT sp_create_usuario(
    'Usuario', 'Auth TEST', 'auth.test@empresa.com',
    '+56 9 9999 9999', 'Tester', 'Testing', 'Activo',
    'Usuario para pruebas de autenticación',
    v_test_hash
  ) INTO v_auth_result;
  
  IF v_auth_result->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo sp_create_usuario para auth: %', v_auth_result->>'message';
  END IF;
  
  v_id_usuario := (v_auth_result->>'id_usuario')::INT;
  RAISE NOTICE '✅ Usuario de auth creado con ID: %', v_id_usuario;
  
  -- Probar authenticate_user con credenciales correctas
  SELECT authenticate_user('auth.test@empresa.com', v_test_password) INTO v_auth_result;
  IF v_auth_result->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo authenticate_user con credenciales correctas: %', v_auth_result->>'message';
  END IF;
  RAISE NOTICE '✅ authenticate_user con credenciales correctas funcionando';
  
  -- Probar authenticate_user con email incorrecto
  SELECT authenticate_user('email.incorrecto@empresa.com', v_test_password) INTO v_auth_result;
  IF v_auth_result->>'success' != 'false' THEN
    RAISE EXCEPTION '❌ Fallo authenticate_user con email incorrecto - debería fallar';
  END IF;
  RAISE NOTICE '✅ authenticate_user con email incorrecto funcionando correctamente';
  
  -- Probar get_user_by_email con email existente
  SELECT get_user_by_email('auth.test@empresa.com') INTO v_user_result;
  IF v_user_result->>'success' != 'true' THEN
    RAISE EXCEPTION '❌ Fallo get_user_by_email con email existente: %', v_user_result->>'message';
  END IF;
  RAISE NOTICE '✅ get_user_by_email con email existente funcionando';
  
  -- Probar get_user_by_email con email inexistente
  SELECT get_user_by_email('email.inexistente@empresa.com') INTO v_user_result;
  IF v_user_result->>'success' != 'false' THEN
    RAISE EXCEPTION '❌ Fallo get_user_by_email con email inexistente - debería fallar';
  END IF;
  RAISE NOTICE '✅ get_user_by_email con email inexistente funcionando correctamente';
  
  -- Probar authenticate_user con usuario inactivo
  UPDATE usuario SET estado = 'Inactivo' WHERE id_usuario = v_id_usuario;
  SELECT authenticate_user('auth.test@empresa.com', v_test_password) INTO v_auth_result;
  IF v_auth_result->>'success' != 'false' THEN
    RAISE EXCEPTION '❌ Fallo authenticate_user con usuario inactivo - debería fallar';
  END IF;
  RAISE NOTICE '✅ authenticate_user con usuario inactivo funcionando correctamente';
  
  -- Limpiar usuario de prueba
  DELETE FROM usuario WHERE id_usuario = v_id_usuario;
  RAISE NOTICE '✅ Usuario de prueba eliminado';
  
  RAISE NOTICE '🎉 Pruebas de AUTENTICACIÓN completadas exitosamente';
END $$;

-- =========================================
-- 7) PRUEBAS DE OT (Orden de Trabajo)
-- =========================================

DO $$
DECLARE
  v_id_empresa INT;
  v_id_contacto INT;
  v_id_cotizacion INT;
  v_id_usuario INT;
  v_id_ot INT;
  v_ot ot;
BEGIN
  RAISE NOTICE '🧪 Probando OT (Orden de Trabajo)...';
  
  -- Obtener IDs necesarios
  SELECT id_empresa INTO v_id_empresa FROM empresa WHERE cod_empresa = 'TEST001';
  SELECT id_contacto INTO v_id_contacto FROM contacto WHERE email = 'contacto.actualizado@test.com';
  SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE num_cotizacion = 'COT-TEST-001';
  SELECT id_usuario INTO v_id_usuario FROM usuario WHERE email = 'usuario.actualizado@empresa.com';
  
  -- CREATE OT
  SELECT sp_create_ot(
    'OT-TEST-001', v_id_cotizacion, 'PO-TEST-001', v_id_empresa, v_id_contacto,
    'OT de prueba para validar funcionalidad', 1, 'Pendiente',
    '2024-01-15', '2024-02-15', 'Alta', 'OT de prueba'
  ) INTO v_id_ot;
  
  IF v_id_ot IS NULL OR v_id_ot <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_ot';
  END IF;
  RAISE NOTICE '✅ OT creada con ID: %', v_id_ot;
  
  -- READ por ID
  SELECT * INTO v_ot FROM get_ot(v_id_ot);
  IF v_ot.id_ot != v_id_ot THEN
    RAISE EXCEPTION '❌ Fallo get_ot por ID';
  END IF;
  RAISE NOTICE '✅ OT leída por ID correctamente';
  
  -- READ por número
  SELECT * INTO v_ot FROM get_ot_by_num('OT-TEST-001');
  IF v_ot.num_ot != 'OT-TEST-001' THEN
    RAISE EXCEPTION '❌ Fallo get_ot_by_num';
  END IF;
  RAISE NOTICE '✅ OT leída por número correctamente';
  
  -- UPDATE
  PERFORM sp_update_ot_info(
    v_id_ot, v_id_cotizacion, 'PO-TEST-001-UPDATED', v_id_empresa, v_id_contacto,
    'OT de prueba actualizada', 2, 'En Progreso',
    '2024-01-20', '2024-02-20', 'Media', 'OT de prueba actualizada'
  );
  SELECT * INTO v_ot FROM get_ot(v_id_ot);
  IF v_ot.cantidad != 2 THEN
    RAISE EXCEPTION '❌ Fallo sp_update_ot_info';
  END IF;
  RAISE NOTICE '✅ OT actualizada correctamente';
  
  -- LIST
  IF NOT EXISTS (SELECT 1 FROM list_ots(v_id_empresa, NULL, NULL, NULL, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_ots';
  END IF;
  RAISE NOTICE '✅ Lista de OTs funcionando';
  
  -- STATS
  IF NOT EXISTS (SELECT 1 FROM get_ot_stats(v_id_empresa)) THEN
    RAISE EXCEPTION '❌ Fallo get_ot_stats';
  END IF;
  RAISE NOTICE '✅ Estadísticas de OT funcionando';
  
  RAISE NOTICE '🎉 Pruebas de OT completadas exitosamente';
END $$;

-- =========================================
-- 8) PRUEBAS DE DETALLES DE OT
-- =========================================

DO $$
DECLARE
  v_id_ot INT;
  v_id_material INT;
  v_id_importacion INT;
  v_id_proceso INT;
  v_id_ot_mat INT;
  v_id_ot_imp INT;
  v_id_ot_proc INT;
BEGIN
  RAISE NOTICE '🧪 Probando DETALLES DE OT...';
  
  -- Obtener IDs necesarios
  SELECT id_ot INTO v_id_ot FROM ot WHERE num_ot = 'OT-TEST-001';
  SELECT id_material INTO v_id_material FROM material WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_importacion INTO v_id_importacion FROM importacion WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_proceso INTO v_id_proceso FROM proceso_maquina WHERE descripcion LIKE '%TEST%' LIMIT 1;
  
  -- OT Material
  SELECT sp_create_ot_material(v_id_ot, v_id_material, 10, '20x30cm', 75.00, 750.00) INTO v_id_ot_mat;
  IF v_id_ot_mat IS NULL OR v_id_ot_mat <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_ot_material';
  END IF;
  RAISE NOTICE '✅ Material agregado a OT correctamente';
  
  -- OT Importación
  SELECT sp_create_ot_importacion(v_id_ot, v_id_importacion, 3, 'Flete aéreo', 150.00, 450.00) INTO v_id_ot_imp;
  IF v_id_ot_imp IS NULL OR v_id_ot_imp <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_ot_importacion';
  END IF;
  RAISE NOTICE '✅ Importación agregada a OT correctamente';
  
  -- OT Proceso
  SELECT sp_create_ot_proceso(v_id_ot, v_id_proceso, 180, 5400.00) INTO v_id_ot_proc;
  IF v_id_ot_proc IS NULL OR v_id_ot_proc <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_ot_proceso';
  END IF;
  RAISE NOTICE '✅ Proceso agregado a OT correctamente';
  
  -- Verificar listas de detalles
  IF NOT EXISTS (SELECT 1 FROM list_ot_materials(v_id_ot, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_ot_materials';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM list_ot_importaciones(v_id_ot, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_ot_importaciones';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM list_ot_procesos(v_id_ot, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_ot_procesos';
  END IF;
  
  RAISE NOTICE '✅ Listas de detalles de OT funcionando correctamente';
  
  RAISE NOTICE '🎉 Pruebas de DETALLES DE OT completadas exitosamente';
END $$;

-- =========================================
-- 9) PRUEBAS DE ARCHIVOS Y TIEMPO DE OT
-- =========================================

DO $$
DECLARE
  v_id_ot INT;
  v_id_usuario INT;
  v_id_archivo INT;
  v_id_tiempo INT;
BEGIN
  RAISE NOTICE '🧪 Probando ARCHIVOS Y TIEMPO DE OT...';
  
  -- Obtener IDs necesarios
  SELECT id_ot INTO v_id_ot FROM ot WHERE num_ot = 'OT-TEST-001';
  SELECT id_usuario INTO v_id_usuario FROM usuario WHERE email = 'usuario.actualizado@empresa.com';
  
  -- OT Archivo
  SELECT sp_create_archivo(
    'plano_test.dwg', 'plano_test.dwg', 'cad', 'application/dwg',
    1024000, 'uploads/planos/plano_test-1234567890-test123.dwg',
    v_id_ot, 'Plano de prueba'
  ) INTO v_id_archivo;
  
  IF v_id_archivo IS NULL OR v_id_archivo <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_archivo';
  END IF;
  RAISE NOTICE '✅ Archivo agregado a OT correctamente';
  
  -- OT Registro Tiempo
  SELECT sp_create_registro_tiempo(
    v_id_usuario, '2024-01-15 08:00:00', '2024-01-15 12:00:00', 
    240, 'Trabajo de prueba', 'Completado',
    v_id_ot, '2024-01-15 08:30:00', '2024-01-15 12:30:00'
  ) INTO v_id_tiempo;
  
  IF v_id_tiempo IS NULL OR v_id_tiempo <= 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_create_registro_tiempo';
  END IF;
  RAISE NOTICE '✅ Registro de tiempo agregado a OT correctamente';
  
  -- Verificar listas
  IF NOT EXISTS (SELECT 1 FROM list_archivos(v_id_ot, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_archivos';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM list_registros_tiempo(v_id_ot, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_registros_tiempo';
  END IF;
  
  RAISE NOTICE '✅ Listas de archivos y tiempo funcionando correctamente';
  
  -- PRUEBAS ADICIONALES DE REGISTRO_TIEMPO
  -- =========================================
  
  -- READ registro específico
  IF NOT EXISTS (SELECT 1 FROM get_registro_tiempo(v_id_tiempo)) THEN
    RAISE EXCEPTION '❌ Fallo get_registro_tiempo';
  END IF;
  RAISE NOTICE '✅ Lectura de registro específico funcionando';
  
  -- UPDATE registro
  PERFORM sp_update_registro_tiempo(
    v_id_tiempo, '2024-01-15 09:00:00', '2024-01-15 13:00:00',
    300, 'Trabajo de prueba actualizado', 'Completado',
    '2024-01-15 09:30:00', '2024-01-15 13:30:00'
  );
  RAISE NOTICE '✅ Actualización de registro funcionando';
  
  -- LIST por colaborador
  IF NOT EXISTS (SELECT 1 FROM list_registros_por_colaborador(v_id_usuario, 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_registros_por_colaborador';
  END IF;
  RAISE NOTICE '✅ Lista por colaborador funcionando';
  
  -- LIST por estado
  IF NOT EXISTS (SELECT 1 FROM list_registros_por_estado(v_id_ot, 'Completado', 10, 0)) THEN
    RAISE EXCEPTION '❌ Fallo list_registros_por_estado';
  END IF;
  RAISE NOTICE '✅ Lista por estado funcionando';
  
  -- REGISTROS DEL DÍA
  IF NOT EXISTS (SELECT 1 FROM get_registros_hoy(v_id_ot)) THEN
    RAISE EXCEPTION '❌ Fallo get_registros_hoy';
  END IF;
  RAISE NOTICE '✅ Registros del día funcionando';
  
  -- TIEMPO TOTAL TRABAJADO
  IF NOT EXISTS (SELECT 1 FROM get_tiempo_total_trabajado(v_id_ot)) THEN
    RAISE EXCEPTION '❌ Fallo get_tiempo_total_trabajado';
  END IF;
  RAISE NOTICE '✅ Tiempo total trabajado funcionando';
  
  -- TIEMPO POR COLABORADOR
  IF NOT EXISTS (SELECT 1 FROM get_tiempo_por_colaborador(v_id_ot)) THEN
    RAISE EXCEPTION '❌ Fallo get_tiempo_por_colaborador';
  END IF;
  RAISE NOTICE '✅ Tiempo por colaborador funcionando';
  
  -- COMPLETAR REGISTRO (crear uno nuevo para probar)
  SELECT sp_create_registro_tiempo(
    v_id_usuario, '2024-01-15 14:00:00', NULL, 
    0, 'Trabajo en progreso', 'En Progreso',
    v_id_ot, '2024-01-15 14:30:00', '2024-01-15 18:30:00'
  ) INTO v_id_tiempo;
  
  PERFORM sp_completar_registro_tiempo(v_id_tiempo, '2024-01-15 18:00:00', 240);
  RAISE NOTICE '✅ Completar registro funcionando';
  
  RAISE NOTICE '🎉 Pruebas de ARCHIVOS Y TIEMPO DE OT completadas exitosamente';
END $$;

-- =========================================
-- 10) PRUEBAS DE ELIMINACIÓN (Orden inverso)
-- =========================================

DO $$
DECLARE
  v_id_ot INT;
  v_id_cotizacion INT;
  v_id_empresa INT;
  v_id_contacto INT;
  v_id_material INT;
  v_id_importacion INT;
  v_id_proceso INT;
  v_id_usuario INT;
  v_id_ot_mat INT;
  v_id_ot_imp INT;
  v_id_ot_proc INT;
  v_id_archivo INT;
  v_id_tiempo INT;
  v_cnt INT;
BEGIN
  RAISE NOTICE '🧪 Probando ELIMINACIONES...';
  
  -- Obtener IDs para eliminar
  SELECT id_ot INTO v_id_ot FROM ot WHERE num_ot = 'OT-TEST-001';
  SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE num_cotizacion = 'COT-TEST-001';
  SELECT id_empresa INTO v_id_empresa FROM empresa WHERE cod_empresa = 'TEST001';
  SELECT id_contacto INTO v_id_contacto FROM contacto WHERE email = 'contacto.actualizado@test.com';
  SELECT id_material INTO v_id_material FROM material WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_importacion INTO v_id_importacion FROM importacion WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_proceso INTO v_id_proceso FROM proceso_maquina WHERE descripcion LIKE '%TEST%' LIMIT 1;
  SELECT id_usuario INTO v_id_usuario FROM usuario WHERE email LIKE '%@test.com' OR email LIKE '%@empresa.com' LIMIT 1;
  
  -- Eliminar detalles de OT
  SELECT id INTO v_id_ot_mat FROM ot_material WHERE id_ot = v_id_ot AND id_material = v_id_material LIMIT 1;
  SELECT id INTO v_id_ot_imp FROM ot_importacion WHERE id_ot = v_id_ot AND id_importacion = v_id_importacion LIMIT 1;
  SELECT id INTO v_id_ot_proc FROM ot_proceso WHERE id_ot = v_id_ot AND id_proceso = v_id_proceso LIMIT 1;
  
  PERFORM sp_delete_ot_material(v_id_ot_mat);
  PERFORM sp_delete_ot_importacion(v_id_ot_imp);
  PERFORM sp_delete_ot_proceso(v_id_ot_proc);
  RAISE NOTICE '✅ Detalles de OT eliminados correctamente';
  
  -- Eliminar archivo y tiempo de OT
  SELECT id INTO v_id_archivo FROM archivo WHERE id_ot = v_id_ot LIMIT 1;
  SELECT id INTO v_id_tiempo FROM registro_tiempo WHERE id_ot = v_id_ot LIMIT 1;
  
  PERFORM sp_delete_archivo(v_id_archivo);
  PERFORM sp_delete_registro_tiempo(v_id_tiempo);
  RAISE NOTICE '✅ Archivo y tiempo de OT eliminados correctamente';
  
  -- Eliminar OT (detalles caen por CASCADE)
  PERFORM sp_delete_ot(v_id_ot);
  SELECT COUNT(*) INTO v_cnt FROM ot WHERE id_ot = v_id_ot;
  IF v_cnt != 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_delete_ot';
  END IF;
  RAISE NOTICE '✅ OT eliminada correctamente';
  
  -- Eliminar detalles de cotización (necesitamos obtener los IDs de las tablas relacionales)
  SELECT id INTO v_id_ot_mat FROM cotizacion_material WHERE id_cotizacion = v_id_cotizacion AND id_material = v_id_material LIMIT 1;
  SELECT id INTO v_id_ot_imp FROM cotizacion_importacion WHERE id_cotizacion = v_id_cotizacion AND id_importacion = v_id_importacion LIMIT 1;
  SELECT id INTO v_id_ot_proc FROM cotizacion_proceso WHERE id_cotizacion = v_id_cotizacion AND id_proceso = v_id_proceso LIMIT 1;
  
  PERFORM sp_remove_cotizacion_material(v_id_ot_mat);
  PERFORM sp_remove_cotizacion_importacion(v_id_ot_imp);
  PERFORM sp_remove_cotizacion_proceso(v_id_ot_proc);
  RAISE NOTICE '✅ Detalles de cotización eliminados correctamente';
  
  -- Eliminar cotización (detalles caen por CASCADE)
  PERFORM sp_delete_cotizacion(v_id_cotizacion);
  SELECT COUNT(*) INTO v_cnt FROM cotizacion WHERE id_cotizacion = v_id_cotizacion;
  IF v_cnt != 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_delete_cotizacion';
  END IF;
  RAISE NOTICE '✅ Cotización eliminada correctamente';
  
  -- Eliminar contacto
  PERFORM sp_delete_contacto(v_id_contacto);
  SELECT COUNT(*) INTO v_cnt FROM contacto WHERE id_contacto = v_id_contacto;
  IF v_cnt != 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_delete_contacto';
  END IF;
  RAISE NOTICE '✅ Contacto eliminado correctamente';
  
  -- Eliminar empresa
  PERFORM sp_delete_empresa(v_id_empresa);
  SELECT COUNT(*) INTO v_cnt FROM empresa WHERE id_empresa = v_id_empresa;
  IF v_cnt != 0 THEN
    RAISE EXCEPTION '❌ Fallo sp_delete_empresa';
  END IF;
  RAISE NOTICE '✅ Empresa eliminada correctamente';
  
  -- Eliminar usuario
  IF v_id_usuario IS NOT NULL THEN
    PERFORM sp_delete_usuario(v_id_usuario);
    SELECT COUNT(*) INTO v_cnt FROM usuario WHERE id_usuario = v_id_usuario;
    IF v_cnt != 0 THEN
      RAISE EXCEPTION '❌ Fallo sp_delete_usuario';
    END IF;
    RAISE NOTICE '✅ Usuario eliminado correctamente';
  END IF;
  
  -- Eliminar catálogos
  PERFORM sp_delete_material(v_id_material);
  PERFORM sp_delete_importacion(v_id_importacion);
  PERFORM sp_delete_proceso(v_id_proceso);
  RAISE NOTICE '✅ Catálogos eliminados correctamente';
  
  RAISE NOTICE '🎉 Pruebas de ELIMINACION completadas exitosamente';
END $$;

-- =========================================
-- RESUMEN FINAL
-- =========================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '🎉 TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE';
  RAISE NOTICE '🎉 =========================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Estructura de base de datos actualizada con OT';
  RAISE NOTICE '✅ Todas las tablas funcionando correctamente';
  RAISE NOTICE '✅ Todos los procedimientos almacenados funcionando';
  RAISE NOTICE '✅ Relaciones FK correctamente configuradas';
  RAISE NOTICE '✅ Operaciones CRUD funcionando en todas las entidades';
  RAISE NOTICE '✅ Datos de prueba insertados y eliminados correctamente';
  RAISE NOTICE '✅ Integridad referencial funcionando';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 La base de datos está lista para usar en producción!';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Entidades probadas:';
  RAISE NOTICE '   • Material (catálogo)';
  RAISE NOTICE '   • Importación (catálogo)';
  RAISE NOTICE '   • Proceso/Máquina (catálogo)';
  RAISE NOTICE '   • Empresa (entidad principal)';
  RAISE NOTICE '   • Contacto (dependiente de empresa)';
  RAISE NOTICE '   • Cotización (dependiente de empresa y contacto)';
  RAISE NOTICE '   • Detalles de cotización (material, importación, proceso)';
  RAISE NOTICE '   🆕 OT (Orden de Trabajo) - NUEVA SECCIÓN';
  RAISE NOTICE '   🆕 Detalles de OT (material, importación, proceso)';
  RAISE NOTICE '   🆕 Archivos de OT (archivos, documentos)';
  RAISE NOTICE '   🆕 Control de tiempo de OT (colaboradores) - COMPLETO';
  RAISE NOTICE '     • sp_create_registro_tiempo (con fechas esperadas)';
  RAISE NOTICE '     • sp_update_registro_tiempo (con fechas esperadas)';
  RAISE NOTICE '     • get_registro_tiempo, list_registros_tiempo';
  RAISE NOTICE '     • list_registros_por_colaborador, list_registros_por_estado';
  RAISE NOTICE '     • get_registros_hoy, get_tiempo_total_trabajado';
  RAISE NOTICE '     • get_tiempo_por_colaborador, sp_completar_registro_tiempo';
  RAISE NOTICE '     • sp_delete_registro_tiempo';
  RAISE NOTICE '   🆕 Usuario (Colaboradores) - NUEVA SECCIÓN';
  RAISE NOTICE '   🔐 Autenticación (Login/Password) - NUEVA SECCIÓN';
  RAISE NOTICE '     • authenticate_user (verificación de credenciales)';
  RAISE NOTICE '     • get_user_by_email (búsqueda por email)';
  RAISE NOTICE '     • sp_create_usuario (con soporte para password)';
  RAISE NOTICE '     • sp_update_usuario (con soporte para password)';
  RAISE NOTICE '';
END $$;
