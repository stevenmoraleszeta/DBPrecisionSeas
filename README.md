# 🚀 **ORDEN DE EJECUCIÓN DE PROCEDIMIENTOS ALMACENADOS**

### **📋 SECUENCIA OBLIGATORIA (POR DEPENDENCIAS)**

#### **FASE 1: Estructura Base (Sin Dependencias)**
```bash
# 1. Crear la base de datos
psql -c "CREATE DATABASE db_precision_seas;"

# 2. Conectar a la base de datos
psql -d db_precision_seas
```

#### **FASE 2: Tablas Principales (Orden: Sin FK → Con FK)**
```sql
-- 1. Ejecutar estructura de tablas (sin FK activas)
\i create.sql

-- 2. Crear procedimientos de catálogos (sin dependencias)
\i procedures/material.sql
\i procedures/importacion.sql
\i procedures/proceso_maquina.sql
```

#### **FASE 3: Tablas con Dependencias (Orden: Padre → Hijo)**
```sql
-- 3. Crear procedimientos de empresa (tabla padre)
\i procedures/empresa.sql

-- 4. Crear procedimientos de contacto (depende de empresa)
\i procedures/contacto.sql

-- 5. Crear procedimientos de cotización (depende de empresa y contacto)
\i procedures/cotizacion.sql
```

#### **FASE 4: Tablas de Detalle (Orden: Dependen de cotización)**
```sql
-- 6. Crear procedimientos de detalles (dependen de cotización)
\i procedures/cotizacion_material.sql
\i procedures/cotizacion_importacion.sql
\i procedures/cotizacion_proceso.sql
```

#### **FASE 5: Datos y Pruebas**
```sql
-- 7. Insertar datos de prueba
\i insert_test_data.sql

-- 8. Ejecutar pruebas integrales
\i prueba.sql
```

### **🔍 EXPLICACIÓN DE DEPENDENCIAS**

#### **Jerarquía de Dependencias**
```
material.sql          ← Sin dependencias
importacion.sql       ← Sin dependencias  
proceso_maquina.sql   ← Sin dependencias
    ↓
empresa.sql           ← Sin dependencias
    ↓
contacto.sql          ← FK a empresa.id_empresa
    ↓
cotizacion.sql        ← FK a empresa.id_empresa + contacto.id_contacto
    ↓
cotizacion_material.sql      ← FK a cotizacion.id_cotizacion
cotizacion_importacion.sql   ← FK a cotizacion.id_cotizacion
cotizacion_proceso.sql       ← FK a cotizacion.id_cotizacion
```

#### **¿Por Qué Este Orden?**

1. **`material.sql`, `importacion.sql`, `proceso_maquina.sql`**
   - Son catálogos independientes
   - No tienen FK a otras tablas
   - Se pueden crear en cualquier orden

2. **`empresa.sql`**
   - Tabla padre para contactos y cotizaciones
   - Debe existir antes de crear FK que la referencien

3. **`contacto.sql`**
   - Tiene FK a `empresa.id_empresa`
   - Necesita que la tabla empresa y sus procedimientos existan

4. **`cotizacion.sql`**
   - Tiene FK a `empresa.id_empresa` y `contacto.id_contacto`
   - Necesita que ambas tablas padre existan

5. **`cotizacion_*.sql`**
   - Todas tienen FK a `cotizacion.id_cotizacion`
   - Necesitan que la tabla cotización y sus procedimientos existan

### **⚡ SCRIPT DE EJECUCIÓN AUTOMÁTICA**

