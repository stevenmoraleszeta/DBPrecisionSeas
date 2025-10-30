-- =========================================
-- ADD PASSWORD FIELD TO USUARIO TABLE
-- =========================================

-- Add password field to usuario table
ALTER TABLE usuario 
ADD COLUMN password VARCHAR(255);

-- Add index for email (for login lookups)
CREATE INDEX IF NOT EXISTS idx_usuario_email_login ON usuario(email);

-- Add comment to document the password field
COMMENT ON COLUMN usuario.password IS 'Password hash for user authentication';

-- =========================================
-- UPDATE STORED PROCEDURES FOR PASSWORD
-- =========================================

-- Update sp_create_usuario to include password
CREATE OR REPLACE FUNCTION sp_create_usuario(
    p_nombre_usuario VARCHAR(100),
    p_apellido_usuario VARCHAR(100),
    p_email VARCHAR(255),
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_cargo VARCHAR(100) DEFAULT NULL,
    p_departamento VARCHAR(100) DEFAULT NULL,
    p_estado VARCHAR(20) DEFAULT 'Activo',
    p_observaciones TEXT DEFAULT NULL,
    p_password VARCHAR(255) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id_usuario INT;
    v_response JSON;
BEGIN
    -- Validar datos requeridos
    IF p_nombre_usuario IS NULL OR TRIM(p_nombre_usuario) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'El nombre del usuario es requerido'
        );
    END IF;
    
    IF p_apellido_usuario IS NULL OR TRIM(p_apellido_usuario) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'El apellido del usuario es requerido'
        );
    END IF;
    
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'El email del usuario es requerido'
        );
    END IF;
    
    -- Validar formato de email
    IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RETURN json_build_object(
            'success', false,
            'message', 'El formato del email no es válido'
        );
    END IF;
    
    -- Verificar si el email ya existe
    IF EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Ya existe un usuario con este email'
        );
    END IF;
    
    -- Insertar usuario
    INSERT INTO usuario (
        nombre_usuario, 
        apellido_usuario, 
        email, 
        telefono, 
        cargo, 
        departamento, 
        estado, 
        observaciones,
        password
    ) VALUES (
        p_nombre_usuario, 
        p_apellido_usuario, 
        p_email, 
        p_telefono, 
        p_cargo, 
        p_departamento, 
        p_estado, 
        p_observaciones,
        p_password
    ) RETURNING id_usuario INTO v_id_usuario;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Usuario creado exitosamente',
        'id_usuario', v_id_usuario
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error al crear usuario: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

-- Update sp_update_usuario to include password
CREATE OR REPLACE FUNCTION sp_update_usuario(
    p_id_usuario INT,
    p_nombre_usuario VARCHAR(100) DEFAULT NULL,
    p_apellido_usuario VARCHAR(100) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_cargo VARCHAR(100) DEFAULT NULL,
    p_departamento VARCHAR(100) DEFAULT NULL,
    p_estado VARCHAR(20) DEFAULT NULL,
    p_observaciones TEXT DEFAULT NULL,
    p_password VARCHAR(255) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_response JSON;
    v_update_fields TEXT[] := ARRAY[]::TEXT[];
    v_update_values TEXT[] := ARRAY[]::TEXT[];
    v_query TEXT;
    v_counter INT := 1;
BEGIN
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
    END IF;
    
    -- Validar email si se proporciona
    IF p_email IS NOT NULL THEN
        IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RETURN json_build_object(
                'success', false,
                'message', 'El formato del email no es válido'
            );
        END IF;
        
        -- Verificar si el email ya existe en otro usuario
        IF EXISTS (SELECT 1 FROM usuario WHERE email = p_email AND id_usuario != p_id_usuario) THEN
            RETURN json_build_object(
                'success', false,
                'message', 'Ya existe otro usuario con este email'
            );
        END IF;
    END IF;
    
    -- Construir query dinámicamente
    IF p_nombre_usuario IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'nombre_usuario = $' || v_counter);
        v_update_values := array_append(v_update_values, p_nombre_usuario);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_apellido_usuario IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'apellido_usuario = $' || v_counter);
        v_update_values := array_append(v_update_values, p_apellido_usuario);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_email IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'email = $' || v_counter);
        v_update_values := array_append(v_update_values, p_email);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_telefono IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'telefono = $' || v_counter);
        v_update_values := array_append(v_update_values, p_telefono);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_cargo IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'cargo = $' || v_counter);
        v_update_values := array_append(v_update_values, p_cargo);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_departamento IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'departamento = $' || v_counter);
        v_update_values := array_append(v_update_values, p_departamento);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_estado IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'estado = $' || v_counter);
        v_update_values := array_append(v_update_values, p_estado);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_observaciones IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'observaciones = $' || v_counter);
        v_update_values := array_append(v_update_values, p_observaciones);
        v_counter := v_counter + 1;
    END IF;
    
    IF p_password IS NOT NULL THEN
        v_update_fields := array_append(v_update_fields, 'password = $' || v_counter);
        v_update_values := array_append(v_update_values, p_password);
        v_counter := v_counter + 1;
    END IF;
    
    -- Agregar fecha_actualizacion
    v_update_fields := array_append(v_update_fields, 'fecha_actualizacion = CURRENT_TIMESTAMP');
    
    -- Si no hay campos para actualizar
    IF array_length(v_update_fields, 1) IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'No se proporcionaron campos para actualizar'
        );
    END IF;
    
    -- Construir y ejecutar query
    v_query := 'UPDATE usuario SET ' || array_to_string(v_update_fields, ', ') || ' WHERE id_usuario = $' || v_counter;
    v_update_values := array_append(v_update_values, p_id_usuario::TEXT);
    
    EXECUTE v_query USING v_update_values;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Usuario actualizado exitosamente'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error al actualizar usuario: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- AUTHENTICATION FUNCTIONS
