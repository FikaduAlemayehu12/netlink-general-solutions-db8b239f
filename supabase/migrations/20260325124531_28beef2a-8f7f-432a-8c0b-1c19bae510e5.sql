
-- Add new roles to the app_role enum (must be separate transaction)
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'cio';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'finance_manager';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'bd_head';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'network_engineer';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'support_tech';
