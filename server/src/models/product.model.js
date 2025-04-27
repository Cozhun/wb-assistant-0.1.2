import { BaseModel } from './base.model.js';

export class ProductModel extends BaseModel {
  // РАБОТА С КАТЕГОРИЯМИ

  // Получение категории по ID
  static async getCategoryById(categoryId) {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE CategoryId = $1
    `;
    const result = await this.query(sql, [categoryId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех категорий предприятия
  static async getCategoriesByEnterpriseId(enterpriseId) {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE EnterpriseId = $1
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Получение дочерних категорий
  static async getChildCategories(parentCategoryId) {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE ParentCategoryId = $1
      ORDER BY Name
    `;
    const result = await this.query(sql, [parentCategoryId]);
    return result.rows;
  }

  // Получение корневых категорий предприятия
  static async getRootCategories(enterpriseId) {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE EnterpriseId = $1 AND ParentCategoryId IS NULL
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание новой категории
  static async createCategory(category) {
    const sql = `
      INSERT INTO ProductCategories (
        EnterpriseId, Name, ParentCategoryId, Description
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      category.enterpriseId,
      category.name,
      category.parentCategoryId || null,
      category.description || null
    ]);
    return result.rows[0];
  }

  // Обновление категории
  static async updateCategory(categoryId, category) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (category.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(category.name);
    }
    if (category.parentCategoryId !== undefined) {
      fields.push(`ParentCategoryId = $${paramIndex++}`);
      values.push(category.parentCategoryId);
    }
    if (category.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(category.description);
    }

    if (fields.length === 0) {
      return this.getCategoryById(categoryId);
    }

    const sql = `
      UPDATE ProductCategories
      SET ${fields.join(', ')}
      WHERE CategoryId = $${paramIndex}
      RETURNING *
    `;
    values.push(categoryId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление категории
  static async deleteCategory(categoryId) {
    // Проверяем, есть ли в категории товары
    const checkSql = `
      SELECT COUNT(*) as count FROM Products
      WHERE CategoryId = $1
    `;
    const checkResult = await this.query(checkSql, [categoryId]);
    
    if (parseInt(checkResult.rows[0].count) > 0) {
      throw new Error('Невозможно удалить категорию с товарами');
    }

    // Проверяем, есть ли подкатегории
    const checkSubSql = `
      SELECT COUNT(*) as count FROM ProductCategories
      WHERE ParentCategoryId = $1
    `;
    const checkSubResult = await this.query(checkSubSql, [categoryId]);
    
    if (parseInt(checkSubResult.rows[0].count) > 0) {
      throw new Error('Невозможно удалить категорию с подкатегориями');
    }

    const sql = `
      DELETE FROM ProductCategories
      WHERE CategoryId = $1
      RETURNING *
    `;
    const result = await this.query(sql, [categoryId]);
    return result.rowCount > 0;
  }

  // РАБОТА С ТОВАРАМИ

  // Получение товара по ID
  static async getById(productId) {
    const sql = `
      SELECT p.*, c.Name as CategoryName
      FROM Products p
      LEFT JOIN ProductCategories c ON p.CategoryId = c.CategoryId
      WHERE p.ProductId = $1
    `;
    const result = await this.query(sql, [productId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по артикулу WB
  static async getByWbArticle(enterpriseId, wbArticle) {
    const sql = `
      SELECT p.*, c.Name as CategoryName
      FROM Products p
      LEFT JOIN ProductCategories c ON p.CategoryId = c.CategoryId
      WHERE p.EnterpriseId = $1 AND p.WbArticle = $2
    `;
    const result = await this.query(sql, [enterpriseId, wbArticle]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по SKU
  static async getBySku(enterpriseId, sku) {
    const sql = `
      SELECT p.*, c.Name as CategoryName
      FROM Products p
      LEFT JOIN ProductCategories c ON p.CategoryId = c.CategoryId
      WHERE p.EnterpriseId = $1 AND p.SKU = $2
    `;
    const result = await this.query(sql, [enterpriseId, sku]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по штрихкоду
  static async getByBarcode(enterpriseId, barcode) {
    const sql = `
      SELECT p.*, c.Name as CategoryName
      FROM Products p
      LEFT JOIN ProductCategories c ON p.CategoryId = c.CategoryId
      WHERE p.EnterpriseId = $1 AND p.Barcode = $2
    `;
    const result = await this.query(sql, [enterpriseId, barcode]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех товаров предприятия
  static async getByEnterpriseId(enterpriseId = true) {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Получение товаров категории
  static async getByCategoryId(categoryId = true) {
    const sql = `
      SELECT * FROM Products
      WHERE CategoryId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [categoryId]);
    return result.rows;
  }