-- =========================================

-- Function to authenticate user by email and password
CREATE OR REPLACE FUNCTION authenticate_user(
    p_email VARCHAR(255),
    p_password VARCHAR(255)
)
RETURNS JSON AS $$
DECLARE
    v_usuario RECORD;
    v_response JSON;
BEGIN
    -- Buscar usuario por email
    SELECT 
        id_usuario,
        nombre_usuario,
        apellido_usuario,
        email,
        telefono,
        cargo,
        departamento,
        estado,
        password,
        fecha_creacion,
        fecha_actualizacion,
        observaciones
    INTO v_usuario
    FROM usuario 
    WHERE email = p_email AND estado = 'Activo';
    
    -- Verificar si el usuario existe
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Credenciales inválidas'
        );
    END IF;
    
    -- Verificar si tiene password
    IF v_usuario.password IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Usuario no tiene contraseña configurada'
        );
    END IF;
    
    -- IMPORTANTE: La verificación de contraseña se hace en la aplicación con bcrypt
    -- Esta función solo retorna el usuario si existe y está activo
    -- La verificación real de la contraseña se hace en el servicio de Node.js
    
    RETURN json_build_object(
        'success', true,
        'message', 'Usuario encontrado',
        'data', json_build_object(
            'id_usuario', v_usuario.id_usuario,
            'nombre_usuario', v_usuario.nombre_usuario,
            'apellido_usuario', v_usuario.apellido_usuario,
            'email', v_usuario.email,
            'telefono', v_usuario.telefono,
            'cargo', v_usuario.cargo,
            'departamento', v_usuario.departamento,
            'estado', v_usuario.estado,
            'fecha_creacion', v_usuario.fecha_creacion,
            'fecha_actualizacion', v_usuario.fecha_actualizacion,
            'observaciones', v_usuario.observaciones,
            'password_hash', v_usuario.password
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error en autenticación: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

-- Function to get user by email (for login)
CREATE OR REPLACE FUNCTION get_user_by_email(p_email VARCHAR(255))
RETURNS JSON AS $$
DECLARE
    v_usuario RECORD;
    v_response JSON;
BEGIN
    -- Buscar usuario por email
    SELECT 
        id_usuario,
        nombre_usuario,
        apellido_usuario,
        email,
        telefono,
        cargo,
        departamento,
        estado,
        password,
        fecha_creacion,
        fecha_actualizacion,
        observaciones
    INTO v_usuario
    FROM usuario 
    WHERE email = p_email;
    
    -- Verificar si el usuario existe
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Usuario encontrado',
        'data', json_build_object(
            'id_usuario', v_usuario.id_usuario,
            'nombre_usuario', v_usuario.nombre_usuario,
            'apellido_usuario', v_usuario.apellido_usuario,
            'email', v_usuario.email,
            'telefono', v_usuario.telefono,
            'cargo', v_usuario.cargo,
            'departamento', v_usuario.departamento,
            'estado', v_usuario.estado,
            'fecha_creacion', v_usuario.fecha_creacion,
            'fecha_actualizacion', v_usuario.fecha_actualizacion,
            'observaciones', v_usuario.observaciones,
            'password_hash', v_usuario.password
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', 'Error al buscar usuario: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- CREATE/UPDATE ADMIN USER
-- =========================================

-- Create or update admin user with correct password hash
-- Password: Admin123!
-- Hash: $2b$12$oQpM2V0i0cAwxRw9nIdLEe9he12/QCKjVHr0SzO5RhZK2FHDMbpx2

-- First, check if admin user exists
DO $$
DECLARE
    v_admin_exists BOOLEAN;
    v_admin_id INT;
BEGIN
    -- Check if admin user exists
    SELECT EXISTS(SELECT 1 FROM usuario WHERE email = 'admin@precisionseas.com') INTO v_admin_exists;
    
    IF v_admin_exists THEN
        -- Update existing admin user with password
        UPDATE usuario 
        SET password = '$2b$12$oQpM2V0i0cAwxRw9nIdLEe9he12/QCKjVHr0SzO5RhZK2FHDMbpx2',
            nombre_usuario = 'Admin',
            apellido_usuario = 'Sistema',
            cargo = 'Administrador',
            departamento = 'Sistemas',
            estado = 'Activo',
            observaciones = 'Usuario administrador principal del sistema Precisión Seas ERP'
        WHERE email = 'admin@precisionseas.com';
        
        RAISE NOTICE '✅ Usuario admin actualizado con contraseña';
    ELSE
        -- Create new admin user
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
            '+56 9 0000 0000', 
            'Administrador', 
            'Sistemas', 
            'Activo', 
            '$2b$12$oQpM2V0i0cAwxRw9nIdLEe9he12/QCKjVHr0SzO5RhZK2FHDMbpx2',
            'Usuario administrador principal del sistema Precisión Seas ERP'
        );
        
        RAISE NOTICE '✅ Usuario admin creado con contraseña';
    END IF;
END $$;

-- =========================================
-- VERIFICATION QUERIES
-- =========================================

-- Verify admin user exists and has password
DO $$
DECLARE
    v_admin_record RECORD;
    v_auth_test JSON;
BEGIN
    -- Check admin user
    SELECT * INTO v_admin_record 
    FROM usuario 
    WHERE email = 'admin@precisionseas.com';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Usuario admin no encontrado';
    END IF;
    
    IF v_admin_record.password IS NULL THEN
        RAISE EXCEPTION '❌ Usuario admin no tiene contraseña';
    END IF;
    
    RAISE NOTICE '✅ Usuario admin verificado:';
    RAISE NOTICE '   - ID: %', v_admin_record.id_usuario;
    RAISE NOTICE '   - Email: %', v_admin_record.email;
    RAISE NOTICE '   - Nombre: % %', v_admin_record.nombre_usuario, v_admin_record.apellido_usuario;
    RAISE NOTICE '   - Estado: %', v_admin_record.estado;
    RAISE NOTICE '   - Tiene contraseña: %', CASE WHEN v_admin_record.password IS NOT NULL THEN 'SÍ' ELSE 'NO' END;
    
    -- Test authentication function
    SELECT authenticate_user('admin@precisionseas.com', 'Admin123!') INTO v_auth_test;
    
    IF v_auth_test->>'success' != 'true' THEN
        RAISE EXCEPTION '❌ Función authenticate_user falló: %', v_auth_test->>'message';
    END IF;
    
    RAISE NOTICE '✅ Función authenticate_user funcionando correctamente';
    
    -- Test get_user_by_email function
    SELECT get_user_by_email('admin@precisionseas.com') INTO v_auth_test;
    
    IF v_auth_test->>'success' != 'true' THEN
        RAISE EXCEPTION '❌ Función get_user_by_email falló: %', v_auth_test->>'message';
    END IF;
    
    RAISE NOTICE '✅ Función get_user_by_email funcionando correctamente';
    
    RAISE NOTICE '🎉 MIGRACIÓN COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '🎉 Sistema de autenticación listo para usar';
    RAISE NOTICE '🎉 Credenciales: admin@precisionseas.com / Admin123!';
    
END $$;
