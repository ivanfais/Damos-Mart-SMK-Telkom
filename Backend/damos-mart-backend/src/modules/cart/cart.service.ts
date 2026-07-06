import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';

export class CartService {
  /**
   * Fetches user's cart items, computes subtotals and overall stats.
   */
  async getCart(userId: string) {
    const items = await prisma.cartItem.findMany({
      where: { userId },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            price: true,
            stock: true,
            imageUrl: true,
            isPreorder: true,
            category: {
              select: {
                name: true,
              },
            },
          },
        },
        variant: {
          select: {
            id: true,
            variantName: true,
            additionalPrice: true,
            stock: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    let totalItems = 0;
    let totalPrice = 0;

    const formattedItems = items.map((item) => {
      const productPrice = Number(item.product.price);
      const additionalPrice = item.variant ? Number(item.variant.additionalPrice) : 0;
      const unitPrice = productPrice + additionalPrice;
      const subtotal = unitPrice * item.quantity;

      totalItems += item.quantity;
      totalPrice += subtotal;

      const availableStock = item.variant ? item.variant.stock : item.product.stock;
      const isAvailable = availableStock >= item.quantity;

      return {
        id: item.id,
        productId: item.productId,
        productName: item.product.name,
        categoryName: item.product.category.name,
        imageUrl: item.product.imageUrl,
        isPreorder: item.product.isPreorder,
        variantId: item.variantId,
        variantName: item.variant ? item.variant.variantName : null,
        unitPrice,
        quantity: item.quantity,
        subtotal,
        inStock: isAvailable,
        availableStock,
      };
    });

    return {
      items: formattedItems,
      totalItems,
      totalPrice,
    };
  }

  /**
   * Adds an item to the cart or increments its quantity if it already exists.
   */
  async addToCart(
    userId: string,
    data: { productId: string; variantId?: string | null; quantity: number }
  ) {
    // 1. Verify product exists and is active
    const product = await prisma.product.findUnique({
      where: { id: data.productId },
      include: { variants: true },
    });

    if (!product || !product.isActive) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found or inactive');
    }

    // 2. Verify variant if provided
    let availableStock = product.stock;
    if (data.variantId) {
      const variant = product.variants.find((v) => v.id === data.variantId);
      if (!variant) {
        throw new AppError(404, 'VARIANT_NOT_FOUND', 'Product variant not found');
      }
      availableStock = variant.stock;
    }

    const productId = data.productId;
    const variantId = data.variantId || null;

    // 3. Upsert item
    const existingItem = await prisma.cartItem.findFirst({
      where: {
        userId,
        productId,
        variantId,
      },
    });

    const nextQuantity = (existingItem?.quantity ?? 0) + data.quantity;
    if (nextQuantity > availableStock) {
      throw new AppError(
        400,
        'INSUFFICIENT_STOCK',
        `Stok tidak mencukupi untuk ${product.name}. Stok tersedia: ${availableStock}`
      );
    }

    if (existingItem) {
      return prisma.cartItem.update({
        where: { id: existingItem.id },
        data: {
          quantity: existingItem.quantity + data.quantity,
        },
      });
    }

    return prisma.cartItem.create({
      data: {
        userId,
        productId,
        variantId,
        quantity: data.quantity,
      },
    });
  }

  /**
   * Updates a cart item's quantity.
   */
  async updateQuantity(userId: string, cartItemId: string, quantity: number) {
    const item = await prisma.cartItem.findUnique({
      where: { id: cartItemId },
      include: {
        product: true,
        variant: true,
      },
    });

    if (!item || item.userId !== userId) {
      throw new AppError(404, 'CART_ITEM_NOT_FOUND', 'Cart item not found');
    }

    const availableStock = item.variant ? item.variant.stock : item.product.stock;
    if (quantity > availableStock) {
      throw new AppError(
        400,
        'INSUFFICIENT_STOCK',
        `Stok tidak mencukupi. Stok tersedia: ${availableStock}`
      );
    }

    return prisma.cartItem.update({
      where: { id: cartItemId },
      data: { quantity },
    });
  }

  /**
   * Removes a cart item.
   */
  async removeCartItem(userId: string, cartItemId: string) {
    const item = await prisma.cartItem.findUnique({
      where: { id: cartItemId },
    });

    if (!item || item.userId !== userId) {
      throw new AppError(404, 'CART_ITEM_NOT_FOUND', 'Cart item not found');
    }

    await prisma.cartItem.delete({
      where: { id: cartItemId },
    });
  }

  /**
   * Empties the user's cart completely.
   */
  async clearCart(userId: string) {
    await prisma.cartItem.deleteMany({
      where: { userId },
    });
  }
}
export default CartService;
