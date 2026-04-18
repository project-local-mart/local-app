ALTER TABLE "products" ALTER COLUMN "images" SET DEFAULT '{}';--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "categories" SET DEFAULT '{}';--> statement-breakpoint
ALTER TABLE "merchants" ADD COLUMN "user_id" text;