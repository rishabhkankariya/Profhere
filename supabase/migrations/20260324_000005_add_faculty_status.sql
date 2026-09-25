-- Add status column to faculty table
ALTER TABLE public.faculty 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'available'
CHECK (status IN ('available', 'away', 'busy', 'on_break'));

-- Add index for status lookups
CREATE INDEX IF NOT EXISTS idx_faculty_status ON public.faculty(status);
