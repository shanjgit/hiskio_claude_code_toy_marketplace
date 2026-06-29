-- =====================================================================================
-- Add nickname to profiles and update all display-name RPCs to prefer it
-- =====================================================================================

-- 1) Add nickname column
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS nickname TEXT;

-- 2) Update get_profile_names to also expose nickname
DROP FUNCTION IF EXISTS public.get_profile_names(uuid[]);
CREATE FUNCTION public.get_profile_names(user_ids uuid[] DEFAULT NULL)
RETURNS TABLE (
  user_id uuid,
  first_name text,
  last_name text,
  nickname text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.user_id, p.first_name, p.last_name, p.nickname
  FROM public.profiles p
  WHERE user_ids IS NULL OR p.user_id = ANY(user_ids);
$$;

-- 3) Update get_public_products — seller_name prefers nickname
DROP FUNCTION IF EXISTS public.get_public_products(text, text);
CREATE FUNCTION public.get_public_products(search_term text DEFAULT NULL, sort_by text DEFAULT 'created_at')
RETURNS TABLE (
  id uuid,
  product_name text,
  price numeric,
  color text,
  leather text,
  year_purchased integer,
  stamp text,
  location text,
  description text,
  first_image_url text,
  created_at timestamptz,
  seller_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.product_name,
    p.price,
    p.color,
    p.leather,
    p.year_purchased,
    p.stamp,
    p.location,
    p.description,
    pi.image_url AS first_image_url,
    p.created_at,
    COALESCE(
      NULLIF(prof.nickname, ''),
      NULLIF(TRIM(COALESCE(prof.first_name, '') || ' ' || COALESCE(prof.last_name, '')), ''),
      'Anonymous'
    ) AS seller_name
  FROM public.products p
  LEFT JOIN LATERAL (
    SELECT image_url
    FROM public.product_images
    WHERE product_id = p.id
    ORDER BY created_at ASC
    LIMIT 1
  ) pi ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) prof ON TRUE
  WHERE
    CASE
      WHEN search_term IS NOT NULL THEN
        (p.product_name ILIKE '%' || search_term || '%' OR
         p.description ILIKE '%' || search_term || '%' OR
         p.color ILIKE '%' || search_term || '%' OR
         p.leather ILIKE '%' || search_term || '%' OR
         p.location ILIKE '%' || search_term || '%')
      ELSE TRUE
    END
  ORDER BY
    CASE WHEN sort_by = 'price_asc' THEN p.price END ASC,
    CASE WHEN sort_by = 'price_desc' THEN p.price END DESC,
    CASE WHEN sort_by = 'created_at' OR sort_by IS NULL THEN p.created_at END DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_products(text, text) TO anon, authenticated;

-- 4) Update get_public_product_detail — seller_name prefers nickname
DROP FUNCTION IF EXISTS public.get_public_product_detail(uuid);
CREATE FUNCTION public.get_public_product_detail(product_id uuid)
RETURNS TABLE (
  id uuid,
  product_name text,
  price numeric,
  color text,
  leather text,
  year_purchased integer,
  stamp text,
  location text,
  description text,
  created_at timestamptz,
  seller_name text,
  images json
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.product_name,
    p.price,
    p.color,
    p.leather,
    p.year_purchased,
    p.stamp,
    p.location,
    p.description,
    p.created_at,
    COALESCE(
      NULLIF(prof.nickname, ''),
      NULLIF(TRIM(COALESCE(prof.first_name, '') || ' ' || COALESCE(prof.last_name, '')), ''),
      'Anonymous'
    ) AS seller_name,
    COALESCE(imgs.images, '[]'::json) AS images
  FROM public.products p
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) prof ON TRUE
  LEFT JOIN LATERAL (
    SELECT json_agg(
      json_build_object(
        'id', pi.id,
        'image_url', pi.image_url,
        'created_at', pi.created_at
      ) ORDER BY pi.created_at ASC
    ) AS images
    FROM public.product_images pi
    WHERE pi.product_id = p.id
  ) imgs ON TRUE
  WHERE p.id = product_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_product_detail(uuid) TO anon, authenticated;

