-- =========================================
-- Insertar datos de prueba
-- =========================================

-- Insertar empresas de prueba
INSERT INTO empresa (cod_empresa, nombre_empresa, direccion, telefono, email_factura, cedula, observaciones) VALUES
('EMP001', 'Marina del Sur S.A.', 'Av. Costanera 123, Valparaíso', '+56 32 123 4567', 'facturacion@marinadelsur.cl', '96.789.123-4', 'Cliente principal del puerto'),
('EMP002', 'Astilleros del Pacífico', 'Calle del Mar 456, San Antonio', '+56 35 987 6543', 'admin@astilleros.cl', '78.456.789-1', 'Especialistas en reparación naval'),
('EMP003', 'Pesquera Austral', 'Puerto Pesquero 789, Talcahuano', '+56 41 555 1234', 'contabilidad@pesqueraus.cl', '65.123.456-7', 'Flota pesquera comercial');

-- Insertar contactos de prueba
INSERT INTO contacto (cod_empresa, nombre_contacto, telefono, email, puesto, notas) VALUES
('EMP001', 'Juan Pérez', '+56 9 1234 5678', 'juan.perez@marinadelsur.cl', 'Gerente General', 'Contacto principal'),
('EMP001', 'María González', '+56 9 8765 4321', 'maria.gonzalez@marinadelsur.cl', 'Jefa de Compras', 'Responsable de cotizaciones'),
('EMP002', 'Carlos Rodríguez', '+56 9 5555 1234', 'carlos.rodriguez@astilleros.cl', 'Director Técnico', 'Especialista en proyectos'),
('EMP003', 'Ana Silva', '+56 9 1111 2222', 'ana.silva@pesqueraus.cl', 'Gerente de Operaciones', 'Maneja toda la flota');

-- Insertar cotizaciones de prueba
INSERT INTO cotizacion (num_cotizacion, cod_empresa, id_contacto, desc_servicio, cantidad, moneda, validez_oferta, tiempo_entrega, forma_pago, subtotal, descuento, iva, total) VALUES
('COT-001', 'EMP001', 1, 'Reparación de casco de embarcación pesquera', 1, 'USD', '30 días', '4-6 semanas', '50% anticipo, 50% contra entrega', 15000.00, 0.00, 2850.00, 17850.00),
('COT-002', 'EMP002', 3, 'Instalación de sistema de propulsión', 1, 'USD', '45 días', '8-10 semanas', '30% anticipo, 40% avance, 30% final', 25000.00, 1250.00, 4750.00, 28500.00),
('COT-003', 'EMP003', 4, 'Mantenimiento preventivo de motores', 5, 'USD', '60 días', '2-3 semanas', '100% contra entrega', 5000.00, 0.00, 950.00, 5950.00);

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
