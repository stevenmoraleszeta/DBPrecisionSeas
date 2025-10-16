-- =========================================
-- MIGRACIÓN: Agregar contraseñas a usuarios
-- =========================================

-- Agregar campo de contraseña a la tabla usuario
ALTER TABLE usuario 
ADD COLUMN password VARCHAR(255);

-- Agregar campo de salt para mayor seguridad (opcional, bcrypt ya incluye salt)
-- ALTER TABLE usuario 
-- ADD COLUMN salt VARCHAR(255);

-- Agregar campo de último login
ALTER TABLE usuario 
ADD COLUMN ultimo_login TIMESTAMP DEFAULT NULL;

-- Agregar campo de intentos de login fallidos
ALTER TABLE usuario 
ADD COLUMN intentos_fallidos INTEGER DEFAULT 0;

-- Agregar campo de bloqueado hasta
ALTER TABLE usuario 
ADD COLUMN bloqueado_hasta TIMESTAMP DEFAULT NULL;

-- Crear índice para búsqueda por email (ya existe pero lo verificamos)
-- CREATE INDEX IF NOT EXISTS idx_usuario_email ON usuario(email);

-- Crear índice para búsqueda por password
CREATE INDEX IF NOT EXISTS idx_usuario_password ON usuario(password);

-- Agregar comentarios a los nuevos campos
COMMENT ON COLUMN usuario.password IS 'Contraseña hasheada del usuario';
COMMENT ON COLUMN usuario.ultimo_login IS 'Fecha y hora del último login exitoso';
COMMENT ON COLUMN usuario.intentos_fallidos IS 'Número de intentos de login fallidos consecutivos';
COMMENT ON COLUMN usuario.bloqueado_hasta IS 'Fecha hasta la cual el usuario está bloqueado por intentos fallidos';

-- Actualizar trigger para incluir los nuevos campos en fecha_actualizacion
CREATE OR REPLACE FUNCTION update_usuario_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- El trigger ya existe, solo lo recreamos para asegurar que funcione
DROP TRIGGER IF EXISTS trigger_update_usuario_timestamp ON usuario;
CREATE TRIGGER trigger_update_usuario_timestamp
    BEFORE UPDATE ON usuario
    FOR EACH ROW
    EXECUTE FUNCTION update_usuario_timestamp();

-- =========================================
-- FUNCIÓN PARA HASH DE CONTRASEÑAS
-- =========================================

