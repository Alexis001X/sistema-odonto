# Solución al Error de RLS (Row Level Security)

## Error
```
new row violates row-level security policy for table "clientes"
```

## Causas Comunes
1. Las políticas RLS no están configuradas correctamente
2. El usuario no está autenticado correctamente
3. Hay conflicto con políticas existentes
4. RLS está habilitado pero no hay políticas definidas

## Soluciones

### Opción 1: Ejecutar Script de Reparación (RECOMENDADO)

Ejecuta el archivo `fix-rls-policies.sql` en el SQL Editor de Supabase:

1. Ve a tu proyecto en Supabase
2. Click en "SQL Editor" en el menú lateral
3. Copia y pega el contenido de `fix-rls-policies.sql`
4. Click en "Run" o presiona Ctrl+Enter
5. Verifica que no haya errores

### Opción 2: Solución Rápida - Deshabilitar RLS Temporalmente

**⚠️ ADVERTENCIA: Solo para desarrollo/testing. NO usar en producción**

```sql
-- Deshabilitar RLS temporalmente
ALTER TABLE public.clientes DISABLE ROW LEVEL SECURITY;
```

Esto permitirá todas las operaciones sin restricciones. Una vez que verifiques que todo funciona, vuelve a habilitar RLS:

```sql
-- Volver a habilitar RLS
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
```

### Opción 3: Recrear la Tabla desde Cero

```sql
-- 1. Eliminar tabla existente (⚠️ CUIDADO: Esto borra todos los datos)
DROP TABLE IF EXISTS public.clientes CASCADE;

-- 2. Crear tabla nueva
CREATE TABLE public.clientes (
  id_cliente UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  id_number TEXT UNIQUE NOT NULL,
  phone TEXT,
  email TEXT,
  direccion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Habilitar RLS
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- 4. Crear políticas
CREATE POLICY "allow_authenticated_select"
  ON public.clientes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_insert"
  ON public.clientes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_update"
  ON public.clientes FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_delete"
  ON public.clientes FOR DELETE
  TO authenticated
  USING (true);
```

### Opción 4: Verificar Autenticación

Asegúrate de que el usuario esté correctamente autenticado:

```javascript
// En tu componente Clientes.jsx
import { supabase } from '../lib/supabaseClient'

// Agregar este código para verificar autenticación
useEffect(() => {
  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession()
    console.log('Sesión activa:', session)
    console.log('Usuario:', session?.user)
  }
  checkAuth()
}, [])
```

Si `session` es `null`, el problema es de autenticación, no de RLS.

## Verificar que las Políticas Funcionen

Después de aplicar la solución, ejecuta esta consulta para verificar:

```sql
-- Ver todas las políticas de la tabla clientes
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'clientes';
```

Deberías ver 4 políticas: SELECT, INSERT, UPDATE y DELETE, todas para el rol `authenticated`.

## Verificar en la Interfaz de Supabase

1. Ve a "Table Editor" en Supabase
2. Selecciona la tabla `clientes`
3. Click en "RLS Policies" (ícono de escudo)
4. Deberías ver 4 políticas activas

Si no aparecen, créalas manualmente desde la interfaz:
- Click en "New Policy"
- Selecciona "Enable access to all users based on their user UID"
- Modifica para que sea `TO authenticated USING (true)`

## Script de Debug

Ejecuta esto para ver detalles del error:

```sql
-- Ver información de la tabla
SELECT
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'clientes';

-- Ver políticas
SELECT * FROM pg_policies WHERE tablename = 'clientes';

-- Intentar insertar como test (esto mostrará el error exacto)
INSERT INTO public.clientes (name, id_number)
VALUES ('Test Cliente', '1234567890');
```

## Solución Definitiva Paso a Paso

1. **Elimina todas las políticas existentes:**
   ```sql
   DROP POLICY IF EXISTS "Usuarios autenticados pueden ver clientes" ON public.clientes;
   DROP POLICY IF EXISTS "Usuarios autenticados pueden crear clientes" ON public.clientes;
   DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar clientes" ON public.clientes;
   DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar clientes" ON public.clientes;
   ```

2. **Asegúrate de que RLS esté habilitado:**
   ```sql
   ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
   ```

3. **Crea políticas con nombres simples:**
   ```sql
   CREATE POLICY "clientes_select" ON public.clientes FOR SELECT USING (true);
   CREATE POLICY "clientes_insert" ON public.clientes FOR INSERT WITH CHECK (true);
   CREATE POLICY "clientes_update" ON public.clientes FOR UPDATE USING (true);
   CREATE POLICY "clientes_delete" ON public.clientes FOR DELETE USING (true);
   ```

4. **Prueba insertar un registro:**
   - Desde la interfaz de Supabase: Table Editor > clientes > Insert row
   - Desde el código: Intenta registrar un cliente nuevo

Si el problema persiste, comparte el mensaje de error completo y verificaremos la autenticación.
