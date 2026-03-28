-- Add updated_at column to track edits
ALTER TABLE public.direct_messages ADD COLUMN updated_at timestamptz DEFAULT now();

-- Drop the old receiver-only update policy
DROP POLICY IF EXISTS "Users update own received DMs" ON public.direct_messages;

-- Allow both sender (edit content) and receiver (mark read) to update
CREATE POLICY "Users can update own DMs"
ON public.direct_messages
FOR UPDATE
USING ((auth.uid() = sender_id) OR (auth.uid() = receiver_id));