-- Crear función para generar hash de contraseña (será implementada en la aplicación)
-- Esta función es solo para documentar el proceso
CREATE OR REPLACE FUNCTION hash_password(raw_password TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Esta función será implementada en la aplicación Node.js con bcrypt
    -- Aquí solo documentamos que debe devolver un hash bcrypt
    RAISE EXCEPTION 'Esta función debe ser implementada en la aplicación Node.js con bcrypt';
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- FUNCIÓN PARA VERIFICAR CONTRASEÑA
-- =========================================

-- Crear función para verificar contraseña (será implementada en la aplicación)
CREATE OR REPLACE FUNCTION verify_password(raw_password TEXT, hashed_password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Esta función será implementada en la aplicación Node.js con bcrypt
    -- Aquí solo documentamos que debe comparar con bcrypt.compare()
    RAISE EXCEPTION 'Esta función debe ser implementada en la aplicación Node.js con bcrypt';
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTO PARA CREAR USUARIO CON CONTRASEÑA
-- =========================================

-- Actualizar el procedimiento sp_create_usuario para incluir contraseña
CREATE OR REPLACE FUNCTION sp_create_usuario(
    p_nombre_usuario VARCHAR(100),
    p_apellido_usuario VARCHAR(100),
    p_email VARCHAR(255),
    p_password VARCHAR(255), -- NUEVO PARÁMETRO
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_cargo VARCHAR(100) DEFAULT NULL,
    p_departamento VARCHAR(100) DEFAULT NULL,
    p_estado VARCHAR(20) DEFAULT 'Activo',
    p_observaciones TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id_usuario INTEGER;
    v_result JSON;
BEGIN
    -- Validar que la contraseña no esté vacía
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        v_result := json_build_object(
            'success', false,
            'message', 'La contraseña es requerida'
        );
        RETURN v_result;
    END IF;

    -- Insertar nuevo usuario con contraseña
    INSERT INTO usuario (
        nombre_usuario, 
        apellido_usuario, 
        email, 
        password, -- NUEVO CAMPO
        telefono, 
        cargo, 
        departamento, 
        estado, 
        observaciones
    ) VALUES (
        p_nombre_usuario, 
        p_apellido_usuario, 
        p_email, 
        p_password, -- NUEVO CAMPO
        p_telefono, 
        p_cargo, 
        p_departamento, 
        p_estado, 
        p_observaciones
    ) RETURNING id_usuario INTO v_id_usuario;
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'message', 'Usuario creado exitosamente',
        'id_usuario', v_id_usuario
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al crear usuario: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTO PARA ACTUALIZAR CONTRASEÑA
-- =========================================

-- Crear procedimiento para cambiar contraseña
CREATE OR REPLACE FUNCTION sp_change_password(
    p_id_usuario INTEGER,
    p_old_password VARCHAR(255),
    p_new_password VARCHAR(255)
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_current_password VARCHAR(255);
BEGIN
    -- Obtener contraseña actual
    SELECT password INTO v_current_password
    FROM usuario 
    WHERE id_usuario = p_id_usuario;
    
    -- Verificar que el usuario existe
    IF v_current_password IS NULL THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
        RETURN v_result;
    END IF;
    
    -- Verificar contraseña actual (esto se hará en la aplicación con bcrypt)
    -- Por ahora solo verificamos que no esté vacía
    IF p_old_password IS NULL OR TRIM(p_old_password) = '' THEN
        v_result := json_build_object(
            'success', false,
            'message', 'La contraseña actual es requerida'
        );
        RETURN v_result;
    END IF;
    
    -- Verificar nueva contraseña
    IF p_new_password IS NULL OR TRIM(p_new_password) = '' THEN
        v_result := json_build_object(
            'success', false,
            'message', 'La nueva contraseña es requerida'
        );
        RETURN v_result;
    END IF;
    
    -- Actualizar contraseña
    UPDATE usuario 
    SET password = p_new_password,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_usuario = p_id_usuario;
    
    v_result := json_build_object(
        'success', true,
        'message', 'Contraseña actualizada exitosamente'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al actualizar contraseña: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTO PARA LOGIN
-- =========================================

-- Crear procedimiento para login
CREATE OR REPLACE FUNCTION sp_login(
    p_email VARCHAR(255),
    p_password VARCHAR(255)
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_usuario_data JSON;
    v_usuario_id INTEGER;
    v_current_password VARCHAR(255);
    v_estado VARCHAR(20);
    v_bloqueado_hasta TIMESTAMP;
    v_intentos_fallidos INTEGER;
BEGIN
    -- Obtener datos del usuario
    SELECT 
        id_usuario,
        password,
        estado,
        bloqueado_hasta,
        intentos_fallidos
    INTO 
        v_usuario_id,
        v_current_password,
        v_estado,
        v_bloqueado_hasta,
        v_intentos_fallidos
    FROM usuario 
    WHERE email = p_email;
    
    -- Verificar que el usuario existe
    IF v_usuario_id IS NULL THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
        RETURN v_result;
    END IF;
    
    -- Verificar estado del usuario
    IF v_estado != 'Activo' THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario inactivo o suspendido'
        );
        RETURN v_result;
    END IF;
    
    -- Verificar si está bloqueado
    IF v_bloqueado_hasta IS NOT NULL AND v_bloqueado_hasta > CURRENT_TIMESTAMP THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario bloqueado temporalmente por intentos fallidos'
        );
        RETURN v_result;
    END IF;
    
    -- Verificar contraseña (esto se hará en la aplicación con bcrypt.compare)
    -- Por ahora solo verificamos que no esté vacía
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        -- Incrementar intentos fallidos
        UPDATE usuario 
        SET intentos_fallidos = COALESCE(intentos_fallidos, 0) + 1,
            bloqueado_hasta = CASE 
                WHEN COALESCE(intentos_fallidos, 0) + 1 >= 5 THEN 
                    CURRENT_TIMESTAMP + INTERVAL '30 minutes'
                ELSE NULL 
            END
        WHERE id_usuario = v_usuario_id;
        
        v_result := json_build_object(
            'success', false,
            'message', 'Contraseña requerida'
        );
        RETURN v_result;
    END IF;
    
    -- Si llegamos aquí, la verificación de contraseña se hará en la aplicación
    -- Por ahora simulamos un login exitoso si la contraseña no está vacía
    -- En la aplicación real, aquí se verificará con bcrypt.compare(p_password, v_current_password)
    
    -- Resetear intentos fallidos y actualizar último login
    UPDATE usuario 
    SET intentos_fallidos = 0,
        bloqueado_hasta = NULL,
        ultimo_login = CURRENT_TIMESTAMP,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_usuario = v_usuario_id;
    
    -- Obtener datos del usuario para la respuesta
    SELECT json_build_object(
        'id_usuario', u.id_usuario,
        'nombre_usuario', u.nombre_usuario,
        'apellido_usuario', u.apellido_usuario,
        'email', u.email,
        'telefono', u.telefono,
        'cargo', u.cargo,
        'departamento', u.departamento,
        'estado', u.estado,
        'ultimo_login', u.ultimo_login,
        'fecha_creacion', u.fecha_creacion,
        'fecha_actualizacion', u.fecha_actualizacion,
        'observaciones', u.observaciones
    ) INTO v_usuario_data
    FROM usuario u
    WHERE u.id_usuario = v_usuario_id;
    
    v_result := json_build_object(
        'success', true,
        'message', 'Login exitoso',
        'data', v_usuario_data
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error en el login: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- PROCEDIMIENTO PARA RESETEAR CONTRASEÑA
-- =========================================

-- Crear procedimiento para resetear contraseña (admin)
CREATE OR REPLACE FUNCTION sp_reset_password(
    p_id_usuario INTEGER,
    p_new_password VARCHAR(255)
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Verificar que la nueva contraseña no esté vacía
    IF p_new_password IS NULL OR TRIM(p_new_password) = '' THEN
        v_result := json_build_object(
            'success', false,
            'message', 'La nueva contraseña es requerida'
        );
        RETURN v_result;
    END IF;
    
    -- Actualizar contraseña y resetear intentos fallidos
    UPDATE usuario 
    SET password = p_new_password,
        intentos_fallidos = 0,
        bloqueado_hasta = NULL,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_usuario = p_id_usuario;
    
    -- Verificar que se actualizó
    IF NOT FOUND THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
        RETURN v_result;
    END IF;
    
    v_result := json_build_object(
        'success', true,
        'message', 'Contraseña reseteada exitosamente'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al resetear contraseña: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- ACTUALIZAR USUARIOS EXISTENTES CON CONTRASEÑA POR DEFECTO
-- =========================================

-- Agregar contraseña por defecto a usuarios existentes
-- NOTA: En producción, estos usuarios deberán cambiar su contraseña en el primer login
UPDATE usuario 
SET password = '$2b$10$default.password.hash.placeholder'
WHERE password IS NULL;

-- Comentario sobre la contraseña por defecto
COMMENT ON COLUMN usuario.password IS 'Contraseña hasheada del usuario. Los usuarios existentes tienen una contraseña por defecto que debe ser cambiada en el primer login.';
