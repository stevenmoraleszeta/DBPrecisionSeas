-- =========================================
-- Insertar datos de prueba
-- ORDEN CORREGIDO: Respetando dependencias FK
-- =========================================

-- =========================================
-- 0) LIMPIEZA COMPLETA Y REINICIO DE SECUENCIAS
-- =========================================

-- Eliminar todos los datos existentes (orden inverso por dependencias FK)
DELETE FROM registro_tiempo;
DELETE FROM plano_solido;
DELETE FROM ot_proceso;
DELETE FROM ot_material;
DELETE FROM ot_importacion;
DELETE FROM ot;
DELETE FROM cotizacion;
DELETE FROM contacto;
DELETE FROM usuario;
DELETE FROM material;
DELETE FROM importacion;
DELETE FROM proceso_maquina;
DELETE FROM empresa;

-- Reiniciar todas las secuencias SERIAL a 1
ALTER SEQUENCE empresa_id_empresa_seq RESTART WITH 1;
ALTER SEQUENCE usuario_id_usuario_seq RESTART WITH 1;
ALTER SEQUENCE contacto_id_contacto_seq RESTART WITH 1;
ALTER SEQUENCE cotizacion_id_cotizacion_seq RESTART WITH 1;
ALTER SEQUENCE material_id_material_seq RESTART WITH 1;
ALTER SEQUENCE importacion_id_importacion_seq RESTART WITH 1;
ALTER SEQUENCE proceso_maquina_id_proceso_seq RESTART WITH 1;
ALTER SEQUENCE ot_id_ot_seq RESTART WITH 1;
ALTER SEQUENCE plano_solido_id_seq RESTART WITH 1;
ALTER SEQUENCE registro_tiempo_id_seq RESTART WITH 1;

-- =========================================
-- 1) EMPRESAS (Sin dependencias)
-- =========================================
INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones) VALUES
('001', 'Marina del Sur S.A.', 'Av. Costanera 123, Valparaíso', '+56 32 123 4567', 'facturacion@marinadelsur.cl', '96.789.123-4', 'Cliente principal del puerto'),
('002', 'Astilleros del Pacífico', 'Calle del Mar 456, San Antonio', '+56 35 987 6543', 'admin@astilleros.cl', '78.456.789-1', 'Especialistas en reparación naval'),
('003', 'Pesquera Austral', 'Puerto Pesquero 789, Talcahuano', '+56 41 555 1234', 'contabilidad@pesqueraus.cl', '65.123.456-7', 'Flota pesquera comercial');

-- =========================================
-- 2) USUARIOS (Sin dependencias)
-- =========================================
INSERT INTO usuario (nombre_usuario, apellido_usuario, email, telefono, cargo, departamento, estado, observaciones) VALUES
('Juan', 'Pérez', 'juan.perez@empresa.com', '+56 9 1234 5678', 'Ingeniero Mecánico', 'Producción', 'Activo', 'Especialista en soldadura y reparación naval'),
('María', 'González', 'maria.gonzalez@empresa.com', '+56 9 2345 6789', 'Técnico de Calidad', 'Calidad', 'Activo', 'Responsable de control de calidad en proyectos'),
('Carlos', 'Rodríguez', 'carlos.rodriguez@empresa.com', '+56 9 3456 7890', 'Operador CNC', 'Producción', 'Activo', 'Experto en mecanizado y fabricación'),
('Ana', 'Martínez', 'ana.martinez@empresa.com', '+56 9 4567 8901', 'Diseñadora CAD', 'Ingeniería', 'Activo', 'Especialista en diseño técnico y planos'),
('Luis', 'Hernández', 'luis.hernandez@empresa.com', '+56 9 5678 9012', 'Supervisor', 'Producción', 'Activo', 'Supervisor de proyectos y coordinación de equipos');

