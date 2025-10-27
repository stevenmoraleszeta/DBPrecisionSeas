-- =========================================
-- PROCEDIMIENTOS PARA USUARIO
-- =========================================

-- Crear usuario
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

-- Actualizar usuario
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
    v_update_fields TEXT := '';
    v_has_fields BOOLEAN := FALSE;
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
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'nombre_usuario = ' || quote_literal(p_nombre_usuario);
        v_has_fields := TRUE;
    END IF;
    
    IF p_apellido_usuario IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'apellido_usuario = ' || quote_literal(p_apellido_usuario);
        v_has_fields := TRUE;
    END IF;
    
    IF p_email IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'email = ' || quote_literal(p_email);
        v_has_fields := TRUE;
    END IF;
    
    IF p_telefono IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'telefono = ' || quote_literal(p_telefono);
        v_has_fields := TRUE;
    END IF;
    
    IF p_cargo IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'cargo = ' || quote_literal(p_cargo);
        v_has_fields := TRUE;
    END IF;
    
    IF p_departamento IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'departamento = ' || quote_literal(p_departamento);
        v_has_fields := TRUE;
    END IF;
    
    IF p_estado IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'estado = ' || quote_literal(p_estado);
        v_has_fields := TRUE;
    END IF;
    
    IF p_observaciones IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'observaciones = ' || quote_literal(p_observaciones);
        v_has_fields := TRUE;
    END IF;
    
    IF p_password IS NOT NULL THEN
        IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
        v_update_fields := v_update_fields || 'password = ' || quote_literal(p_password);
        v_has_fields := TRUE;
    END IF;
    
    -- Agregar fecha_actualizacion
    IF v_update_fields != '' THEN v_update_fields := v_update_fields || ', '; END IF;
    v_update_fields := v_update_fields || 'fecha_actualizacion = CURRENT_TIMESTAMP';
    
    -- Si no hay campos para actualizar
    IF NOT v_has_fields THEN
        RETURN json_build_object(
            'success', false,
            'message', 'No se proporcionaron campos para actualizar'
        );
    END IF;
    
    -- Construir y ejecutar query
    EXECUTE 'UPDATE usuario SET ' || v_update_fields || ' WHERE id_usuario = ' || p_id_usuario;
    
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

