-- =========================================
-- Insertar datos de prueba
-- =========================================

-- Insertar empresas de prueba
INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones) VALUES
('001', 'Marina del Sur S.A.', 'Av. Costanera 123, Valparaíso', '+56 32 123 4567', 'facturacion@marinadelsur.cl', '96.789.123-4', 'Cliente principal del puerto'),
('002', 'Astilleros del Pacífico', 'Calle del Mar 456, San Antonio', '+56 35 987 6543', 'admin@astilleros.cl', '78.456.789-1', 'Especialistas en reparación naval'),
('003', 'Pesquera Austral', 'Puerto Pesquero 789, Talcahuano', '+56 41 555 1234', 'contabilidad@pesqueraus.cl', '65.123.456-7', 'Flota pesquera comercial');

-- Insertar contactos de prueba (usando id_empresa en lugar de cod_empresa)
INSERT INTO contacto (id_empresa, nombre_contacto, telefono, email, puesto, notas) VALUES
(1, 'Juan Pérez', '+56 9 1234 5678', 'juan.perez@marinadelsur.cl', 'Gerente General', 'Contacto principal'),
(1, 'María González', '+56 9 8765 4321', 'maria.gonzalez@marinadelsur.cl', 'Jefa de Compras', 'Responsable de cotizaciones'),
(2, 'Carlos Rodríguez', '+56 9 5555 1234', 'carlos.rodriguez@astilleros.cl', 'Director Técnico', 'Especialista en proyectos'),
(3, 'Ana Silva', '+56 9 1111 2222', 'ana.silva@pesqueraus.cl', 'Gerente de Operaciones', 'Maneja toda la flota');

-- Insertar cotizaciones de prueba (usando id_empresa en lugar de cod_empresa)
INSERT INTO cotizacion (num_cotizacion, id_empresa, id_contacto, desc_servicio, cantidad, moneda, validez_oferta, tiempo_entrega, forma_pago, subtotal, descuento, iva, total) VALUES
('COT-001', 1, 1, 'Reparación de casco de embarcación pesquera', 1, 'USD', '30 días', '4-6 semanas', '50% anticipo, 50% contra entrega', 15000.00, 0.00, 2850.00, 17850.00),
('COT-002', 2, 3, 'Instalación de sistema de propulsión', 1, 'USD', '45 días', '8-10 semanas', '30% anticipo, 40% avance, 30% final', 25000.00, 1250.00, 4750.00, 28500.00),
('COT-003', 3, 4, 'Mantenimiento preventivo de motores', 5, 'USD', '60 días', '2-3 semanas', '100% contra entrega', 5000.00, 0.00, 950.00, 5950.00);

-- Insertar materiales de prueba
INSERT INTO material (descripcion, cantidad, unidad) VALUES
('Acero inoxidable 316L', 100, 'kg'),
('Pintura anticorrosiva marina', 50, 'litros'),
('Tornillos de acero galvanizado', 200, 'unidades'),
('Cables eléctricos marinos', 500, 'metros');

-- Insertar importaciones de prueba
INSERT INTO importacion (descripcion, cantidad, unidad) VALUES
('Motores diesel marinos', 2, 'unidades'),
('Sistemas de navegación GPS', 1, 'conjunto'),
('Equipos de comunicación VHF', 3, 'unidades');

-- Insertar procesos de prueba
INSERT INTO proceso_maquina (descripcion, tarifa_x_minuto) VALUES
('Corte de acero con plasma', 2.50),
('Soldadura TIG', 3.00),
('Pintado con pistola', 1.75),
('Mecanizado CNC', 4.50);

-- =========================================
-- DATOS DE PRUEBA PARA OT (Orden de Trabajo)
-- =========================================

