-- =========================================
-- MIGRATION: Remove UNIQUE Constraints to Allow Duplicate Entries
-- =========================================
-- This migration removes the unique constraints that prevent adding
-- the same material, import, or process multiple times to the same
-- quotation or OT. This allows for more flexible data entry.

-- Remove UNIQUE constraints from COTIZACION relational tables
ALTER TABLE cotizacion_material DROP CONSTRAINT IF EXISTS uk_cot_mat;
ALTER TABLE cotizacion_importacion DROP CONSTRAINT IF EXISTS uk_cot_imp;
ALTER TABLE cotizacion_proceso DROP CONSTRAINT IF EXISTS uk_cot_proceso;

-- Remove UNIQUE constraints from OT relational tables
ALTER TABLE ot_material DROP CONSTRAINT IF EXISTS uk_ot_mat;
ALTER TABLE ot_importacion DROP CONSTRAINT IF EXISTS uk_ot_imp;
ALTER TABLE ot_proceso DROP CONSTRAINT IF EXISTS uk_ot_proceso;

-- Verification: Show remaining constraints
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    a.attname AS column_name
FROM pg_constraint 
INNER JOIN pg_attribute a ON a.attrelid = conrelid AND a.attnum = ANY(conkey)
WHERE conrelid IN (
    'cotizacion_material'::regclass,
    'cotizacion_importacion'::regclass,
    'cotizacion_proceso'::regclass,
    'ot_material'::regclass,
    'ot_importacion'::regclass,
    'ot_proceso'::regclass
)
AND contype = 'u'
ORDER BY conname;