-- Obtener usuario por ID
CREATE OR REPLACE FUNCTION get_usuario(p_id_usuario INTEGER)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_usuario_data JSON;
BEGIN
    -- Primero verificar si el usuario existe
    SELECT json_build_object(
        'id_usuario', u.id_usuario,
        'nombre_usuario', u.nombre_usuario,
        'apellido_usuario', u.apellido_usuario,
        'email', u.email,
        'telefono', u.telefono,
        'cargo', u.cargo,
        'departamento', u.departamento,
        'estado', u.estado,
        'fecha_creacion', u.fecha_creacion,
        'fecha_actualizacion', u.fecha_actualizacion,
        'observaciones', u.observaciones
    ) INTO v_usuario_data
    FROM usuario u
    WHERE u.id_usuario = p_id_usuario;
    
    -- Verificar si se encontró el usuario
    IF v_usuario_data IS NULL THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
    ELSE
        v_result := json_build_object(
            'success', true,
            'data', v_usuario_data
        );
    END IF;
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', 'Error al obtener usuario: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Listar usuarios con paginación y búsqueda
CREATE OR REPLACE FUNCTION list_usuarios(
    p_limit INTEGER DEFAULT 10,
    p_offset INTEGER DEFAULT 0,
    p_search VARCHAR(255) DEFAULT NULL,
    p_estado VARCHAR(20) DEFAULT NULL,
    p_departamento VARCHAR(100) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_count INTEGER;
    v_usuarios JSON;
    v_where_conditions TEXT := 'WHERE 1=1';
    v_sql TEXT;
BEGIN
    -- Construir condiciones WHERE dinámicamente
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_where_conditions := v_where_conditions || ' AND (
            LOWER(nombre_usuario) LIKE LOWER(''%' || p_search || '%'') OR
            LOWER(apellido_usuario) LIKE LOWER(''%' || p_search || '%'') OR
            LOWER(email) LIKE LOWER(''%' || p_search || '%'') OR
            LOWER(cargo) LIKE LOWER(''%' || p_search || '%'')
        )';
    END IF;
    
    IF p_estado IS NOT NULL AND p_estado != '' THEN
        v_where_conditions := v_where_conditions || ' AND estado = ''' || p_estado || '''';
    END IF;
    
    IF p_departamento IS NOT NULL AND p_departamento != '' THEN
        v_where_conditions := v_where_conditions || ' AND departamento = ''' || p_departamento || '''';
    END IF;
    
    -- Contar total de registros
    v_sql := 'SELECT COUNT(*) FROM usuario ' || v_where_conditions;
    EXECUTE v_sql INTO v_count;
    
    -- Obtener usuarios con paginación
    v_sql := 'SELECT json_agg(
        json_build_object(
            ''id_usuario'', u.id_usuario,
            ''nombre_usuario'', u.nombre_usuario,
            ''apellido_usuario'', u.apellido_usuario,
            ''email'', u.email,
            ''telefono'', u.telefono,
            ''cargo'', u.cargo,
            ''departamento'', u.departamento,
            ''estado'', u.estado,
            ''fecha_creacion'', u.fecha_creacion,
            ''fecha_actualizacion'', u.fecha_actualizacion,
            ''observaciones'', u.observaciones
        )
    ) FROM (
        SELECT * FROM usuario ' || v_where_conditions || '
        ORDER BY nombre_usuario, apellido_usuario
        LIMIT ' || p_limit || ' OFFSET ' || p_offset || '
    ) u';
    
    EXECUTE v_sql INTO v_usuarios;
    
    -- Construir resultado
    v_result := json_build_object(
        'success', true,
        'data', COALESCE(v_usuarios, '[]'::json),
        'pagination', json_build_object(
            'total', v_count,
            'limit', p_limit,
            'offset', p_offset,
            'pages', CEIL(v_count::DECIMAL / p_limit)
        )
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al listar usuarios: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Eliminar usuario
CREATE OR REPLACE FUNCTION sp_delete_usuario(p_id_usuario INTEGER)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    DELETE FROM usuario WHERE id_usuario = p_id_usuario;
    
    IF FOUND THEN
        v_result := json_build_object(
            'success', true,
            'message', 'Usuario eliminado exitosamente'
        );
    ELSE
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
    END IF;
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al eliminar usuario: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Buscar usuarios
CREATE OR REPLACE FUNCTION search_usuarios(p_search_term VARCHAR(255))
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id_usuario', u.id_usuario,
            'nombre_usuario', u.nombre_usuario,
            'apellido_usuario', u.apellido_usuario,
            'email', u.email,
            'telefono', u.telefono,
            'cargo', u.cargo,
            'departamento', u.departamento,
            'estado', u.estado
        )
    ) INTO v_result
    FROM usuario u
    WHERE LOWER(u.nombre_usuario) LIKE LOWER('%' || p_search_term || '%')
       OR LOWER(u.apellido_usuario) LIKE LOWER('%' || p_search_term || '%')
       OR LOWER(u.email) LIKE LOWER('%' || p_search_term || '%')
       OR LOWER(u.cargo) LIKE LOWER('%' || p_search_term || '%')
       OR LOWER(u.departamento) LIKE LOWER('%' || p_search_term || '%');
    
    IF v_result IS NULL THEN
        v_result := '[]'::json;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'data', v_result
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', 'Error en la búsqueda: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Obtener estadísticas de usuarios
CREATE OR REPLACE FUNCTION get_usuario_stats()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_total_usuarios INTEGER;
    v_usuarios_activos INTEGER;
    v_usuarios_inactivos INTEGER;
    v_usuarios_suspendidos INTEGER;
    v_departamentos JSON;
BEGIN
    -- Contar total de usuarios
    SELECT COUNT(*) INTO v_total_usuarios FROM usuario;
    
    -- Contar por estado
    SELECT COUNT(*) INTO v_usuarios_activos FROM usuario WHERE estado = 'Activo';
    SELECT COUNT(*) INTO v_usuarios_inactivos FROM usuario WHERE estado = 'Inactivo';
    SELECT COUNT(*) INTO v_usuarios_suspendidos FROM usuario WHERE estado = 'Suspendido';
    
    -- Obtener distribución por departamento
    SELECT json_agg(
        json_build_object(
            'departamento', departamento,
            'count', count
        )
    ) INTO v_departamentos
    FROM (
        SELECT departamento, COUNT(*) as count
        FROM usuario
        WHERE departamento IS NOT NULL
        GROUP BY departamento
        ORDER BY count DESC
    ) dept_stats;
    
    -- Construir resultado
    v_result := json_build_object(
        'success', true,
        'data', json_build_object(
            'total_usuarios', v_total_usuarios,
            'usuarios_activos', v_usuarios_activos,
            'usuarios_inactivos', v_usuarios_inactivos,
            'usuarios_suspendidos', v_usuarios_suspendidos,
            'departamentos', COALESCE(v_departamentos, '[]'::json)
        )
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := json_build_object(
        'success', false,
        'message', 'Error al obtener estadísticas: ' || SQLERRM
    );
    RETURN v_result;
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