-- 5) Update get_user_conversations — seller_name and buyer_name prefer nickname
DROP FUNCTION IF EXISTS public.get_user_conversations();
CREATE FUNCTION public.get_user_conversations()
RETURNS TABLE(
  id uuid,
  product_id uuid,
  seller_id uuid,
  updated_at timestamptz,
  last_message_at timestamptz,
  product_name text,
  first_image_url text,
  seller_name text,
  buyer_name text,
  last_message text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    c.id,
    c.product_id,
    p.user_id AS seller_id,
    c.updated_at,
    c.last_message_at,
    p.product_name,
    img.image_url AS first_image_url,
    COALESCE(
      NULLIF(ps.nickname, ''),
      NULLIF(TRIM(COALESCE(ps.first_name, '') || ' ' || COALESCE(ps.last_name, '')), ''),
      'Anonymous'
    ) AS seller_name,
    COALESCE(
      NULLIF(pb.nickname, ''),
      NULLIF(TRIM(COALESCE(pb.first_name, '') || ' ' || COALESCE(pb.last_name, '')), ''),
      'Anonymous'
    ) AS buyer_name,
    lm.body AS last_message
  FROM public.conversations c
  JOIN public.products p ON p.id = c.product_id
  LEFT JOIN LATERAL (
    SELECT pi.image_url
    FROM public.product_images pi
    WHERE pi.product_id = p.id
    ORDER BY pi.created_at ASC
    LIMIT 1
  ) img ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) ps ON TRUE
  LEFT JOIN LATERAL (
    SELECT pa.user_id
    FROM public.participants pa
    WHERE pa.conversation_id = c.id AND pa.user_id != p.user_id
    LIMIT 1
  ) buyer ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[buyer.user_id]) gp
  ) pb ON TRUE
  LEFT JOIN LATERAL (
    SELECT m.body
    FROM public.messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  WHERE EXISTS (
    SELECT 1 FROM public.participants pa
    WHERE pa.conversation_id = c.id AND pa.user_id = auth.uid()
  )
  ORDER BY COALESCE(c.last_message_at, c.updated_at) DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_conversations() TO authenticated;

-- 6) Update get_conversation_details — seller_name and buyer_name prefer nickname
DROP FUNCTION IF EXISTS public.get_conversation_details(uuid);
CREATE FUNCTION public.get_conversation_details(conv_id uuid)
RETURNS TABLE(
  id uuid,
  product_id uuid,
  seller_id uuid,
  buyer_id uuid,
  product_name text,
  price numeric,
  first_image_url text,
  seller_name text,
  buyer_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    c.id,
    c.product_id,
    p.user_id AS seller_id,
    buyer.user_id AS buyer_id,
    p.product_name,
    p.price,
    img.image_url AS first_image_url,
    COALESCE(
      NULLIF(ps.nickname, ''),
      NULLIF(TRIM(COALESCE(ps.first_name, '') || ' ' || COALESCE(ps.last_name, '')), ''),
      'Anonymous'
    ) AS seller_name,
    COALESCE(
      NULLIF(pb.nickname, ''),
      NULLIF(TRIM(COALESCE(pb.first_name, '') || ' ' || COALESCE(pb.last_name, '')), ''),
      'Anonymous'
    ) AS buyer_name
  FROM public.conversations c
  JOIN public.products p ON p.id = c.product_id
  LEFT JOIN LATERAL (
    SELECT pi.image_url
    FROM public.product_images pi
    WHERE pi.product_id = p.id
    ORDER BY pi.created_at ASC
    LIMIT 1
  ) img ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) ps ON TRUE
  LEFT JOIN LATERAL (
    SELECT pa.user_id
    FROM public.participants pa
    WHERE pa.conversation_id = c.id AND pa.user_id != p.user_id
    LIMIT 1
  ) buyer ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[buyer.user_id]) gp
  ) pb ON TRUE
  WHERE c.id = conv_id
    AND EXISTS (
      SELECT 1 FROM public.participants pa
      WHERE pa.conversation_id = c.id AND pa.user_id = auth.uid()
    )
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_details(uuid) TO authenticated;

-- 7) Update get_user_saved_products — seller_name prefers nickname
DROP FUNCTION IF EXISTS public.get_user_saved_products();
CREATE FUNCTION public.get_user_saved_products()
RETURNS TABLE(
  saved_id uuid,
  product_id uuid,
  product_name text,
  price numeric,
  location text,
  first_image_url text,
  seller_name text,
  saved_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    sp.id AS saved_id,
    p.id AS product_id,
    p.product_name,
    p.price,
    COALESCE(p.location, 'Location not specified') AS location,
    img.image_url AS first_image_url,
    COALESCE(
      NULLIF(prof.nickname, ''),
      NULLIF(TRIM(COALESCE(prof.first_name, '') || ' ' || COALESCE(prof.last_name, '')), ''),
      'Anonymous'
    ) AS seller_name,
    sp.created_at AS saved_at
  FROM public.saved_products sp
  JOIN public.products p ON p.id = sp.product_id
  LEFT JOIN LATERAL (
    SELECT pi.image_url
    FROM public.product_images pi
    WHERE pi.product_id = p.id
    ORDER BY pi.created_at ASC
    LIMIT 1
  ) img ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) prof ON TRUE
  WHERE sp.user_id = auth.uid()
  ORDER BY sp.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_saved_products() TO authenticated;

-- 8) Update get_message_read_receipts — user_name prefers nickname
DROP FUNCTION IF EXISTS public.get_message_read_receipts(uuid);
CREATE FUNCTION public.get_message_read_receipts(msg_id uuid)
RETURNS TABLE (
  user_id uuid,
  user_name text,
  read_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    ms.user_id,
    COALESCE(
      NULLIF(prof.nickname, ''),
      NULLIF(TRIM(COALESCE(prof.first_name, '') || ' ' || COALESCE(prof.last_name, '')), ''),
      'Anonymous'
    ) AS user_name,
    ms.read_at
  FROM public.message_status ms
  JOIN public.messages m ON m.id = ms.message_id
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name, gp.nickname
    FROM public.get_profile_names(ARRAY[ms.user_id]) gp
  ) prof ON TRUE
  WHERE ms.message_id = msg_id
    AND ms.read_at IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.participants pa
      WHERE pa.conversation_id = m.conversation_id AND pa.user_id = auth.uid()
    )
  ORDER BY ms.read_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_message_read_receipts(uuid) TO authenticated;
