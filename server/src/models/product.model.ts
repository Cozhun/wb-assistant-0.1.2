import { BaseModel } from '.';

export interface ProductCategory {
  categoryId?: number;
  enterpriseId: number;
  name: string;
  parentCategoryId?: number;
  description?: string;
}

export interface Product {
  productId?: number;
  enterpriseId: number;
  categoryId?: number;
  name: string;
  sku: string;
  barcode?: string;
  wbArticle?: string;
  description?: string;
  weight?: number;
  width?: number;
  height?: number;
  length?: number;
  minStock?: number;
  maxStock?: number;
  isActive?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

interface CountResult {
  count: string;
}

export class ProductModel extends BaseModel {
  // РАБОТА С КАТЕГОРИЯМИ

  // Получение категории по ID
  static async getCategoryById(categoryId: number): Promise<ProductCategory | null> {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE CategoryId = $1
    `;
    const result = await this.query<ProductCategory>(sql, [categoryId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех категорий предприятия
  static async getCategoriesByEnterpriseId(enterpriseId: number): Promise<ProductCategory[]> {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE EnterpriseId = $1
      ORDER BY Name
    `;
    const result = await this.query<ProductCategory>(sql, [enterpriseId]);
    return result.rows;
  }

  // Получение дочерних категорий
  static async getChildCategories(parentCategoryId: number): Promise<ProductCategory[]> {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE ParentCategoryId = $1
      ORDER BY Name
    `;
    const result = await this.query<ProductCategory>(sql, [parentCategoryId]);
    return result.rows;
  }

  // Получение корневых категорий предприятия
  static async getRootCategories(enterpriseId: number): Promise<ProductCategory[]> {
    const sql = `
      SELECT * FROM ProductCategories
      WHERE EnterpriseId = $1 AND ParentCategoryId IS NULL
      ORDER BY Name
    `;
    const result = await this.query<ProductCategory>(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание новой категории
  static async createCategory(category: ProductCategory): Promise<ProductCategory> {
    const sql = `
      INSERT INTO ProductCategories (
        EnterpriseId, Name, ParentCategoryId, Description
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query<ProductCategory>(sql, [
      category.enterpriseId,
      category.name,
      category.parentCategoryId || null,
      category.description || null
    ]);
    return result.rows[0];
  }

  // Обновление категории
  static async updateCategory(categoryId: number, category: Partial<ProductCategory>): Promise<ProductCategory | null> {
    const fields: string[] = [];
    const values: any[] = [];
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

    const result = await this.query<ProductCategory>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление категории
  static async deleteCategory(categoryId: number): Promise<boolean> {
    // Проверяем, есть ли товары в этой категории
    const productsCheck = await this.query<CountResult>(`
      SELECT COUNT(*) as count FROM Products
      WHERE CategoryId = $1
    `, [categoryId]);
    
    if (parseInt(productsCheck.rows[0].count) > 0) {
      return false; // Нельзя удалить категорию с товарами
    }

    // Проверяем, есть ли подкатегории
    const categoriesCheck = await this.query<CountResult>(`
      SELECT COUNT(*) as count FROM ProductCategories
      WHERE ParentCategoryId = $1
    `, [categoryId]);
    
    if (parseInt(categoriesCheck.rows[0].count) > 0) {
      return false; // Нельзя удалить категорию с подкатегориями
    }

    // Удаляем категорию
    const sql = `
      DELETE FROM ProductCategories
      WHERE CategoryId = $1
    `;
    const result = await this.query(sql, [categoryId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // РАБОТА С ТОВАРАМИ

  // Получение товара по ID
  static async getById(productId: number): Promise<Product | null> {
    const sql = `
      SELECT * FROM Products
      WHERE ProductId = $1
    `;
    const result = await this.query<Product>(sql, [productId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по SKU
  static async getBySku(enterpriseId: number, sku: string): Promise<Product | null> {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1 AND SKU = $2
    `;
    const result = await this.query<Product>(sql, [enterpriseId, sku]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по штрихкоду
  static async getByBarcode(enterpriseId: number, barcode: string): Promise<Product | null> {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1 AND Barcode = $2
    `;
    const result = await this.query<Product>(sql, [enterpriseId, barcode]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение товара по артикулу Wildberries
  static async getByWbArticle(enterpriseId: number, wbArticle: string): Promise<Product | null> {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1 AND WbArticle = $2
    `;
    const result = await this.query<Product>(sql, [enterpriseId, wbArticle]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех товаров предприятия
  static async getByEnterpriseId(enterpriseId: number, activeOnly: boolean = true): Promise<Product[]> {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query<Product>(sql, [enterpriseId]);
    return result.rows;
  }

  // Получение товаров категории
  static async getByCategoryId(categoryId: number, activeOnly: boolean = true): Promise<Product[]> {
    const sql = `
      SELECT * FROM Products
      WHERE CategoryId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query<Product>(sql, [categoryId]);
    return result.rows;
  }

  // Поиск товаров по имени или SKU
  static async search(enterpriseId: number, searchTerm: string, activeOnly: boolean = true): Promise<Product[]> {
    const sql = `
      SELECT * FROM Products
      WHERE EnterpriseId = $1
      AND (
        Name ILIKE $2
        OR SKU ILIKE $2
        OR Barcode ILIKE $2
        OR WbArticle ILIKE $2
      )
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
      LIMIT 100
    `;
    const result = await this.query<Product>(sql, [enterpriseId, `%${searchTerm}%`]);
    return result.rows;
  }

  // Создание нового товара
  static async create(product: Product): Promise<Product> {
    const sql = `
      INSERT INTO Products (
        EnterpriseId, CategoryId, Name, SKU, Barcode, WbArticle,
        Description, Weight, Width, Height, Length,
        MinStock, MaxStock, IsActive
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
      ) RETURNING *
    `;
    const result = await this.query<Product>(sql, [
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
      product.minStock || 0,
      product.maxStock || null,
      product.isActive === undefined ? true : product.isActive
    ]);
    return result.rows[0];
  }

  // Обновление товара
  static async update(productId: number, product: Partial<Product>): Promise<Product | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (product.categoryId !== undefined) {
      fields.push(`CategoryId = $${paramIndex++}`);
      values.push(product.categoryId);
    }
    if (product.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(product.name);
    }
    if (product.sku !== undefined) {
      fields.push(`SKU = $${paramIndex++}`);
      values.push(product.sku);
    }
    if (product.barcode !== undefined) {
      fields.push(`Barcode = $${paramIndex++}`);
      values.push(product.barcode);
    }
    if (product.wbArticle !== undefined) {
      fields.push(`WbArticle = $${paramIndex++}`);
      values.push(product.wbArticle);
    }
    if (product.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(product.description);
    }
    if (product.weight !== undefined) {
      fields.push(`Weight = $${paramIndex++}`);
      values.push(product.weight);
    }
    if (product.width !== undefined) {
      fields.push(`Width = $${paramIndex++}`);
      values.push(product.width);
    }
    if (product.height !== undefined) {
      fields.push(`Height = $${paramIndex++}`);
      values.push(product.height);
    }
    if (product.length !== undefined) {
      fields.push(`Length = $${paramIndex++}`);
      values.push(product.length);
    }
    if (product.minStock !== undefined) {
      fields.push(`MinStock = $${paramIndex++}`);
      values.push(product.minStock);
    }
    if (product.maxStock !== undefined) {
      fields.push(`MaxStock = $${paramIndex++}`);
      values.push(product.maxStock);
    }
    if (product.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(product.isActive);
    }

    // Добавляем обновление времени
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

    const result = await this.query<Product>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация товара
  static async deactivate(productId: number): Promise<boolean> {
    const sql = `
      UPDATE Products
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE ProductId = $1
    `;
    const result = await this.query(sql, [productId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }
} 