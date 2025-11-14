-- ============================================
-- MIGRACIÓN DE TABLA CITAS_MEDICAS
-- Actualiza la estructura para usar id como PK y appointment_number como INT8 autoincremental
-- ============================================

-- IMPORTANTE: Este script modificará la estructura de la tabla
-- Asegúrate de hacer un respaldo antes de ejecutar

-- 1. Crear tabla temporal con nueva estructura
CREATE TABLE IF NOT EXISTS public.citas_medicas_new (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  appointment_number BIGINT,
  client_name TEXT NOT NULL,
  client_id_number TEXT NOT NULL,
  appointment_at TIMESTAMP WITH TIME ZONE NOT NULL,
  reason TEXT NOT NULL,
  cost DECIMAL(10, 2),
  attending_doctor TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  FOREIGN KEY (client_id_number) REFERENCES public.clientes(id_number) ON DELETE CASCADE
);

-- 2. Copiar datos existentes (si los hay)
-- Nota: appointment_number se asignará después
INSERT INTO public.citas_medicas_new (
  client_name,
  client_id_number,
  appointment_at,
  reason,
  cost,
  attending_doctor,
  notes,
  created_at,
  updated_at
)
SELECT
  client_name,
  client_id_number,
  appointment_at,
  reason,
  cost,
  attending_doctor,
  notes,
  created_at,
  updated_at
FROM public.citas_medicas
ORDER BY created_at ASC;

-- 3. Eliminar tabla antigua
DROP TABLE IF EXISTS public.citas_medicas CASCADE;

-- 4. Renombrar tabla nueva
ALTER TABLE public.citas_medicas_new RENAME TO citas_medicas;

-- 5. Crear secuencia para appointment_number
CREATE SEQUENCE IF NOT EXISTS public.citas_medicas_appointment_number_seq
  START WITH 1
  INCREMENT BY 1
  NO MAXVALUE
  NO MINVALUE
  CACHE 1;

-- 6. Asignar números de cita a registros existentes
UPDATE public.citas_medicas
SET appointment_number = nextval('public.citas_medicas_appointment_number_seq')
WHERE appointment_number IS NULL
ORDER BY created_at ASC;

-- 7. Hacer appointment_number NOT NULL y UNIQUE después de asignar valores
ALTER TABLE public.citas_medicas
  ALTER COLUMN appointment_number SET NOT NULL,
  ALTER COLUMN appointment_number SET DEFAULT nextval('public.citas_medicas_appointment_number_seq'::regclass);

ALTER TABLE public.citas_medicas
  ADD CONSTRAINT citas_medicas_appointment_number_unique UNIQUE (appointment_number);

-- 8. Habilitar RLS
ALTER TABLE public.citas_medicas ENABLE ROW LEVEL SECURITY;

-- 9. Crear políticas de seguridad
DROP POLICY IF EXISTS "citas_medicas_select_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_insert_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_update_authenticated" ON public.citas_medicas;
DROP POLICY IF EXISTS "citas_medicas_delete_authenticated" ON public.citas_medicas;

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

-- 10. Crear índices
CREATE INDEX IF NOT EXISTS idx_citas_medicas_id ON public.citas_medicas(id);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_number ON public.citas_medicas(appointment_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_appointment_at ON public.citas_medicas(appointment_at);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_client_id_number ON public.citas_medicas(client_id_number);
CREATE INDEX IF NOT EXISTS idx_citas_medicas_date ON public.citas_medicas(DATE(appointment_at));
CREATE INDEX IF NOT EXISTS idx_citas_medicas_attending_doctor ON public.citas_medicas(attending_doctor);

-- 11. Índice único para evitar citas duplicadas
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_medicas_unique_datetime
  ON public.citas_medicas(DATE(appointment_at), EXTRACT(HOUR FROM appointment_at));

-- 12. Función para actualizar updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 13. Trigger para updated_at
DROP TRIGGER IF EXISTS on_citas_medicas_updated ON public.citas_medicas;
CREATE TRIGGER on_citas_medicas_updated
  BEFORE UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 14. Función de validación de horarios
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
    AND id != COALESCE(NEW.id, gen_random_uuid());

  IF existing_appointment_count > 0 THEN
    RAISE EXCEPTION 'Ya existe una cita programada para esta hora. Por favor seleccione otra hora.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 15. Trigger de validación
DROP TRIGGER IF EXISTS validate_appointment_time_trigger ON public.citas_medicas;
CREATE TRIGGER validate_appointment_time_trigger
  BEFORE INSERT OR UPDATE ON public.citas_medicas
  FOR EACH ROW EXECUTE FUNCTION public.validate_appointment_time();

-- 16. Verificación final
SELECT
  'Migración completada exitosamente' as status,
  (SELECT COUNT(*) FROM public.citas_medicas) as total_citas,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'citas_medicas') as politicas,
  (SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'citas_medicas') as indices;
