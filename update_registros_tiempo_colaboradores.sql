-- Script para actualizar registros de tiempo con colaboradores
-- Asignar colaboradores a registros que no los tienen

-- Actualizar registros de tiempo existentes con colaboradores
UPDATE registro_tiempo 
SET id_colaborador = 16  -- Juan Pérez
WHERE id = 1 AND id_colaborador IS NULL;

UPDATE registro_tiempo 
SET id_colaborador = 17  -- María González
WHERE id = 2 AND id_colaborador IS NULL;

UPDATE registro_tiempo 
SET id_colaborador = 18  -- Carlos Rodríguez
WHERE id = 3 AND id_colaborador IS NULL;

UPDATE registro_tiempo 
SET id_colaborador = 19  -- Ana Martínez
WHERE id = 4 AND id_colaborador IS NULL;

UPDATE registro_tiempo 
SET id_colaborador = 20  -- Luis Hernández
WHERE id = 9 AND id_colaborador IS NULL;

-- Verificar los cambios
SELECT 
    rt.id,
    rt.descripcion,
    rt.id_colaborador,
    u.nombre_usuario,
    u.apellido_usuario
FROM registro_tiempo rt
LEFT JOIN usuario u ON rt.id_colaborador = u.id_usuario
ORDER BY rt.id;
