# 🕐 Solución al Problema de Zona Horaria en Citas

## 🔍 Análisis del Problema

### **Síntoma:**
- Seleccionas hora: **14:00** en el formulario
- Se guarda en la base de datos: **09:00**
- Diferencia: **-5 horas**

### **Causa Raíz:**
El problema ocurre por la conversión automática de zona horaria entre:
1. **Tu navegador** (hora local)
2. **PostgreSQL/Supabase** (almacena en UTC)

---

## 🧪 Diagnóstico

### **Zona Horaria Actual:**
- Si ves -5 horas de diferencia → Estás en **UTC-5** (ej: Ecuador, Colombia, Perú, etc.)
- PostgreSQL guarda en **UTC** (tiempo universal)
- Al leer de vuelta, JavaScript convierte de UTC a tu hora local

---

## ✅ Soluciones Disponibles

### **OPCIÓN 1: Trabajar con UTC (Recomendado)** ⭐

La base de datos ya guarda en UTC. Solo necesitamos mostrar correctamente en hora local.

**Ventajas:**
- ✅ Estándar internacional
- ✅ No hay conversiones innecesarias
- ✅ Funciona si el servidor está en otro país

**Implementación:**
Ya está implementado en el código actualizado. Solo necesitas verificar la configuración de Supabase.

---

### **OPCIÓN 2: Forzar Zona Horaria Específica**

Si prefieres que la base de datos guarde en tu hora local:

**Paso 1:** Ejecuta en Supabase SQL Editor:
```sql
-- Verificar zona horaria actual
SHOW timezone;

-- Cambiar a tu zona horaria (ejemplo para Ecuador/Colombia/Perú)
ALTER DATABASE postgres SET timezone TO 'America/Bogota';

-- O para Ecuador
ALTER DATABASE postgres SET timezone TO 'America/Guayaquil';

-- O para Perú
ALTER DATABASE postgres SET timezone TO 'America/Lima';
```

**Paso 2:** Reinicia la conexión de Supabase.

---

## 🔧 Código Actualizado (Ya Aplicado)

He actualizado el código para manejar mejor las fechas:

```javascript
// Al GUARDAR la cita
const appointmentDateTime = `${formData.appointment_date}T${formData.appointment_time}:00`
// Ejemplo: "2025-01-15T14:00:00"

// Al LEER y MOSTRAR las citas
const appointmentDate = new Date(cita.appointment_at)
const hours = String(appointmentDate.getHours()).padStart(2, '0')
const minutes = String(appointmentDate.getMinutes()).padStart(2, '0')
// Automáticamente convierte de UTC a hora local
```

---

## 🧪 Para Verificar que Funciona

### **Paso 1: Verifica la zona horaria de Supabase**

Ejecuta en Supabase SQL Editor:
```sql
-- Ver zona horaria
SHOW timezone;

-- Ver una cita específica con diferentes formatos
SELECT
  id,
  appointment_at,
  appointment_at AT TIME ZONE 'UTC' as utc_time,
  appointment_at AT TIME ZONE 'America/Bogota' as local_time
FROM citas_medicas
LIMIT 1;
```

### **Paso 2: Prueba registrar una cita**

1. Selecciona fecha: **2025-01-15**
2. Selecciona hora: **14:00**
3. Guarda la cita
4. En la consola del navegador verás:
   ```
   === GUARDANDO CITA ===
   Fecha seleccionada: 2025-01-15
   Hora seleccionada: 14:00
   DateTime string: 2025-01-15T14:00:00
   ```

### **Paso 3: Verifica en Supabase**

Ve a la tabla `citas_medicas` y mira el campo `appointment_at`:
- Si ves: `2025-01-15 14:00:00+00` → Hora guardada en UTC (normal)
- Si ves: `2025-01-15 19:00:00+00` → Se está convirtiendo (problema)

### **Paso 4: Verifica en el calendario**

1. Ve a la vista de calendario
2. Selecciona la fecha **2025-01-15**
3. La cita debe aparecer en el slot de **14:00**
4. En la consola verás:
   ```
   Buscando cita a las 14:00 - Cita en 14:00 → true
   ```

---

## 🎯 Solución Final Simplificada

### **Si el problema persiste:**

Ejecuta este script en Supabase para forzar que interprete las fechas como hora local:

```sql
-- OPCIÓN A: Cambiar zona horaria de la base de datos
ALTER DATABASE postgres SET timezone TO 'America/Guayayuil'; -- Cambia según tu país

-- OPCIÓN B: Crear una función que maneje las conversiones
CREATE OR REPLACE FUNCTION fix_appointment_timezone()
RETURNS TRIGGER AS $$
BEGIN
  -- Asegurar que la hora se guarde tal como viene sin conversión
  NEW.appointment_at = NEW.appointment_at AT TIME ZONE 'UTC';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS fix_timezone_trigger ON public.citas_medicas;
CREATE TRIGGER fix_timezone_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION fix_appointment_timezone();
```

---

## 📊 Tabla de Zonas Horarias Comunes

| País/Región | Zona Horaria | Offset UTC |
|-------------|--------------|------------|
| Ecuador | America/Guayaquil | UTC-5 |
| Colombia | America/Bogota | UTC-5 |
| Perú | America/Lima | UTC-5 |
| México (CDMX) | America/Mexico_City | UTC-6 |
| Argentina | America/Buenos_Aires | UTC-3 |
| Chile | America/Santiago | UTC-3/UTC-4 |
| España | Europe/Madrid | UTC+1/UTC+2 |

---

## 🐛 Troubleshooting

### **Problema: Aún se guarda con -5 horas**

**Solución:**
```sql
-- Verificar la zona horaria de tu sesión
SHOW timezone;

-- Cambiar temporalmente para tu sesión
SET timezone TO 'America/Guayaquil'; -- O tu zona

-- Hacer permanente para todas las conexiones
ALTER DATABASE postgres SET timezone TO 'America/Guayaquil';
```

### **Problema: Se muestra mal en el calendario pero bien en la tabla**

**Causa:** El calendario usa conversión diferente a la tabla.

**Solución:** Ya está corregida en el código actualizado. Ambos usan:
```javascript
const appointmentDate = new Date(cita.appointment_at)
const hours = appointmentDate.getHours() // Convierte automáticamente a local
```

---

## ✨ Resumen

1. **PostgreSQL guarda en UTC** (esto es correcto)
2. **JavaScript convierte automáticamente** a tu hora local al leer
3. **El código actualizado** maneja esto correctamente
4. **Si prefieres**, puedes cambiar la zona horaria de Supabase

**Prueba ahora:**
1. Registra una cita a las 14:00
2. Verifica en consola los logs
3. Revisa que aparezca a las 14:00 en el calendario

Si aún tienes problemas, comparte los logs de la consola. 🎉
