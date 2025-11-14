-- ============================================
-- SCHEMA PARA TABLA DE CITAS MÉDICAS
-- Ejecuta este script en el SQL Editor de Supabase
-- ============================================

-- Eliminar tabla si existe (CUIDADO: esto borra todos los datos)
-- Comenta esta línea si ya tienes datos que quieres conservar
DROP TABLE IF EXISTS public.citas_medicas CASCADE;

-- Crear tabla de citas médicas
CREATE TABLE public.citas_medicas (
  appointment_number UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_name TEXT NOT NULL,
  client_id_number TEXT NOT NULL,
  appointment_at TIMESTAMP WITH TIME ZONE NOT NULL,
  reason TEXT NOT NULL,
  cost DECIMAL(10, 2),
  attending_doctor TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Referencias a otras tablas
  FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE,
  FOREIGN KEY (attending_doctor) REFERENCES public.doctors(id) ON DELETE SET NULL
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "citas_medicas_select_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_insert_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_update_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_delete_authenticated" ON public.citas_medicas;

-- Crear políticas de seguridad para usuarios autenticados
CREATE POLICY "citas_medicas_select_authenticated"
  ON public.citas_medicas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "citas_medicas_insert_authenticated"
  ON public.citas_medicas FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "citas_medicas_update_authenticated"
  ON public.citas_medicas FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "citas_medicas_delete_authenticated"
  ON public.citas_medicas FOR DELETE
  TO authenticated
  USING (true);

-- Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_status ON public.citas_medicas(status);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));

-- Índice único para evitar citas duplicadas en la misma hora del mismo día
-- (Excepto las citas canceladas)
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_medicas_unique_datetime
  ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at))
  WHERE status != 'cancelled';

-- Función para actualizar updated_at automáticamente
-- (Esta función debería existir ya, si no, créala)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at en citas_medicas
DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
CREATE TRIGGER on_citas_medicas_updated
  BEFORE UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Función para validar que no haya citas duplicadas en la misma hora
CREATE OR REPLACE FUNCTION public.validate_appointment_time()
RETURNS TRIGGER AS $$
DECLARE
  existing_appointment_count INTEGER;
BEGIN
  -- Contar citas existentes en la misma fecha y hora (excluyendo canceladas)
  SELECT COUNT(*)
  INTO existing_appointment_count
  FROM public.citas_medicas
  WHERE DATE(appointment_at) = DATE(NEW.appointment_at)
    AND EXTRACT(HOUR FROM appointment_at) = EXTRACT(HOUR FROM NEW.appointment_at)
    AND status != 'cancelled'
    AND appointment_number != COALESCE(NEW.appointment_number, gen_random_uuid());

  IF existing_appointment_count > 0 THEN
    RAISE EXCEPTION 'Ya existe una cita programada para esta hora. Por favor seleccione otra hora.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para validar antes de insertar o actualizar
DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
CREATE TRIGGER validate_appointment_time_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();

-- Verificar que todo se creó correctamente
SELECT
  'Tabla citas_medicas creada correctamente' as status,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'citas_medicas') as politicas_count,
  (SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'citas_medicas') as indices_count;
