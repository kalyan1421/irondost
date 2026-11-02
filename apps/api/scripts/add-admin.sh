#!/usr/bin/env bash
# Creates a super admin who signs in to the admin console with email + password in the live Supabase database, or resets
# that admin's password. Safe to run again: an existing admin only gets the new password.
#
#   cd apps/api && scripts/add-admin.sh
#
# It asks for the admin email, a new admin password (10+ characters) and the Supabase database password, then connects to
# the IronDost project through the session pooler (port 5432). Not the direct host: that one is IPv6 only on the free plan.
# Nothing is written to disk and the passwords are not echoed. The admin password is hashed (scrypt) by prisma/set-admin.ts
# before it is stored, and the hash never leaves the database.
set -euo pipefail

ref="gsqcgqgsatppgccuiqbb"
host="aws-0-ap-southeast-1.pooler.supabase.com"

read -r -p "Admin email: " ADMIN_EMAIL
read -r -s -p "Admin password (10+ characters): " ADMIN_PASSWORD
echo
read -r -s -p "Supabase database password: " DB_PASSWORD
echo

if [ "${#ADMIN_PASSWORD}" -lt 10 ]; then
  echo "The admin password needs at least 10 characters." >&2
  exit 2
fi

# The database password may contain characters that are special in a URL.
encoded=$(DB_PASSWORD="$DB_PASSWORD" node -e 'process.stdout.write(encodeURIComponent(process.env.DB_PASSWORD))')

export ADMIN_EMAIL ADMIN_PASSWORD
export DATABASE_URL="postgresql://postgres.${ref}:${encoded}@${host}:5432/postgres"
pnpm db:admin
