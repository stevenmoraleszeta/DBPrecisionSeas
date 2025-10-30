-- =========================================
-- Insertar datos de prueba
-- ORDEN CORREGIDO: Respetando dependencias FK
-- =========================================

-- =========================================
-- 0) LIMPIEZA COMPLETA Y REINICIO DE SECUENCIAS
-- =========================================

-- Eliminar todos los datos existentes (orden inverso por dependencias FK)
DELETE FROM registro_tiempo;
DELETE FROM archivo;
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
ALTER SEQUENCE archivo_id_seq RESTART WITH 1;
ALTER SEQUENCE registro_tiempo_id_seq RESTART WITH 1;

-- =========================================
-- 1) EMPRESAS (Sin dependencias)
-- =========================================
INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones) VALUES
('001', 'TechMet Industries S.A.', 'Zona Franca de Cartago', '+506 2550 1234', 'facturacion@techmet.co.cr', '3-101-654321-8', 'Cliente principal en manufactura industrial'),
('002', 'Precisión Metálica del Pacífico', 'Parque Industrial La Uruca', '+506 2250 9876', 'compras@pmpacifica.co.cr', '3-102-789012-3', 'Especialistas en estructuras metálicas'),
('003', 'Aluminios y Estructuras S.A.', 'San José, Pavas', '+506 2296 5555', 'contabilidad@aluminios.co.cr', '3-103-456789-0', 'Fabricación de estructuras metálicas');

-- =========================================
-- 2) USUARIOS (Sin dependencias)
-- =========================================
INSERT INTO usuario (nombre_usuario, apellido_usuario, email, telefono, cargo, departamento, estado, password, observaciones) VALUES
('Admin', 'Sistema', 'admin@precisionseas.com', '+506 8319 0317', 'Administrador', 'Sistemas', 'Activo', '$2b$12$oQpM2V0i0cAwxRw9nIdLEe9he12/QCKjVHr0SzO5RhZK2FHDMbpx2', 'Usuario administrador principal del sistema'),
('Juan', 'Pérez', 'juan.perez@empresa.com', '+506 8319 1234', 'Ingeniero Mecánico', 'Producción', 'Activo', NULL, 'Especialista en soldadura y estructuras metálicas'),
('María', 'González', 'maria.gonzalez@empresa.com', '+506 8319 2345', 'Técnico de Calidad', 'Calidad', 'Activo', NULL, 'Responsable de control de calidad en proyectos'),
('Carlos', 'Rodríguez', 'carlos.rodriguez@empresa.com', '+506 8319 3456', 'Operador CNC', 'Producción', 'Activo', NULL, 'Experto en mecanizado y fabricación'),
('Ana', 'Martínez', 'ana.martinez@empresa.com', '+506 8319 4567', 'Diseñadora CAD', 'Ingeniería', 'Activo', NULL, 'Especialista en diseño técnico y planos'),
('Luis', 'Hernández', 'luis.hernandez@empresa.com', '+506 8319 5678', 'Supervisor', 'Producción', 'Activo', NULL, 'Supervisor de proyectos y coordinación de equipos');

-- =========================================
-- 3) CONTACTOS (Depende de empresa)
-- =========================================
INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas) VALUES
(1, 'Juan Pérez', '+506 2550 1234', 'juan.perez@techmet.co.cr', 'Gerente General', 'Contacto principal'),
(1, 'María González', '+506 2550 1235', 'maria.gonzalez@techmet.co.cr', 'Jefa de Compras', 'Responsable de cotizaciones'),
(2, 'Carlos Rodríguez', '+506 2250 9876', 'carlos.rodriguez@pmpacifica.co.cr', 'Director Técnico', 'Especialista en proyectos'),
(3, 'Ana Silva', '+506 2296 5555', 'ana.silva@aluminios.co.cr', 'Gerente de Operaciones', 'Coordinadora de proyectos');

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
('COT-001', 1, 1, 'Zona Franca de Cartago', '+506 2550 1234', 'Fabricación de estructura metálica para nave industrial', 1, 'USD', '30 días', '4-6 semanas', '50% anticipo, 50% contra entrega', 15000.00, 0.00, 2850.00, 17850.00, 'Proyecto prioritario', 'Requiere supervisión especial'),
('COT-002', 2, 3, 'Parque Industrial La Uruca', '+506 2250 9876', 'Instalación de sistema de ventilación industrial', 1, 'USD', '45 días', '8-10 semanas', '30% anticipo, 40% avance, 30% final', 25000.00, 1250.00, 4750.00, 28500.00, 'Proyecto de largo plazo', 'Coordinación con proveedores'),
('COT-003', 3, 4, 'San José, Pavas', '+506 2296 5555', 'Mantenimiento de estructuras metálicas', 5, 'USD', '60 días', '2-3 semanas', '100% contra entrega', 5000.00, 0.00, 950.00, 5950.00, 'Mantenimiento rutinario', 'Programa estándar');

-- =========================================
-- 5) CATALOGOS (Sin dependencias)
-- =========================================

