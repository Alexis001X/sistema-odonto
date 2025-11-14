-- ============================================
-- ACTUALIZAR RELACIÓN ENTRE CITAS Y DOCTORES
-- Ejecuta este script en Supabase si necesitas actualizar la relación
-- ============================================

-- NOTA: Este script asume que ya tienes la tabla doctors creada
-- Si no la tienes, descomenta y ejecuta el siguiente bloque:

/*
CREATE TABLE IF NOT EXISTS public.doctors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  speciality TEXT,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS para doctors
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para doctors
CREATE POLICY "doctors_select_authenticated"
  ON public.doctors FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "doctors_insert_authenticated"
  ON public.doctors FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "doctors_update_authenticated"
  ON public.doctors FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "doctors_delete_authenticated"
  ON public.doctors FOR DELETE
  TO authenticated
  USING (true);
*/

-- Eliminar la constraint de foreign key anterior si existe (por si acaso)
ALTER TABLE public.citas_medicas
  DROP CONSTRAINT IF EXISTS citas_medicas_attending_doctor_id_fkey;

-- Modificar la columna attending_doctor_id para que sea UUID en lugar de TEXT
-- IMPORTANTE: Esto solo funcionará si la columna está vacía o tiene valores NULL
-- Si ya tienes datos, primero debes limpiarlos o migrarlos

-- Opción 1: Si no tienes datos importantes, puedes eliminar y recrear
ALTER TABLE public.citas_medicas
  ALTER COLUMN attending_doctor_id TYPE UUID USING attending_doctor_id::uuid;

-- Opción 2: Si la columna ya es TEXT con datos, primero necesitas limpiarla:
-- UPDATE public.citas_medicas SET attending_doctor_id = NULL WHERE attending_doctor_id IS NOT NULL;
-- ALTER TABLE public.citas_medicas ALTER COLUMN attending_doctor_id TYPE UUID USING NULL;

-- Agregar la foreign key constraint
ALTER TABLE public.citas_medicas
  ADD CONSTRAINT citas_medicas_attending_doctor_id_fkey
  FOREIGN KEY (attending_doctor_id)
  REFERENCES public.doctors(id)
  ON DELETE SET NULL;

-- Crear índice para mejorar rendimiento en búsquedas por doctor
CREATE INDEX IF NOT EXISTS idx_citas_medicas_attending_doctor
  ON public.citas_medicas(attending_doctor_id);

-- Verificar la relación
SELECT
  'Relación creada exitosamente' as status,
  (SELECT COUNT(*) FROM pg_constraint WHERE conname = 'citas_medicas_attending_doctor_id_fkey') as constraint_exists;