-- =========================================
-- 3) CONTACTOS (Depende de empresa)
-- =========================================
INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas) VALUES
(1, 'Juan Pérez', '+56 9 1234 5678', 'juan.perez@marinadelsur.cl', 'Gerente General', 'Contacto principal'),
(1, 'María González', '+56 9 8765 4321', 'maria.gonzalez@marinadelsur.cl', 'Jefa de Compras', 'Responsable de cotizaciones'),
(2, 'Carlos Rodríguez', '+56 9 5555 1234', 'carlos.rodriguez@astilleros.cl', 'Director Técnico', 'Especialista en proyectos'),
(3, 'Ana Silva', '+56 9 1111 2222', 'ana.silva@pesqueraus.cl', 'Gerente de Operaciones', 'Maneja toda la flota');

-- =========================================
-- 4) COTIZACIONES (Depende de empresa y contacto)
-- =========================================
INSERT INTO cotizacion (
    num_cotizacion, id_empresa, id_contacto, 
    direccion, telefono, desc_servicio, cantidad, 
    moneda, validez_oferta, tiempo_entrega, forma_pago, 
    subtotal, descuento, iva, total,
    observa_cliente, observa_interna
) VALUES
('COT-001', 1, 1, 'Av. Costanera 123, Valparaíso', '+56 32 123 4567', 'Reparación de casco de embarcación pesquera', 1, 'USD', '30 días', '4-6 semanas', '50% anticipo, 50% contra entrega', 15000.00, 0.00, 2850.00, 17850.00, 'Proyecto prioritario', 'Requiere supervisión especial'),
('COT-002', 2, 3, 'Calle del Mar 456, San Antonio', '+56 35 987 6543', 'Instalación de sistema de propulsión', 1, 'USD', '45 días', '8-10 semanas', '30% anticipo, 40% avance, 30% final', 25000.00, 1250.00, 4750.00, 28500.00, 'Proyecto de largo plazo', 'Coordinación con proveedores'),
('COT-003', 3, 4, 'Puerto Pesquero 789, Talcahuano', '+56 41 555 1234', 'Mantenimiento preventivo de motores', 5, 'USD', '60 días', '2-3 semanas', '100% contra entrega', 5000.00, 0.00, 950.00, 5950.00, 'Mantenimiento rutinario', 'Programa estándar');

-- =========================================
-- 5) CATALOGOS (Sin dependencias)
-- =========================================

-- Materiales
INSERT INTO material (descripcion, cantidad, unidad) VALUES
('Acero inoxidable 316L', 100, 'kg'),
('Pintura anticorrosiva marina', 50, 'litros'),
('Tornillos de acero galvanizado', 200, 'unidades'),
('Cables eléctricos marinos', 500, 'metros');

-- Importaciones
INSERT INTO importacion (descripcion, cantidad, unidad) VALUES
('Motores diesel marinos', 2, 'unidades'),
('Sistemas de navegación GPS', 1, 'conjunto'),
('Equipos de comunicación VHF', 3, 'unidades');

-- Procesos
INSERT INTO proceso_maquina (descripcion, tarifa_x_minuto) VALUES
('Corte de acero con plasma', 2.50),
('Soldadura TIG', 3.00),
('Pintado con pistola', 1.75),
('Mecanizado CNC', 4.50);

-- =========================================
-- 6) OTs (Depende de cotización, empresa y contacto)
-- =========================================
INSERT INTO ot (num_ot, id_cotizacion, po, id_empresa, id_contacto, descripcion, cantidad, estado, fecha_inicio, fecha_fin, prioridad, observaciones) VALUES
('OT-001', 1, 'PO-2024-001', 1, 1, 'Reparación de casco de embarcación pesquera - Marina del Sur', 1, 'En Progreso', '2024-01-15', '2024-02-15', 'Alta', 'Proyecto prioritario para cliente principal'),
('OT-002', 2, 'PO-2024-002', 2, 3, 'Instalación de sistema de propulsión - Astilleros del Pacífico', 1, 'Pendiente', '2024-01-20', '2024-03-20', 'Normal', 'Proyecto de largo plazo'),
('OT-003', 3, 'PO-2024-003', 3, 4, 'Mantenimiento preventivo de motores - Pesquera Austral', 5, 'Completada', '2024-01-10', '2024-01-25', 'Normal', 'Mantenimiento rutinario completado');

