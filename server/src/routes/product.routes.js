/**
 * Маршруты для работы с продуктами
 */
import express from 'express';
import * as productController from '../controllers/product.controller.js';

const router = express.Router();

// Маршруты для продуктов
router.get('/', productController.getProductsByEnterpriseId);
router.get('/sku', productController.getProductBySku);
router.get('/barcode', productController.getProductByBarcode);
router.get('/categories', productController.getProductCategories);
router.get('/brands', productController.getProductBrands);
router.get('/:id', productController.getProductById);
router.post('/', productController.createProduct);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);
router.post('/import', productController.importProducts);

export default router; 