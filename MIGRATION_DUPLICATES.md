# Migración: Permite Duplicados en Tablas Relacionales

## Resumen del Cambio

Esta migración elimina las restricciones UNIQUE que impedían agregar el mismo material, importación o proceso múltiples veces a la misma cotización u OT.

## ¿Por qué este cambio?

Anteriormente, el sistema impedía agregar el mismo elemento (material, importación o proceso) dos veces en la misma cotización u OT. Sin embargo, en la práctica, es común que:
- El mismo proceso aparezca múltiples veces con diferentes tiempos
- El mismo material se use varias veces con diferentes cantidades o precios
- La misma importación se requiera en diferentes etapas

Ejemplo: En una cotización, podrías necesitar "Corte láser" dos veces:
1. Corte láser - 30 minutos - para partes principales
2. Corte láser - 15 minutos - para partes secundarias

## Cambios Realizados

### 1. Base de Datos

#### Eliminación de Restricciones UNIQUE

Las siguientes restricciones se eliminaron de la base de datos:
- `uk_cot_mat` - de cotizacion_material
- `uk_cot_imp` - de cotizacion_importacion  
- `uk_cot_proceso` - de cotizacion_proceso
- `uk_ot_mat` - de ot_material
- `uk_ot_imp` - de ot_importacion
- `uk_ot_proceso` - de ot_proceso

### 2. Procedimientos Almacenados

#### Cotizaciones

**Archivo**: `DBPresicionSeas/procedures/cotizacion_material.sql`
- Removido: `ON CONFLICT DO UPDATE`
- Cambio: Simple INSERT que permite duplicados

**Archivo**: `DBPresicionSeas/procedures/cotizacion_importacion.sql`
- Removido: `ON CONFLICT DO UPDATE`
- Cambio: Simple INSERT que permite duplicados

**Archivo**: `DBPresicionSeas/procedures/cotizacion_proceso.sql`
- Removido: `ON CONFLICT DO UPDATE`
- Cambio: Simple INSERT que permite duplicados

#### OTs (Orden de Trabajo)

Los procedimientos de OT ya estaban correctos y no tenían restricciones de duplicados.

### 3. Schema de Base de Datos

**Archivo**: `DBPresicionSeas/create.sql`
- Actualizado: Comentarios que indican que se permiten duplicados
- Eliminado: Restricciones UNIQUE de todas las tablas relacionales

## Cómo Aplicar la Migración

### Opción 1: Base de Datos Nueva
Si estás creando una nueva base de datos, usa el archivo `create.sql` actualizado directamente.

### Opción 2: Base de Datos Existente
Si tienes una base de datos existente con datos, ejecuta:

```sql
-- 1. Ejecutar la migración de restricciones
\i remove_unique_constraints.sql

-- 2. Actualizar los procedimientos almacenados
\i procedures/cotizacion_material.sql
\i procedures/cotizacion_importacion.sql
\i procedures/cotizacion_proceso.sql
```

## Impacto en el Sistema

### Frontend
- ✅ No se requieren cambios en el frontend
- ✅ El usuario ahora puede agregar el mismo elemento múltiples veces
- ✅ La funcionalidad de editar y eliminar sigue funcionando correctamente

### Backend
- ✅ Los endpoints de creación ahora aceptan duplicados
- ✅ Los cálculos de totales funcionan correctamente con duplicados
- ✅ La validación de campos requeridos sigue activa

### Integridad de Datos
- ✅ Cada registro tiene su propio ID único
- ✅ Se mantiene la integridad referencial (foreign keys)
- ✅ Los índices existentes siguen funcionando correctamente

## Notas Importantes

1. **Eliminación Individual**: Cada registro duplicado debe eliminarse individualmente por su ID único.

2. **Visualización**: En las tablas, los elementos duplicados aparecerán como filas separadas, permitiendo ver y editar cada ocurrencia independientemente.

3. **Totales**: Los cálculos de totales sumarán todos los registros, incluyendo duplicados.

## Ejemplo de Uso

Ahora es posible tener en una cotización:

| ID | Material | Cantidad | Precio | Total |
|----|----------|----------|--------|-------|
| 1  | Aluminio | 10m      | $50    | $500  |
| 2  | Aluminio | 5m       | $50    | $250  |

Esto permite registrar que el mismo material se usa en diferentes cantidades o con diferentes dimensiones en el mismo proyecto.

## Compatibilidad

- ✅ Compatible con versiones anteriores de la API
- ✅ Compatible con todos los endpoints existentes
- ✅ No requiere cambios en el código del backend
- ✅ No requiere cambios en el código del frontend

