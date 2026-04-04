-- =============================================
-- Mamark: NEW SQL for Chat Feature
-- Run this in your Supabase SQL Editor
-- =============================================

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Only users who are part of the order can read messages
CREATE POLICY "Order participants can read messages"
  ON public.messages FOR SELECT USING (
    auth.uid() IN (
      SELECT customer_id FROM public.orders WHERE id = order_id
      UNION
      SELECT supplier_id FROM public.orders WHERE id = order_id
    )
  );

-- Only users who are part of the order can send messages
CREATE POLICY "Order participants can send messages"
  ON public.messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (
      SELECT customer_id FROM public.orders WHERE id = order_id
      UNION
      SELECT supplier_id FROM public.orders WHERE id = order_id
    )
  );

-- Enable Realtime for live messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- =============================================
-- Supabase Storage Setup Instructions
-- =============================================
-- 1. Go to Storage in your Supabase dashboard.
-- 2. Create a bucket named exactly: MY_IMAGE
-- 3. Set it as PUBLIC.
-- 4. Run these policies:

-- Allow everyone to read product images
CREATE POLICY "Public read product images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'MY_IMAGE');

-- Allow authenticated suppliers to upload
CREATE POLICY "Suppliers can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'MY_IMAGE' AND
    auth.role() = 'authenticated'
  );

-- Allow suppliers to delete their own uploads
CREATE POLICY "Suppliers can delete their images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'MY_IMAGE' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =============================================
-- Avatars bucket setup
-- =============================================
-- Create a bucket named: avatars (public)

CREATE POLICY "Public read avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.role() = 'authenticated'
  );
