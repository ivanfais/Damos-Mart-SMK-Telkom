/**
 * One-off script: mirror the live Railway catalog (categories + products + variants)
 * into the local dev database, via the public REST API (no direct DB credentials needed).
 *
 * Image URLs are intentionally left null — the Railway-hosted files behind them
 * return 404 (uploads directory lost its contents), so importing those broken
 * paths would just carry the dead links over locally. Re-upload real photos
 * through the app once pointed at this local backend; local disk storage
 * persists normally (unlike the current Railway environment).
 *
 * Usage: npx ts-node scripts/pull-catalog-from-railway.ts
 */
import { PrismaClient } from '@prisma/client';

const RAILWAY_API = 'https://damos-mart-smk-telkom-production.up.railway.app/api/v1';
const prisma = new PrismaClient();

async function main() {
  const categoriesRes = await fetch(`${RAILWAY_API}/categories`);
  const categoriesJson: any = await categoriesRes.json();
  const categories = categoriesJson.data as Array<{
    id: string; name: string; iconUrl: string | null; sortOrder: number;
  }>;

  for (const c of categories) {
    await prisma.category.upsert({
      where: { id: c.id },
      create: { id: c.id, name: c.name, iconUrl: null, sortOrder: c.sortOrder },
      update: { name: c.name, sortOrder: c.sortOrder },
    });
  }
  console.log(`Categories synced: ${categories.length}`);

  const productsRes = await fetch(`${RAILWAY_API}/products?limit=200`);
  const productsJson: any = await productsRes.json();
  const products = productsJson.data as Array<{
    id: string; categoryId: string; name: string; description: string | null;
    price: string; stock: number; isPreorder: boolean; preorderEstimation: string | null;
    isActive: boolean;
    variants: Array<{ id: string; variantName: string; additionalPrice: string; stock: number }>;
  }>;

  for (const p of products) {
    await prisma.product.upsert({
      where: { id: p.id },
      create: {
        id: p.id,
        categoryId: p.categoryId,
        name: p.name,
        description: p.description,
        price: p.price,
        stock: p.stock,
        imageUrl: null,
        isPreorder: p.isPreorder,
        preorderEstimation: p.preorderEstimation,
        isActive: p.isActive,
      },
      update: {
        categoryId: p.categoryId,
        name: p.name,
        description: p.description,
        price: p.price,
        stock: p.stock,
        isPreorder: p.isPreorder,
        preorderEstimation: p.preorderEstimation,
        isActive: p.isActive,
      },
    });

    for (const v of p.variants) {
      await prisma.productVariant.upsert({
        where: { id: v.id },
        create: {
          id: v.id,
          productId: p.id,
          variantName: v.variantName,
          additionalPrice: v.additionalPrice,
          stock: v.stock,
        },
        update: {
          variantName: v.variantName,
          additionalPrice: v.additionalPrice,
          stock: v.stock,
        },
      });
    }
  }
  console.log(`Products synced: ${products.length}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
