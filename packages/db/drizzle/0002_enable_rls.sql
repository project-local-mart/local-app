-- Deny-by-default row level security on every application table.
--
-- Localmart only reaches the database through apps/api, which connects as the
-- tables' owner. Owners bypass RLS (it is not FORCEd), so the API is
-- unaffected. Any other role — for example Supabase's `anon` and
-- `authenticated` roles used by its auto-generated Data API — matches no
-- policy and therefore sees no rows. Add explicit policies here only if a
-- non-owner role ever needs access.
ALTER TABLE "communities" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "merchants" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "moderators" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "pos_connections" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "products" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;
