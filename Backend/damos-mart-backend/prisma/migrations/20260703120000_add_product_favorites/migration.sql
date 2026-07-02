-- CreateTable
CREATE TABLE "product_favorites" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "product_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_favorites_pkey" PRIMARY KEY ("id")
);

-- CreateUniqueIndex
CREATE UNIQUE INDEX "product_favorites_user_id_product_id_key" ON "product_favorites"("user_id", "product_id");

-- AddForeignKeys
ALTER TABLE "product_favorites"
ADD CONSTRAINT "product_favorites_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE;

ALTER TABLE "product_favorites"
ADD CONSTRAINT "product_favorites_product_id_fkey"
    FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE;
