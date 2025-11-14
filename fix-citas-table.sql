-- ============================================
-- SCRIPT PARA REPARAR TABLA CITAS_MEDICAS
-- Ejecuta este script en Supabase SQL Editor
-- ============================================

-- 1. ELIMINAR TABLA EXISTENTE (CUIDADO: Borra todos los datos)
DROP TABLE IF EXISTS public.citas_medicas CASCADE;

-- 2. CREAR TABLA CORRECTAMENTE
CREATE TABLE public.citas_medicas (
  appointment_number UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_name TEXT NOT NULL,
  client_id_number TEXT NOT NULL,
  appointment_at TIMESTAMP WITH TIME ZONE NOT NULL,
  reason TEXT NOT NULL,
  cost DECIMAL(10, 2),
  attending_doctor TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Referencia a clientes
  FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE
);

-- 3. HABILITAR RLS
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

-- 4. ELIMINAR POLÍTICAS ANTERIORES
DROP POLICY IF EXISTS "citas_medicas_select_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_insert_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_update_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_delete_authenticated" ON public.citas_medicas;

-- 5. CREAR POLÍTICAS DE SEGURIDAD
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

-- 6. CREAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_status ON public.citas_medicas(status);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));
CREATE INDEX IF NOT EXISTS idx_citas_medicas_attending_doctor ON public.citas_medicas(attending_doctor);

-- 7. ÍNDICE ÚNICO PARA EVITAR CITAS DUPLICADAS
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_medicas_unique_datetime
  ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at))
  WHERE status != 'cancelled';

-- 8. FUNCIÓN PARA ACTUALIZAR updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. TRIGGER PARA updated_at
DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
CREATE TRIGGER on_citas_medicas_updated
  BEFORE UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 10. FUNCIÓN DE VALIDACIÓN DE HORARIOS
CREATE OR REPLACE FUNCTION public.validate_appointment_time()
RETURNS TRIGGER AS $$
DECLARE
  existing_appointment_count INTEGER;
BEGIN
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

-- 11. TRIGGER DE VALIDACIÓN
DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
CREATE TRIGGER validate_appointment_time_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();

-- 12. VERIFICACIÓN FINAL
SELECT
  'Tabla citas_medicas creada correctamente' as status,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'citas_medicas') as politicas,
  (SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'citas_medicas') as indices;

-- 13. INSERTAR DATOS DE PRUEBA (Opcional - descomenta si quieres)
/*
INSERT INTO public.citas_medicas (
  client_name,
  client_id_number,
  appointment_at,
  reason,
  cost,
  attending_doctor,
  notes
) VALUES (
  'Juan Pérez',
  '1234567890',
  '2025-11-15 09:00:00+00',
  'Limpieza dental',
  50.00,
  'a550edae-8c2f-4ec7-a929-7a123f456789',
  'Primera visita'
);
*/