#### **Para Linux/macOS:**
```bash
#!/bin/bash
# create_database.sh

DB_NAME="db_precision_seas"

echo "🚀 Creando base de datos $DB_NAME..."

# Crear base de datos
psql -c "CREATE DATABASE $DB_NAME;"

# Conectar y ejecutar en orden
psql -d $DB_NAME << EOF
-- FASE 2: Tablas principales
\i create.sql

-- FASE 3: Procedimientos de catálogos
\i procedures/material.sql
\i procedures/importacion.sql
\i procedures/proceso_maquina.sql

-- FASE 4: Procedimientos con dependencias
\i procedures/empresa.sql
\i procedures/contacto.sql
\i procedures/cotizacion.sql

-- FASE 5: Procedimientos de detalle
\i procedures/cotizacion_material.sql
\i procedures/cotizacion_importacion.sql
\i procedures/cotizacion_proceso.sql

-- FASE 6: Datos de prueba
\i insert_test_data.sql

-- FASE 7: Verificar instalación
SELECT '✅ Base de datos creada exitosamente' as mensaje;
SELECT COUNT(*) as total_empresas FROM empresa;
SELECT COUNT(*) as total_contactos FROM contacto;
SELECT COUNT(*) as total_cotizaciones FROM cotizacion;
EOF

echo "✅ Base de datos $DB_NAME creada exitosamente!"
```

#### **Para Windows (PowerShell):**
```powershell
# create_database.ps1

$DB_NAME = "db_precision_seas"

Write-Host "🚀 Creando base de datos $DB_NAME..." -ForegroundColor Green

# Crear base de datos
psql -c "CREATE DATABASE $DB_NAME;"

# Crear archivo temporal con comandos
$commands = @"
-- FASE 2: Tablas principales
\i create.sql

-- FASE 3: Procedimientos de catálogos
\i procedures/material.sql
\i procedures/importacion.sql
\i procedures/proceso_maquina.sql

-- FASE 4: Procedimientos con dependencias
\i procedures/empresa.sql
\i procedures/contacto.sql
\i procedures/cotizacion.sql

-- FASE 5: Procedimientos de detalle
\i procedures/cotizacion_material.sql
\i procedures/cotizacion_importacion.sql
\i procedures/cotizacion_proceso.sql

-- FASE 6: Datos de prueba
\i insert_test_data.sql

-- FASE 7: Verificar instalación
SELECT '✅ Base de datos creada exitosamente' as mensaje;
SELECT COUNT(*) as total_empresas FROM empresa;
SELECT COUNT(*) as total_contactos FROM contacto;
SELECT COUNT(*) as total_cotizaciones FROM cotizacion;
"@

$commands | Out-File -FilePath "temp_commands.sql" -Encoding UTF8

# Ejecutar comandos
psql -d $DB_NAME -f "temp_commands.sql"

# Limpiar archivo temporal
Remove-Item "temp_commands.sql"

Write-Host "✅ Base de datos $DB_NAME creada exitosamente!" -ForegroundColor Green
```

### **🧪 VERIFICACIÓN POST-INSTALACIÓN**

#### **Verificar Procedimientos Creados:**
```sql
-- Verificar que todos los procedimientos existen
SELECT 
    n.nspname as schema,
    p.proname as procedure_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;
```

#### **Verificar Estructura de Tablas:**
```sql
-- Verificar estructura de tablas principales
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('empresa', 'contacto', 'cotizacion')
ORDER BY table_name, ordinal_position;
```

#### **Verificar Restricciones de FK:**
```sql
-- Verificar que las FK están correctamente configuradas
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';
```

### **❌ ERRORES COMUNES Y SOLUCIONES**

#### **Error: "relation does not exist"**
- **Causa**: Ejecutando procedimientos antes de crear las tablas
- **Solución**: Ejecutar `create.sql` primero

#### **Error: "function does not exist"**
- **Causa**: Ejecutando procedimientos en orden incorrecto
- **Solución**: Seguir el orden de dependencias exacto

#### **Error: "foreign key constraint fails"**
- **Causa**: FK activas antes de crear procedimientos
- **Solución**: Crear procedimientos antes de activar FK

### **📞 Soporte**

Para problemas con la migración o la nueva estructura, revisar:
1. Logs de PostgreSQL
2. Restricciones de clave foránea
3. Secuencias auto-incrementales
4. Índices recreados correctamente
5. **Orden de ejecución** de procedimientos almacenados