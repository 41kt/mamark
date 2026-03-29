-- Supabase Schema for Mamark App
-- Run this script in your Supabase project's SQL Editor

-- 1. Users Table (Public Profile Data)
-- Note: Authentication passwords are automatically managed securely by Supabase Auth (auth.users).
-- We link our public.users table to auth.users using the 'id' field.
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('supplier', 'customer')),
  store_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Turn on Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policies for public.users
CREATE POLICY "Public users are viewable by everyone."
  ON public.users FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile."
  ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile."
  ON public.users FOR UPDATE USING (auth.uid() = id);


-- 2. Products Table
CREATE TABLE public.products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  supplier_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  quantity INTEGER DEFAULT 0 NOT NULL,
  unit TEXT DEFAULT 'قطعة' NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Policies for public.products
CREATE POLICY "Products are viewable by everyone."
  ON public.products FOR SELECT USING (true);

CREATE POLICY "Suppliers can insert their own products."
  ON public.products FOR INSERT WITH CHECK (
    auth.uid() = supplier_id AND 
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'supplier')
  );

CREATE POLICY "Suppliers can update their own products."
  ON public.products FOR UPDATE USING (auth.uid() = supplier_id);

CREATE POLICY "Suppliers can delete their own products."
  ON public.products FOR DELETE USING (auth.uid() = supplier_id);


-- 3. Inventory Table
CREATE TABLE public.inventory (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  store_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  quantity_available INTEGER DEFAULT 0 NOT NULL,
  quantity_sold INTEGER DEFAULT 0 NOT NULL,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(store_id, product_id)
);

ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Inventory is viewable by everyone."
  ON public.inventory FOR SELECT USING (true);

CREATE POLICY "Suppliers can manage their own inventory."
  ON public.inventory FOR ALL USING (auth.uid() = store_id);

-- 4. Cart Table
CREATE TABLE public.cart (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  quantity INTEGER DEFAULT 1 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.cart ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own cart."
  ON public.cart FOR ALL USING (auth.uid() = user_id);

-- 5. Orders Table
CREATE TABLE public.orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  supplier_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  items JSONB NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'delivered', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can see their own orders."
  ON public.orders FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Suppliers can see orders for their products."
  ON public.orders FOR SELECT USING (auth.uid() = supplier_id);

CREATE POLICY "Customers can create orders."
  ON public.orders FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Suppliers can update order status."
  ON public.orders FOR UPDATE USING (auth.uid() = supplier_id);

-- 6. Ratings Table
CREATE TABLE public.ratings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(product_id, user_id)
);

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ratings are viewable by everyone."
  ON public.ratings FOR SELECT USING (true);

CREATE POLICY "Users can rate products they bought."
  ON public.ratings FOR INSERT WITH CHECK (auth.uid() = user_id);


-- Set up Realtime to listen for changes
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE public.cart;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ratings;

-- 7. Storage Policies (Run these in SQL Editor or setup in Dashboard)
-- Create buckets first in Dashboard: 'products', 'avatars'

-- Policies for 'products' bucket
-- Allow public read
-- CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'products');

-- Allow suppliers to upload
-- CREATE POLICY "Supplier Upload" ON storage.objects FOR INSERT WITH CHECK (
--   bucket_id = 'products' AND 
--   (SELECT role FROM public.users WHERE id = auth.uid()) = 'supplier'
-- );

-- Policies for 'avatars' bucket
-- Allow public read
-- CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- Allow users to upload their own avatar
-- CREATE POLICY "User Upload" ON storage.objects FOR INSERT WITH CHECK (
--   bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
-- );
