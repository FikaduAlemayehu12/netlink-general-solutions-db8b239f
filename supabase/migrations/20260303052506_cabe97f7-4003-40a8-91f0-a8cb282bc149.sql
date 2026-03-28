
-- Direct messages table
CREATE TABLE public.direct_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL,
  receiver_id uuid NOT NULL,
  content text NOT NULL DEFAULT '',
  attachment_urls text[] DEFAULT '{}'::text[],
  read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own DMs" ON public.direct_messages
FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users send DMs" ON public.direct_messages
FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users update own received DMs" ON public.direct_messages
FOR UPDATE USING (auth.uid() = receiver_id);

CREATE POLICY "Users delete own sent DMs" ON public.direct_messages
FOR DELETE USING (auth.uid() = sender_id);

-- DM reactions
CREATE TABLE public.dm_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.direct_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  reaction text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, reaction)
);

ALTER TABLE public.dm_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "DM participants read reactions" ON public.dm_reactions
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM direct_messages dm
    WHERE dm.id = dm_reactions.message_id
    AND (auth.uid() = dm.sender_id OR auth.uid() = dm.receiver_id)
  )
);

CREATE POLICY "Users add DM reactions" ON public.dm_reactions
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users remove own DM reactions" ON public.dm_reactions
FOR DELETE USING (auth.uid() = user_id);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dm_reactions;
