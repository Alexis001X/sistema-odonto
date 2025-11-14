-- ============================================
-- SCRIPT PARA SOLUCIONAR POLÍTICAS RLS
-- Ejecuta este script en el SQL Editor de Supabase
-- ============================================

-- 1. ELIMINAR POLÍTICAS EXISTENTES (si hay conflictos)
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver clientes" ON public.clientes;
DROP POLICY IF EXISTS "Usuarios autenticados pueden crear clientes" ON public.clientes;
DROP POLICY IF EXISTS "Usuarios autenticados pueden actualizar clientes" ON public.clientes;
DROP POLICY IF EXISTS "Usuarios autenticados pueden eliminar clientes" ON public.clientes;

-- 2. DESHABILITAR RLS TEMPORALMENTE PARA VERIFICAR LA TABLA
-- (Opcional - solo para debugging, elimina esta línea en producción)
-- ALTER TABLE public.clientes DISABLE ROW LEVEL SECURITY;

-- 3. VERIFICAR QUE LA TABLA EXISTE
-- Si no existe, créala:
CREATE TABLE IF NOT EXISTS public.clientes (
  id_cliente UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  id_number TEXT UNIQUE NOT NULL,
  phone TEXT,
  email TEXT,
  direccion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. HABILITAR RLS
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- 5. CREAR POLÍTICAS NUEVAS CON NOMBRES ÚNICOS
CREATE POLICY "enable_select_for_authenticated_users"
  ON public.clientes
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "enable_insert_for_authenticated_users"
  ON public.clientes
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "enable_update_for_authenticated_users"
  ON public.clientes
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "enable_delete_for_authenticated_users"
  ON public.clientes
  FOR DELETE
  TO authenticated
  USING (true);

-- 6. CREAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_clientes_id_number ON public.clientes(id_number);
CREATE INDEX IF NOT EXISTS idx_clientes_name ON public.clientes(name);
CREATE INDEX IF NOT EXISTS idx_clientes_created_at ON public.clientes(created_at DESC);

-- 7. TRIGGER PARA UPDATED_AT
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_clientes_updated ON public.clientes;
CREATE TRIGGER on_clientes_updated
  BEFORE UPDATE ON public.clientes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8. VERIFICAR LAS POLÍTICAS CREADAS
-- Ejecuta esta consulta para ver las políticas activas:
-- SELECT * FROM pg_policies WHERE tablename = 'clientes';