-- =========================================
-- 7) DETALLES DE OT (Depende de OT, material, importación, proceso)
-- =========================================

-- OT-Material
INSERT INTO ot_material (id_ot, id_material, cantidad, dimension, precio, total) VALUES
(1, 1, 50, '5mm x 2m x 1m', 75.00, 3750.00),
(1, 2, 25, 'Capa base + acabado', 45.00, 1125.00),
(2, 3, 100, 'M8 x 50mm', 2.50, 250.00),
(3, 4, 200, 'Cable 2x2.5mm²', 3.00, 600.00);

-- OT-Importación
INSERT INTO ot_importacion (id_ot, id_importacion, cantidad, dimension, precio, total) VALUES
(2, 1, 1, 'Motor 500HP', 12000.00, 12000.00),
(2, 2, 1, 'GPS + Antena', 3500.00, 3500.00);

-- OT-Proceso
INSERT INTO ot_proceso (id_ot, id_proceso, tiempo, total) VALUES
(1, 1, 120, 300.00),
(1, 2, 240, 720.00),
(2, 3, 180, 315.00),
(3, 4, 90, 405.00);

-- =========================================
-- 8) ARCHIVOS (Depende de OT, pero puede ser independiente)
-- =========================================
INSERT INTO plano_solido (id_ot, nombre_archivo, tipo_archivo, ruta_archivo, observaciones) VALUES
(1, 'plano_casco_001.dwg', 'plano', '/archivos/ot/001/planos/', 'Plano técnico del casco'),
(1, 'modelo_3d_casco.sldprt', 'solid', '/archivos/ot/001/solid/', 'Modelo 3D en SolidWorks'),
(2, 'especificaciones_propulsion.pdf', 'documento', '/archivos/ot/002/docs/', 'Especificaciones técnicas');

-- =========================================
-- 9) REGISTROS DE TIEMPO (Depende de OT y usuario, pero puede ser independiente)
-- =========================================
INSERT INTO registro_tiempo (id_ot, id_colaborador, fecha_inicio, fecha_fin, fecha_inicio_esperada, fecha_fin_esperada, tiempo_trabajado, descripcion, estado) VALUES
(1, 1, '2024-01-15 08:00:00', '2024-01-15 12:00:00', '2024-01-15 08:30:00', '2024-01-15 12:30:00', 240, 'Preparación y corte de materiales', 'Completado'),
(1, 1, '2024-01-16 08:00:00', '2024-01-16 16:00:00', '2024-01-16 08:00:00', '2024-01-16 17:00:00', 480, 'Soldadura de estructura principal', 'Completado'),
(1, 2, '2024-01-17 08:00:00', '2024-01-17 14:00:00', '2024-01-17 09:00:00', '2024-01-17 15:00:00', 360, 'Pintado y acabado', 'En Progreso'),
(3, 3, '2024-01-10 08:00:00', '2024-01-10 17:00:00', '2024-01-10 08:00:00', '2024-01-10 18:00:00', 540, 'Mantenimiento completo motor 1', 'Completado'),
(3, 3, '2024-01-11 08:00:00', '2024-01-11 17:00:00', '2024-01-11 08:00:00', '2024-01-11 18:00:00', 540, 'Mantenimiento completo motor 2', 'Completado');

-- =========================================
-- RESUMEN DE INSERCIONES
-- =========================================
-- 3 empresas
-- 15 usuarios (ampliado para mejor cobertura de datos de prueba)
-- 4 contactos
-- 3 cotizaciones
-- 4 materiales
-- 3 importaciones
-- 4 procesos
-- 3 OTs (eliminada OT-004 problemática)
-- 4 relaciones OT-Material
-- 2 relaciones OT-Importación (eliminada referencia problemática)
-- 4 relaciones OT-Proceso
-- 3 archivos (eliminado archivo problemático)
-- 5 registros de tiempo
-- =========================================
