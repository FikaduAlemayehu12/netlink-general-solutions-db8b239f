
-- Allow CEO to read all direct messages for oversight
DROP POLICY IF EXISTS "Users read own DMs" ON public.direct_messages;
CREATE POLICY "Users read own DMs" ON public.direct_messages
FOR SELECT TO public
USING (
  auth.uid() = sender_id 
  OR auth.uid() = receiver_id 
  OR is_ceo(auth.uid())
);

-- Allow CEO to delete project groups (for recycle bin)
CREATE POLICY "CEO deletes project groups" ON public.project_groups
FOR DELETE TO authenticated
USING (is_ceo(auth.uid()) OR auth.uid() = created_by);

-- Allow CEO to read all DM reactions for oversight
DROP POLICY IF EXISTS "DM participants read reactions" ON public.dm_reactions;
CREATE POLICY "DM participants read reactions" ON public.dm_reactions
FOR SELECT TO public
USING (
  EXISTS (
    SELECT 1 FROM direct_messages dm
    WHERE dm.id = dm_reactions.message_id
    AND (auth.uid() = dm.sender_id OR auth.uid() = dm.receiver_id OR is_ceo(auth.uid()))
  )
);
