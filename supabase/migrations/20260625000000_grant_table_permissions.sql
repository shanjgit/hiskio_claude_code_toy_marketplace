GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_images TO authenticated;
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT ON public.products TO anon;
GRANT SELECT ON public.product_images TO anon;
