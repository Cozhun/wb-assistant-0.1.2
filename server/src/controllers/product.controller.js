/**
 * Контроллер для управления продуктами
 */
import { ProductModel } from '../models/product.model.js';
import logger from '../utils/logger.js';

/**
 * Получить продукты по ID предприятия
 */
export const getProductsByEnterpriseId = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      search, 
      categoryId, 
      page = 1, 
      limit = 20, 
      sortBy = 'name', 
      sortOrder = 'ASC' 
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const filters = {
      search,
      categoryId: categoryId ? Number(categoryId) : undefined
    };
    
    const pagination = {
      page: Number(page),
      limit: Number(limit)
    };
    
    const sorting = {
      sortBy,
      sortOrder
    };
    
    const result = await ProductModel.getProductsByEnterpriseId(
      enterpriseId,
      filters,
      pagination,
      sorting
    );
    
    return res.json({
      data: result.products,
      total: result.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(result.total / pagination.limit)
    });
  } catch (error) {
    logger.error('Ошибка при получении продуктов предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить продукт по ID
 */
export const getProductById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID продукта обязателен' });
    }
    
    const product = await ProductModel.getProductById(id);
    
    if (!product) {
      return res.status(404).json({ error: 'Продукт не найден' });
    }
    
    return res.json(product);
  } catch (error) {
    logger.error(`Ошибка при получении продукта с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить продукт по артикулу
 */
export const getProductBySku = async (req, res) => {
  try {
    const { enterpriseId, sku } = req.query;
    
    if (!enterpriseId || !sku) {
      return res.status(400).json({ error: 'ID предприятия и артикул продукта обязательны' });
    }
    
    const product = await ProductModel.getProductBySku(enterpriseId, sku);
    
    if (!product) {
      return res.status(404).json({ error: 'Продукт не найден' });
    }
    
    return res.json(product);
  } catch (error) {
    logger.error('Ошибка при получении продукта по артикулу:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить продукт по штрихкоду
 */
export const getProductByBarcode = async (req, res) => {
  try {
    const { enterpriseId, barcode } = req.query;
    
    if (!enterpriseId || !barcode) {
      return res.status(400).json({ error: 'ID предприятия и штрихкод продукта обязательны' });
    }
    
    const product = await ProductModel.getProductByBarcode(enterpriseId, barcode);
    
    if (!product) {
      return res.status(404).json({ error: 'Продукт не найден' });
    }
    
    return res.json(product);
  } catch (error) {
    logger.error('Ошибка при получении продукта по штрихкоду:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новый продукт
 */
export const createProduct = async (req, res) => {
  try {
    const {
      enterpriseId,
      name,
      sku,
      barcode,
      description,
      categoryId,
      brandId,
      price,
      weight,
      dimensions,
      attributes,
      images
    } = req.body;
    
    if (!enterpriseId || !name || !sku) {
      return res.status(400).json({ 
        error: 'ID предприятия, название и артикул продукта обязательны' 
      });
    }
    
    // Проверка на существование продукта с таким же артикулом
    const existingProductBySku = await ProductModel.getProductBySku(enterpriseId, sku);
    if (existingProductBySku) {
      return res.status(400).json({ 
        error: 'Продукт с таким артикулом уже существует' 
      });
    }
    
    // Проверка на существование продукта с таким же штрихкодом
    if (barcode) {
      const existingProductByBarcode = await ProductModel.getProductByBarcode(enterpriseId, barcode);
      if (existingProductByBarcode) {
        return res.status(400).json({ 
          error: 'Продукт с таким штрихкодом уже существует' 
        });
      }
    }
    
    const newProduct = await ProductModel.createProduct({
      enterpriseId,
      name,
      sku,
      barcode,
      description,
      categoryId,
      brandId,
      price,
      weight,
      dimensions,
      attributes,
      images
    });
    
    return res.status(201).json(newProduct);
  } catch (error) {
    logger.error('Ошибка при создании продукта:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить продукт
 */
export const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      sku,
      barcode,
      description,
      categoryId,
      brandId,
      price,
      weight,
      dimensions,
      attributes,
      images
    } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID продукта обязателен' });
    }
    
    // Проверка существования продукта
    const existingProduct = await ProductModel.getProductById(id);
    if (!existingProduct) {
      return res.status(404).json({ error: 'Продукт не найден' });
    }
    
    // Проверка на существование другого продукта с таким же артикулом
    if (sku && sku !== existingProduct.sku) {
      const duplicateProductBySku = await ProductModel.getProductBySku(
        existingProduct.enterpriseId, 
        sku
      );
      
      if (duplicateProductBySku && duplicateProductBySku.productId !== Number(id)) {
        return res.status(400).json({ 
          error: 'Продукт с таким артикулом уже существует' 
        });
      }
    }
    
    // Проверка на существование другого продукта с таким же штрихкодом
    if (barcode && barcode !== existingProduct.barcode) {
      const duplicateProductByBarcode = await ProductModel.getProductByBarcode(
        existingProduct.enterpriseId, 
        barcode
      );
      
      if (duplicateProductByBarcode && duplicateProductByBarcode.productId !== Number(id)) {
        return res.status(400).json({ 
          error: 'Продукт с таким штрихкодом уже существует' 
        });
      }
    }
    
    const updatedProduct = await ProductModel.updateProduct(id, {
      name,
      sku,
      barcode,
      description,
      categoryId,
      brandId,
      price,
      weight,
      dimensions,
      attributes,
      images
    });
    
    return res.json(updatedProduct);
  } catch (error) {
    logger.error(`Ошибка при обновлении продукта с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить продукт
 */
export const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID продукта обязателен' });
    }
    
    // Проверка существования продукта
    const existingProduct = await ProductModel.getProductById(id);
    if (!existingProduct) {
      return res.status(404).json({ error: 'Продукт не найден' });
    }
    
    await ProductModel.deleteProduct(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении продукта с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить категории продуктов
 */
export const getProductCategories = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const categories = await ProductModel.getProductCategories(enterpriseId);
    return res.json(categories);
  } catch (error) {
    logger.error('Ошибка при получении категорий продуктов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить бренды продуктов
 */
export const getProductBrands = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const brands = await ProductModel.getProductBrands(enterpriseId);
    return res.json(brands);
  } catch (error) {
    logger.error('Ошибка при получении брендов продуктов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Импортировать продукты из файла
 */
export const importProducts = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    const { products, updateExisting = false } = req.body;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!Array.isArray(products) || products.length === 0) {
      return res.status(400).json({ 
        error: 'Массив продуктов обязателен и не может быть пустым' 
      });
    }
    
    const result = await ProductModel.importProducts(
      enterpriseId, 
      products, 
      updateExisting
    );
    
    return res.status(201).json({
      success: true,
      created: result.created,
      updated: result.updated,
      errors: result.errors
    });
  } catch (error) {
    logger.error('Ошибка при импорте продуктов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 