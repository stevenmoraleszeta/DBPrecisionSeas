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
    p_observaciones TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_id_usuario INTEGER;
    v_result JSON;
BEGIN
    -- Insertar nuevo usuario
    INSERT INTO usuario (
        nombre_usuario, 
        apellido_usuario, 
        email, 
        telefono, 
        cargo, 
        departamento, 
        estado, 
        observaciones
    ) VALUES (
        p_nombre_usuario, 
        p_apellido_usuario, 
        p_email, 
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

-- Actualizar usuario
CREATE OR REPLACE FUNCTION sp_update_usuario(
    p_id_usuario INTEGER,
    p_nombre_usuario VARCHAR(100) DEFAULT NULL,
    p_apellido_usuario VARCHAR(100) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_cargo VARCHAR(100) DEFAULT NULL,
    p_departamento VARCHAR(100) DEFAULT NULL,
    p_estado VARCHAR(20) DEFAULT NULL,
    p_observaciones TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Actualizar solo los campos que no son NULL
    UPDATE usuario SET
        nombre_usuario = COALESCE(p_nombre_usuario, nombre_usuario),
        apellido_usuario = COALESCE(p_apellido_usuario, apellido_usuario),
        email = COALESCE(p_email, email),
        telefono = COALESCE(p_telefono, telefono),
        cargo = COALESCE(p_cargo, cargo),
        departamento = COALESCE(p_departamento, departamento),
        estado = COALESCE(p_estado, estado),
        observaciones = COALESCE(p_observaciones, observaciones)
    WHERE id_usuario = p_id_usuario;
    
    IF FOUND THEN
        v_result := json_build_object(
            'success', true,
            'message', 'Usuario actualizado exitosamente'
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
        'message', 'Error al actualizar usuario: ' || SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Obtener usuario por ID
CREATE OR REPLACE FUNCTION get_usuario(p_id_usuario INTEGER)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
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
    ) INTO v_result
    FROM usuario u
    WHERE u.id_usuario = p_id_usuario;
    
    IF v_result IS NULL THEN
        v_result := json_build_object(
            'success', false,
            'message', 'Usuario no encontrado'
        );
    ELSE
        v_result := json_build_object(
            'success', true,
            'data', v_result
        );
    END IF;
    
    RETURN v_result;
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