-- Materiales
INSERT INTO material (descripcion, cantidad, unidad) VALUES
('Acero inoxidable 316L', 100, 'kg'),
('Pintura anticorrosiva industrial', 50, 'litros'),
('Tornillos de acero galvanizado', 200, 'unidades'),
('Cables eléctricos industriales', 500, 'metros');

-- Importaciones
INSERT INTO importacion (descripcion, cantidad, unidad) VALUES
('Motores eléctricos industriales', 2, 'unidades'),
('Sistemas de control automatizado', 1, 'conjunto'),
('Equipos de soldadura TIG', 3, 'unidades');

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
('OT-001', 1, 'PO-2025-001', 1, 1, 'Fabricación de estructura metálica - TechMet Industries', 1, 'En Progreso', '2025-01-15', '2025-02-15', 'Alta', 'Proyecto prioritario para cliente principal'),
('OT-002', 2, 'PO-2025-002', 2, 3, 'Instalación de sistema de ventilación - Precisión Metálica', 1, 'Pendiente', '2025-01-20', '2025-03-20', 'Normal', 'Proyecto de largo plazo'),
('OT-003', 3, 'PO-2025-003', 3, 4, 'Mantenimiento de estructuras - Aluminios y Estructuras', 5, 'Completada', '2025-01-10', '2025-01-25', 'Normal', 'Mantenimiento rutinario completado');

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
(2, 2, 1, 'Sistema de control automatizado', 3500.00, 3500.00);

-- OT-Proceso
INSERT INTO ot_proceso (id_ot, id_proceso, tiempo, total) VALUES
(1, 1, 120, 300.00),
(1, 2, 240, 720.00),
(2, 3, 180, 315.00),
(3, 4, 90, 405.00);

-- =========================================
-- 8) ARCHIVOS (Depende de OT, pero puede ser independiente)
-- =========================================
INSERT INTO archivo (
  id_ot, nombre_archivo, nombre_original, tipo_archivo, tipo_mime,
  tamano_archivo, ruta_archivo, observaciones, activo
) VALUES
(1, 'plano_estructura_001.dwg', 'plano_estructura_001.dwg', 'cad', 'application/dwg',
 2048576, 'uploads/planos/plano_estructura_001-1234567890-abc123.dwg', 
 'Plano técnico de estructura metálica', TRUE),
(1, 'modelo_3d_estructura.sldprt', 'modelo_3d_estructura.sldprt', 'cad', 'application/octet-stream',
 5242880, 'uploads/planos/modelo_3d_estructura-1234567891-def456.sldprt',
 'Modelo 3D en SolidWorks', TRUE),
(2, 'especificaciones_ventilacion.pdf', 'especificaciones_ventilacion.pdf', 'documento', 'application/pdf',
 1024000, 'uploads/documentos/especificaciones_ventilacion-1234567892-ghi789.pdf',
 'Especificaciones técnicas', TRUE),
(3, 'foto_estructura_1.jpg', 'foto_estructura_1.jpg', 'imagen', 'image/jpeg',
 512000, 'uploads/imagenes/foto_estructura_1-1234567893-jkl012.jpg',
 'Foto de la estructura antes del mantenimiento', TRUE),
(3, 'video_prueba_estructura.mp4', 'video_prueba_estructura.mp4', 'video', 'video/mp4',
 15728640, 'uploads/documentos/video_prueba_estructura-1234567894-mno345.mp4',
 'Video de prueba de la estructura', TRUE),
(NULL, 'manual_operacion_general.pdf', 'manual_operacion_general.pdf', 'documento', 'application/pdf',
 2048000, 'uploads/documentos/manual_operacion_general-1234567895-pqr678.pdf',
 'Manual general de operación (archivo independiente)', TRUE);

-- =========================================
-- 9) REGISTROS DE TIEMPO (Depende de OT y usuario, pero puede ser independiente)
-- =========================================
INSERT INTO registro_tiempo (id_ot, id_colaborador, fecha_inicio, fecha_fin, fecha_inicio_esperada, fecha_fin_esperada, tiempo_trabajado, descripcion, estado) VALUES
(1, 1, '2025-01-15 08:00:00', '2025-01-15 12:00:00', '2025-01-15 08:30:00', '2025-01-15 12:30:00', 240, 'Preparación y corte de materiales', 'Completado'),
(1, 1, '2025-01-16 08:00:00', '2025-01-16 16:00:00', '2025-01-16 08:00:00', '2025-01-16 17:00:00', 480, 'Soldadura de estructura principal', 'Completado'),
(1, 2, '2025-01-17 08:00:00', '2025-01-17 14:00:00', '2025-01-17 09:00:00', '2025-01-17 15:00:00', 360, 'Pintado y acabado', 'En Progreso'),
(3, 3, '2025-01-10 08:00:00', '2025-01-10 17:00:00', '2025-01-10 08:00:00', '2025-01-10 18:00:00', 540, 'Mantenimiento completo estructura 1', 'Completado'),
(3, 3, '2025-01-11 08:00:00', '2025-01-11 17:00:00', '2025-01-11 08:00:00', '2025-01-11 18:00:00', 540, 'Mantenimiento completo estructura 2', 'Completado');

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
-- 6 archivos (incluyendo diferentes tipos: CAD, documentos, imágenes, videos)
-- 5 registros de tiempo
-- =========================================