-- Insertar OTs de prueba
INSERT INTO ot (num_ot, id_cotizacion, po, id_empresa, id_contacto, descripcion, cantidad, id_colaborador, estado, fecha_inicio, fecha_fin, prioridad, observaciones) VALUES
('OT-001', 1, 'PO-2024-001', 1, 1, 'Reparación de casco de embarcación pesquera - Marina del Sur', 1, 1, 'En Progreso', '2024-01-15', '2024-02-15', 'Alta', 'Proyecto prioritario para cliente principal'),
('OT-002', 2, 'PO-2024-002', 2, 3, 'Instalación de sistema de propulsión - Astilleros del Pacífico', 1, 2, 'Pendiente', '2024-01-20', '2024-03-20', 'Normal', 'Proyecto de largo plazo'),
('OT-003', 3, 'PO-2024-003', 3, 4, 'Mantenimiento preventivo de motores - Pesquera Austral', 5, 3, 'Completada', '2024-01-10', '2024-01-25', 'Normal', 'Mantenimiento rutinario completado'),
('OT-004', NULL, 'PO-2024-004', 1, 2, 'Fabricación de piezas especiales para embarcación', 10, 1, 'Pendiente', '2024-02-01', '2024-02-28', 'Media', 'Piezas personalizadas para proyecto especial');

-- Insertar relaciones OT-Material de prueba
INSERT INTO ot_material (id_ot, id_material, cantidad, dimension, precio, total) VALUES
(1, 1, 50, '5mm x 2m x 1m', 75.00, 3750.00),
(1, 2, 25, 'Capa base + acabado', 45.00, 1125.00),
(2, 3, 100, 'M8 x 50mm', 2.50, 250.00),
(3, 4, 200, 'Cable 2x2.5mm²', 3.00, 600.00);

-- Insertar relaciones OT-Importación de prueba
INSERT INTO ot_importacion (id_ot, id_importacion, cantidad, dimension, precio, total) VALUES
(2, 1, 1, 'Motor 500HP', 12000.00, 12000.00),
(2, 2, 1, 'GPS + Antena', 3500.00, 3500.00),
(4, 3, 2, 'VHF 25W', 800.00, 1600.00);

-- Insertar relaciones OT-Proceso de prueba
INSERT INTO ot_proceso (id_ot, id_proceso, tiempo, total) VALUES
(1, 1, 120, 300.00),  -- 2 horas de corte
(1, 2, 240, 720.00),  -- 4 horas de soldadura
(2, 3, 180, 315.00),  -- 3 horas de pintado
(3, 4, 90, 405.00);   -- 1.5 horas de mecanizado

-- Insertar archivos de prueba para OT
INSERT INTO ot_plano_solido (id_ot, nombre_archivo, tipo_archivo, ruta_archivo, observaciones) VALUES
(1, 'plano_casco_001.dwg', 'plano', '/archivos/ot/001/planos/', 'Plano técnico del casco'),
(1, 'modelo_3d_casco.sldprt', 'solid', '/archivos/ot/001/solid/', 'Modelo 3D en SolidWorks'),
(2, 'especificaciones_propulsion.pdf', 'documento', '/archivos/ot/002/docs/', 'Especificaciones técnicas'),
(4, 'dibujo_piezas.dxf', 'plano', '/archivos/ot/004/planos/', 'Dibujo de piezas especiales');

-- Insertar registros de tiempo de prueba
INSERT INTO ot_registro_tiempo (id_ot, id_colaborador, fecha_inicio, fecha_fin, tiempo_trabajado, descripcion, estado) VALUES
(1, 1, '2024-01-15 08:00:00', '2024-01-15 12:00:00', 240, 'Preparación y corte de materiales', 'Completado'),
(1, 1, '2024-01-16 08:00:00', '2024-01-16 16:00:00', 480, 'Soldadura de estructura principal', 'Completado'),
(1, 2, '2024-01-17 08:00:00', '2024-01-17 14:00:00', 360, 'Pintado y acabado', 'En Progreso'),
(3, 3, '2024-01-10 08:00:00', '2024-01-10 17:00:00', 540, 'Mantenimiento completo motor 1', 'Completado'),
(3, 3, '2024-01-11 08:00:00', '2024-01-11 17:00:00', 540, 'Mantenimiento completo motor 2', 'Completado');
