-- Add updated_at column to step_tracker_daily table to track when step records are updated
ALTER TABLE step_tracker_daily
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Update existing records to have the same updated_at as created_at
UPDATE step_tracker_daily
SET updated_at = created_at
WHERE updated_at IS NULL;

-- Make updated_at NOT NULL after setting values for existing records
ALTER TABLE step_tracker_daily
ALTER COLUMN updated_at SET NOT NULL;

-- Create an index on updated_at for better query performance
CREATE INDEX IF NOT EXISTS step_tracker_daily_updated_at_idx ON step_tracker_daily(updated_at);
