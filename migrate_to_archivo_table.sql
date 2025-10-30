-- =========================================
-- MIGRACIÓN: PLANO_SOLIDO → ARCHIVO
-- =========================================
-- Este script migra la tabla plano_solido a la nueva tabla archivo
-- Elimina dependencias de Cloudinary y simplifica la estructura
-- Fecha: 2025-01-09
-- Versión: 1.0.0

-- =========================================
-- 1) BACKUP DE DATOS EXISTENTES
-- =========================================

-- Crear tabla de respaldo
CREATE TABLE IF NOT EXISTS plano_solido_backup AS 
SELECT * FROM plano_solido;

-- =========================================
-- 2) CREAR NUEVA TABLA ARCHIVO
-- =========================================

-- Crear la nueva tabla archivo
CREATE TABLE IF NOT EXISTS archivo (
    id SERIAL PRIMARY KEY,
    id_ot           INT NULL,
    nombre_archivo  VARCHAR(255) NOT NULL,
    nombre_original VARCHAR(255) NOT NULL,
    tipo_archivo    VARCHAR(50) NOT NULL,
    tipo_mime       VARCHAR(100) NOT NULL,
    tamano_archivo  BIGINT NOT NULL DEFAULT 0,
    ruta_archivo    TEXT NOT NULL,
    fecha_subida    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones   TEXT,
    activo          BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_archivo_ot
        FOREIGN KEY (id_ot)
        REFERENCES ot(id_ot)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- =========================================
-- 3) MIGRAR DATOS EXISTENTES
-- =========================================

-- Migrar datos de plano_solido a archivo
INSERT INTO archivo (
    id_ot, nombre_archivo, nombre_original, tipo_archivo, tipo_mime,
    tamano_archivo, ruta_archivo, fecha_subida, fecha_modificacion,
    observaciones, activo
)
SELECT 
    id_ot, 
    nombre_archivo, 
    nombre_original, 
    tipo_archivo, 
    tipo_mime,
    tamano_archivo, 
    -- Convertir URLs de Cloudinary a rutas locales
    CASE 
        WHEN ruta_archivo LIKE 'https://res.cloudinary.com%' THEN
            'uploads/' || 
            CASE 
                WHEN tipo_archivo = 'imagen' THEN 'imagenes/'
                WHEN tipo_archivo = 'documento' THEN 'documentos/'
                WHEN tipo_archivo = 'cad' THEN 'planos/'
                ELSE 'documentos/'
            END ||
            nombre_archivo
        ELSE ruta_archivo
    END as ruta_archivo,
    fecha_subida, 
    fecha_modificacion,
    observaciones, 
    activo
FROM plano_solido
WHERE activo = TRUE;

-- =========================================
-- 4) CREAR ÍNDICES PARA LA NUEVA TABLA
-- =========================================

-- Índices para la tabla archivo
CREATE INDEX IF NOT EXISTS idx_archivo_ot ON archivo (id_ot);
CREATE INDEX IF NOT EXISTS idx_archivo_tipo ON archivo (tipo_archivo);
CREATE INDEX IF NOT EXISTS idx_archivo_activo ON archivo (activo);
CREATE INDEX IF NOT EXISTS idx_archivo_tipo_mime ON archivo (tipo_mime);
CREATE INDEX IF NOT EXISTS idx_archivo_fecha_subida ON archivo (fecha_subida);

-- =========================================
-- 5) CREAR PROCEDIMIENTOS ALMACENADOS
-- =========================================

-- Ejecutar el archivo de procedimientos para archivo
\i procedures/archivo.sql

-- =========================================
-- 6) VERIFICAR MIGRACIÓN
-- =========================================

-- Verificar que los datos se migraron correctamente
DO $$
DECLARE
    v_original_count INT;
    v_migrated_count INT;
