# 📋 Instrucciones Finales - Sistema de Citas Médicas

## ✅ Adaptaciones Realizadas

He adaptado el código para que funcione con la estructura **REAL** de tu tabla en Supabase:

### Estructura Actual de `citas_medicas`:
```
✓ id                    UUID (PRIMARY KEY)
✓ appointment_number    BIGINT (autoincremental)
✓ client_name           TEXT
✓ client_id_number      TEXT
✓ appointment_at        TIMESTAMP WITH TIME ZONE
✓ reason                TEXT
✓ cost                  BIGINT (⚠️ números enteros, no decimales)
✓ attending_doctor      TEXT
✓ notes                 TEXT
✓ created_at            TIMESTAMP WITH TIME ZONE
✓ updated_at            TIMESTAMP WITH TIME ZONE
```

---

## 🔧 Cambios Aplicados al Código

### 1. **Campo `cost` adaptado a BIGINT**
   - Cambiado de `parseFloat()` a `parseInt()`
   - Input ahora acepta solo números enteros (step="1")
   - Muestra sin decimales: `$50` en lugar de `$50.00`

### 2. **Campo `appointment_number` autoincremental**
   - Se genera automáticamente en Supabase
   - No se envía en el INSERT
   - Se muestra en formato 0001, 0002, 0003...

### 3. **Campo `attending_doctor` como TEXT**
   - Cambiado de dropdown a input text libre
   - No hay foreign key a tabla doctors

---

## 🚀 Pasos para Activar el Sistema

### **PASO 1: Verificar y Reparar la Secuencia** (IMPORTANTE)

Ejecuta este script en Supabase SQL Editor:

```sql
-- Archivo: verify-and-fix-sequence.sql
```

Este script:
1. ✅ Verifica si existe la secuencia `citas_medicas_appointment_number_seq`
2. ✅ La crea si no existe
3. ✅ Asigna el DEFAULT a la columna `appointment_number`
4. ✅ Asigna números a registros existentes que no los tengan
5. ✅ Ajusta la secuencia al último número usado

**¿Por qué es necesario?**
- Sin la secuencia, `appointment_number` será NULL
- El código espera que se genere automáticamente
- La secuencia garantiza números consecutivos (1, 2, 3...)

---

### **PASO 2: Probar el Sistema**

1. **Abre tu aplicación React**
2. **Ve a la sección de Citas**
3. **Intenta registrar una cita nueva:**
   - Selecciona un cliente
   - Elige fecha y hora
   - Ingresa razón de la cita
   - Ingresa costo (número entero, ej: 50)
   - Ingresa nombre del doctor (texto libre)
   - Notas opcionales

4. **Verifica que:**
   - ✅ La cita se registra sin errores
   - ✅ El `appointment_number` se genera automáticamente
   - ✅ Aparece en la tabla con formato 0001, 0002, etc.
   - ✅ Al editar, se muestra el número de cita

---

## 🐛 Si Sigues Teniendo el Error

### Error: `null value in column "appointment_number"`

**Causa:** La secuencia no está configurada o el DEFAULT no está asignado.

**Solución:**
1. Ejecuta `verify-and-fix-sequence.sql` en Supabase
2. Verifica el resultado de las consultas finales
3. Debería mostrar:
   ```
   ✓ Secuencia creada/existe
   ✓ DEFAULT asignado a appointment_number
   ✓ Todos los registros tienen número
   ```

### Verificación Manual en Supabase:

```sql
-- Ver estructura de la columna
SELECT column_default
FROM information_schema.columns
WHERE table_name = 'citas_medicas'
  AND column_name = 'appointment_number';

-- Resultado esperado:
-- nextval('public.citas_medicas_appointment_number_seq'::regclass)
```

Si el `column_default` está vacío, ejecuta:

```sql
ALTER TABLE public.citas_medicas
  ALTER COLUMN appointment_number SET DEFAULT nextval('public.citas_medicas_appointment_number_seq'::regclass);
```

---

## 📊 Formato del Número de Cita

El sistema formatea los números con 4 dígitos:
- Registro 1 → **0001**
- Registro 15 → **0015**
- Registro 123 → **0123**
- Registro 1234 → **1234**

Esto se hace en el frontend con:
```javascript
cita.appointment_number.toString().padStart(4, '0')
```

---

## 💡 Notas Importantes

### ⚠️ Campo `cost` es BIGINT
- Solo acepta números enteros
- Para costos con centavos, necesitarías cambiar a DECIMAL en Supabase:
  ```sql
  ALTER TABLE public.citas_medicas
    ALTER COLUMN cost TYPE DECIMAL(10, 2) USING cost::DECIMAL;
  ```
- Luego actualizar el código a `parseFloat()` y `step="0.01"`

### ✅ Campo `attending_doctor` es TEXT
- No hay relación con tabla `doctors`
- Puedes escribir cualquier nombre
- Si quieres un dropdown de doctores, habría que agregar:
  1. Tabla `doctors` en Supabase
  2. Código para cargar doctores
  3. SELECT en lugar de INPUT

---

## 📂 Archivos Importantes

1. **verify-and-fix-sequence.sql** → Reparar secuencia (EJECUTAR PRIMERO)
2. **supabase-schema.sql** → Schema completo actualizado
3. **src/components/Citas.jsx** → Componente adaptado
4. **fix-appointment-number.sql** → Migración completa (solo si necesitas recrear)

---

## ✨ Resumen de lo que Funciona Ahora

✅ Registro de citas con `appointment_number` autoincremental
✅ Campo de número de cita en formulario (disabled)
✅ Columna "N° Cita" en tabla con formato 0001
✅ Campo `cost` como número entero (BIGINT)
✅ Campo `attending_doctor` como texto libre
✅ Vista calendario y vista de lista
✅ Edición y eliminación de citas usando `id` como PK
✅ Validación de citas duplicadas por hora

---

## 🎯 Próximos Pasos

1. **Ejecuta `verify-and-fix-sequence.sql`**
2. **Prueba registrar una cita**
3. **Verifica que el número se genere automáticamente**
4. **Si todo funciona, ¡listo! 🎉**

---

**¿Necesitas ayuda?** Revisa los logs de la consola del navegador y los errores de Supabase.
