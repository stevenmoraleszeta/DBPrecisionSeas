-- =========================================
-- SCRIPT PARA CREAR USUARIO ADMINISTRADOR
-- =========================================
-- Email: admin@precisionseas.com
-- Contraseña: Admin123!
-- =========================================

-- Verificar si el usuario ya existe y crear/actualizar según corresponda
DO $$
DECLARE
    v_admin_exists BOOLEAN;
    v_admin_id INT;
BEGIN
    -- Verificar si el usuario admin ya existe
    SELECT EXISTS(SELECT 1 FROM usuario WHERE email = 'admin@precisionseas.com') INTO v_admin_exists;
    
    IF v_admin_exists THEN
        -- Actualizar usuario existente
        UPDATE usuario 
        SET 
            nombre_usuario = 'Admin',
            apellido_usuario = 'Sistema',
            email = 'admin@precisionseas.com',
            telefono = '+56 9 1234 5678',
            cargo = 'Administrador',
            departamento = 'Sistemas',
            estado = 'Activo',
            password = '$2b$12$9gxm/hfdjTWZgdv6i0y/ueU1jERhT2GgLXY1RmYh/C504OYS6YbBO',
            observaciones = 'Usuario administrador principal del sistema Precision Seas ERP',
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE email = 'admin@precisionseas.com'
        RETURNING id_usuario INTO v_admin_id;
        
        RAISE NOTICE '✅ Usuario admin actualizado exitosamente (ID: %)', v_admin_id;
    ELSE
        -- Crear nuevo usuario admin
        INSERT INTO usuario (
            nombre_usuario, 
            apellido_usuario, 
            email, 
            telefono, 
            cargo, 
            departamento, 
            estado, 
            password,
            observaciones
        ) VALUES (
            'Admin', 
            'Sistema', 
            'admin@precisionseas.com', 
            '+56 9 1234 5678', 
            'Administrador', 
            'Sistemas', 
            'Activo', 
            '$2b$12$9gxm/hfdjTWZgdv6i0y/ueU1jERhT2GgLXY1RmYh/C504OYS6YbBO',
            'Usuario administrador principal del sistema Precision Seas ERP'
        ) RETURNING id_usuario INTO v_admin_id;
        
        RAISE NOTICE '✅ Usuario admin creado exitosamente (ID: %)', v_admin_id;
    END IF;
    
    -- Verificar que el usuario se creó/actualizó correctamente
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION '❌ Error: No se pudo obtener el ID del usuario';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✓ USUARIO ADMINISTRADOR CONFIGURADO';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Email: admin@precisionseas.com';
    RAISE NOTICE 'Contraseña: Admin123!';
    RAISE NOTICE 'Estado: Activo';
    RAISE NOTICE '========================================';
    
END $$;

-- =========================================
-- VERIFICAR CREACIÓN DEL USUARIO
-- =========================================
SELECT 
    id_usuario,
    nombre_usuario,
    apellido_usuario,
    email,
    telefono,
    cargo,
    departamento,
    estado,
    password IS NOT NULL AS tiene_password,
    fecha_creacion,
    fecha_actualizacion
FROM usuario 
WHERE email = 'admin@precisionseas.com';