BEGIN
    -- Contar registros originales
    SELECT COUNT(*) INTO v_original_count 
    FROM plano_solido_backup 
    WHERE activo = TRUE;
    
    -- Contar registros migrados
    SELECT COUNT(*) INTO v_migrated_count 
    FROM archivo 
    WHERE activo = TRUE;
    
    -- Verificar que la migración fue exitosa
    IF v_original_count != v_migrated_count THEN
        RAISE EXCEPTION 'Error en la migración: % registros originales, % registros migrados', 
            v_original_count, v_migrated_count;
    END IF;
    
    RAISE NOTICE 'Migración exitosa: % registros migrados correctamente', v_migrated_count;
END $$;

-- =========================================
-- 7) ELIMINAR TABLA ORIGINAL
-- =========================================

-- Eliminar índices de la tabla original
DROP INDEX IF EXISTS idx_plano_solido_ot;
DROP INDEX IF EXISTS idx_plano_solido_tipo;
DROP INDEX IF EXISTS idx_plano_solido_activo;
DROP INDEX IF EXISTS idx_plano_solido_tipo_mime;
DROP INDEX IF EXISTS idx_plano_solido_fecha_subida;

-- Eliminar la tabla original
DROP TABLE IF EXISTS plano_solido CASCADE;

-- =========================================
-- 8) ACTUALIZAR COMENTARIOS
-- =========================================

-- Comentarios para documentar la tabla
COMMENT ON TABLE archivo IS 'Tabla para almacenar archivos asociados a OTs o independientes';
COMMENT ON COLUMN archivo.nombre_archivo IS 'Nombre del archivo en el sistema';
COMMENT ON COLUMN archivo.nombre_original IS 'Nombre original del archivo subido';
COMMENT ON COLUMN archivo.tipo_archivo IS 'Tipo de archivo categorizado (imagen, documento, etc.)';
COMMENT ON COLUMN archivo.tipo_mime IS 'Tipo MIME del archivo';
COMMENT ON COLUMN archivo.tamano_archivo IS 'Tamaño del archivo en bytes';
COMMENT ON COLUMN archivo.ruta_archivo IS 'Ruta local del archivo en el sistema';
COMMENT ON COLUMN archivo.activo IS 'Indica si el archivo está activo';

-- =========================================
-- 9) VERIFICACIÓN FINAL
-- =========================================

-- Mostrar resumen de la migración
DO $$
DECLARE
    v_archivo_count INT;
    v_backup_count INT;
    v_ot_count INT;
    v_independientes_count INT;
BEGIN
    -- Contar archivos en la nueva tabla
    SELECT COUNT(*) INTO v_archivo_count FROM archivo WHERE activo = TRUE;
    
    -- Contar archivos en el backup
    SELECT COUNT(*) INTO v_backup_count FROM plano_solido_backup WHERE activo = TRUE;
    
    -- Contar archivos asociados a OTs
    SELECT COUNT(*) INTO v_ot_count FROM archivo WHERE id_ot IS NOT NULL AND activo = TRUE;
    
    -- Contar archivos independientes
    SELECT COUNT(*) INTO v_independientes_count FROM archivo WHERE id_ot IS NULL AND activo = TRUE;
    
    RAISE NOTICE '';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'MIGRACIÓN COMPLETADA EXITOSAMENTE';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Archivos migrados: %', v_archivo_count;
    RAISE NOTICE 'Archivos en backup: %', v_backup_count;
    RAISE NOTICE 'Archivos asociados a OTs: %', v_ot_count;
    RAISE NOTICE 'Archivos independientes: %', v_independientes_count;
    RAISE NOTICE '';
    RAISE NOTICE 'La tabla plano_solido ha sido reemplazada por archivo';
    RAISE NOTICE 'Los datos han sido migrados y las URLs de Cloudinary convertidas a rutas locales';
    RAISE NOTICE 'Los procedimientos almacenados han sido actualizados';
    RAISE NOTICE '';
    RAISE NOTICE 'Puedes eliminar la tabla plano_solido_backup cuando confirmes que todo funciona correctamente';
    RAISE NOTICE '=========================================';
END $$;

-- =========================================
-- 10) LIMPIAR BACKUP (OPCIONAL)
-- =========================================

-- Descomenta la siguiente línea para eliminar el backup automáticamente
-- DROP TABLE IF EXISTS plano_solido_backup;

-- =========================================
-- FIN DE LA MIGRACIÓN
-- =========================================
