-- Actualizar el procedimiento sp_update_usuario
-- Este archivo actualiza el procedimiento para que funcione correctamente con parámetros dinámicos

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