  // Поиск товаров
  static async search(enterpriseId, searchParams = {}) {
    const { 
      query, 
      categoryId, 
      isActive, 
      sortBy = 'Name', 
      sortDirection = 'ASC',
      limit = 100,
      offset = 0
    } = searchParams;
    
    let conditions = ['p.EnterpriseId = $1'];
    const params = [enterpriseId];
    let paramIndex = 2;
    
    // Поиск по названию, SKU, штрихкоду или артикулу WB
    if (query) {
      conditions.push(`(
        LOWER(p.Name) LIKE LOWER($${paramIndex}) 
        OR LOWER(p.SKU) LIKE LOWER($${paramIndex})
        OR LOWER(p.Barcode) LIKE LOWER($${paramIndex})
        OR LOWER(p.WbArticle) LIKE LOWER($${paramIndex})
      )`);
      params.push(`%${query}%`);
      paramIndex++;
    }
    
    // Фильтрация по категории
    if (categoryId) {
      conditions.push(`p.CategoryId = $${paramIndex}`);
      params.push(categoryId);
      paramIndex++;
    }
    
    // Фильтрация по активности
    if (isActive !== undefined) {
      conditions.push(`p.IsActive = $${paramIndex}`);
      params.push(isActive);
      paramIndex++;
    }
    
    const sql = `
      SELECT 
        p.*,
        c.Name as CategoryName,
        COUNT(*) OVER() as TotalCount
      FROM 
        Products p
        LEFT JOIN ProductCategories c ON p.CategoryId = c.CategoryId
      WHERE 
        ${conditions.join(' AND ')}
      ORDER BY 
        p.${sortBy} ${sortDirection}
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;
    
    params.push(limit, offset);
    
    const result = await this.query(sql, params);
    
    return {
      data: result.rows,
      total: result.rows.length > 0 ? parseInt(result.rows[0].totalcount) : 0,
      limit: limit,
      offset: offset
    };
  }

  // Создание нового товара
  static async create(product) {
    const sql = `
      INSERT INTO Products (
        EnterpriseId, CategoryId, Name, SKU, Barcode, 
        WbArticle, Description, Weight, Width, Height, 
        Length, MinStock, MaxStock, IsActive
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      product.enterpriseId,
      product.categoryId || null,
      product.name,
      product.sku,
      product.barcode || null,
      product.wbArticle || null,
      product.description || null,
      product.weight || null,
      product.width || null,
      product.height || null,
      product.length || null,
      product.minStock || null,
      product.maxStock || null,
      product.isActive === undefined ? true : product.isActive
    ]);
    return result.rows[0];
  }

  // Обновление товара
  static async update(productId, productData) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (productData.categoryId !== undefined) {
      fields.push(`CategoryId = $${paramIndex++}`);
      values.push(productData.categoryId);
    }
    if (productData.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(productData.name);
    }
    if (productData.sku !== undefined) {
      fields.push(`SKU = $${paramIndex++}`);
      values.push(productData.sku);
    }
    if (productData.barcode !== undefined) {
      fields.push(`Barcode = $${paramIndex++}`);
      values.push(productData.barcode);
    }
    if (productData.wbArticle !== undefined) {
      fields.push(`WbArticle = $${paramIndex++}`);
      values.push(productData.wbArticle);
    }
    if (productData.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(productData.description);
    }
    if (productData.weight !== undefined) {
      fields.push(`Weight = $${paramIndex++}`);
      values.push(productData.weight);
    }
    if (productData.width !== undefined) {
      fields.push(`Width = $${paramIndex++}`);
      values.push(productData.width);
    }
    if (productData.height !== undefined) {
      fields.push(`Height = $${paramIndex++}`);
      values.push(productData.height);
    }
    if (productData.length !== undefined) {
      fields.push(`Length = $${paramIndex++}`);
      values.push(productData.length);
    }
    if (productData.minStock !== undefined) {
      fields.push(`MinStock = $${paramIndex++}`);
      values.push(productData.minStock);
    }
    if (productData.maxStock !== undefined) {
      fields.push(`MaxStock = $${paramIndex++}`);
      values.push(productData.maxStock);
    }
    if (productData.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(productData.isActive);
    }

    // Добавляем поле обновления времени
    fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

    if (fields.length === 0) {
      return this.getById(productId);
    }

    const sql = `
      UPDATE Products
      SET ${fields.join(', ')}
      WHERE ProductId = $${paramIndex}
      RETURNING *
    `;
    values.push(productId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация товара
  static async deactivate(productId) {
    const sql = `
      UPDATE Products
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE ProductId = $1
      RETURNING *
    `;
    const result = await this.query(sql, [productId]);
    return result.rowCount > 0;
  }
} 
