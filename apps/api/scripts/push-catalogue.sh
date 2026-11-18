#!/usr/bin/env bash
# Copies the service catalogue (categories and items) from the local dev database into another one.
#
#   TARGET_DATABASE_URL=<connection string> scripts/push-catalogue.sh              # dry run: prints the plan, changes nothing
#   TARGET_DATABASE_URL=<connection string> scripts/push-catalogue.sh --apply      # adds what is missing
#   TARGET_DATABASE_URL=<connection string> scripts/push-catalogue.sh --apply --overwrite
#                                                                                  # also replaces prices and details of items that already exist
#
# Run it from apps/api. The source is DATABASE_URL from .env and must be on localhost. Categories match on slug,
# items on category and name. It never deletes anything. Promotions and banners are not copied. Image links that
# are not https (such as http://localhost:4000/...) are not copied, because they cannot load from the target.
set -euo pipefail

apply=0
overwrite=0
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    --overwrite) overwrite=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

: "${TARGET_DATABASE_URL:?Set TARGET_DATABASE_URL to the target connection string}"
[ -f .env ] && { set -a; . ./.env; set +a; }
: "${DATABASE_URL:?DATABASE_URL (the local source) is not set}"

host_of() { echo "$1" | sed -E 's#^[a-z]+://([^@]*@)?([^:/?]+).*#\2#'; }
case "$(host_of "$DATABASE_URL")" in
  localhost | 127.0.0.1) ;;
  *) echo "Refusing: the source database is not on localhost." >&2; exit 1 ;;
esac
[ "$DATABASE_URL" != "$TARGET_DATABASE_URL" ] || { echo "Refusing: source and target are the same." >&2; exit 1; }

echo "Source: $(host_of "$DATABASE_URL")  Target: $(host_of "$TARGET_DATABASE_URL")"
if [ "$apply" = 1 ]; then
  [ "$overwrite" = 1 ] && echo "Mode: APPLY with overwrite" || echo "Mode: APPLY (adds missing rows only)"
else
  echo "Mode: dry run (nothing is written)"
fi

stage="$(mktemp)"
trap 'rm -f "$stage"' EXIT

# Rows from the source, written as INSERTs into temporary staging tables on the target.
{
  echo "create temp table stg_cat (slug text, name text, image_url text, sort_order int, is_active boolean);"
  echo "create temp table stg_item (cat_slug text, name text, description text, unit text, price_paise int, offer_price_paise int, image_url text, sort_order int, is_active boolean);"
  psql "$DATABASE_URL" -At -c "
    select format('insert into stg_cat values (%L,%L,%L,%s,%L);', slug, name, case when image_url ~ '^https://' then image_url end, sort_order, is_active)
    from catalog_categories order by sort_order, slug;"
  psql "$DATABASE_URL" -At -c "
    select format('insert into stg_item values (%L,%L,%L,%L,%s,%s,%L,%s,%L);', c.slug, i.name, i.description, i.unit::text, i.price_paise,
                  coalesce(i.offer_price_paise::text, 'null'), case when i.image_url ~ '^https://' then i.image_url end, i.sort_order, i.is_active)
    from catalog_items i join catalog_categories c on c.id = i.category_id order by c.sort_order, c.slug, i.sort_order, i.name;"
} > "$stage"

psql "$TARGET_DATABASE_URL" -X -v ON_ERROR_STOP=1 -v apply="$apply" -v overwrite="$overwrite" -f /dev/stdin <<SQL
\\set QUIET on
begin;
\\i $stage

\\echo
\\echo '== Categories'
select s.slug, case when c.id is null then 'ADD' when s.name is distinct from c.name or s.sort_order <> c.sort_order or s.is_active <> c.is_active then 'DIFFERS' else 'same' end as plan
from stg_cat s left join catalog_categories c on c.slug = s.slug order by s.sort_order, s.slug;

\\echo
\\echo '== Items'
select s.cat_slug, s.name, s.price_paise as local_paise, i.price_paise as target_paise,
       case when c.id is null or i.id is null then 'ADD'
            when (s.description, s.unit, s.price_paise, s.offer_price_paise, s.sort_order, s.is_active)
                 is distinct from (i.description, i.unit::text, i.price_paise, i.offer_price_paise, i.sort_order, i.is_active) then 'DIFFERS'
            else 'same' end as plan
from stg_item s
left join catalog_categories c on c.slug = s.cat_slug
left join catalog_items i on i.category_id = c.id and i.name = s.name
order by s.cat_slug, s.sort_order, s.name;

-- Categories: add the missing ones. Existing ones are only changed with --overwrite.
insert into catalog_categories (id, name, slug, image_url, sort_order, is_active, updated_at)
select gen_random_uuid(), name, slug, image_url, sort_order, is_active, now() from stg_cat
on conflict (slug) do update set
  name = case when :overwrite = 1 then excluded.name else catalog_categories.name end,
  sort_order = case when :overwrite = 1 then excluded.sort_order else catalog_categories.sort_order end,
  is_active = case when :overwrite = 1 then excluded.is_active else catalog_categories.is_active end,
  image_url = coalesce(catalog_categories.image_url, excluded.image_url),
  updated_at = case when :overwrite = 1 then now() else catalog_categories.updated_at end;

-- Items that already exist: only with --overwrite.
update catalog_items i set
  description = s.description, unit = s.unit::"ItemUnit", price_paise = s.price_paise, offer_price_paise = s.offer_price_paise,
  sort_order = s.sort_order, is_active = s.is_active, image_url = coalesce(i.image_url, s.image_url), updated_at = now()
from stg_item s join catalog_categories c on c.slug = s.cat_slug
where :overwrite = 1 and i.category_id = c.id and i.name = s.name;

-- Items that do not exist yet.
insert into catalog_items (id, category_id, name, description, unit, price_paise, offer_price_paise, image_url, sort_order, is_active, updated_at)
select gen_random_uuid(), c.id, s.name, s.description, s.unit::"ItemUnit", s.price_paise, s.offer_price_paise, s.image_url, s.sort_order, s.is_active, now()
from stg_item s join catalog_categories c on c.slug = s.cat_slug
where not exists (select 1 from catalog_items i where i.category_id = c.id and i.name = s.name);

\\echo
\\echo '== Target after this run'
select (select count(*) from catalog_categories) as categories, (select count(*) from catalog_items) as items;

\\if :apply
  commit;
  \\echo 'Applied.'
\\else
  rollback;
  \\echo 'Dry run: rolled back, nothing was written. Re-run with --apply to write.'
\\endif
SQL
