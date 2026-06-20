"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CartController = void 0;
const cart_service_1 = require("./cart.service");
const cartService = new cart_service_1.CartService();
class CartController {
    /**
     * Fetches user's cart content.
     */
    async getCart(req, res, next) {
        try {
            const userId = req.user.userId;
            const data = await cartService.getCart(userId);
            return res.status(200).json({
                success: true,
                data,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Adds product to user's cart.
     */
    async addToCart(req, res, next) {
        try {
            const userId = req.user.userId;
            const cartItem = await cartService.addToCart(userId, req.body);
            return res.status(201).json({
                success: true,
                data: cartItem,
                message: 'Item added to cart successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Updates cart item quantity.
     */
    async updateQuantity(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const { quantity } = req.body;
            const cartItem = await cartService.updateQuantity(userId, id, quantity);
            return res.status(200).json({
                success: true,
                data: cartItem,
                message: 'Cart item quantity updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Removes item from user's cart.
     */
    async removeCartItem(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            await cartService.removeCartItem(userId, id);
            return res.status(200).json({
                success: true,
                message: 'Item removed from cart successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Clears entire cart of user.
     */
    async clearCart(req, res, next) {
        try {
            const userId = req.user.userId;
            await cartService.clearCart(userId);
            return res.status(200).json({
                success: true,
                message: 'Cart cleared successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.CartController = CartController;
exports.default = CartController;
