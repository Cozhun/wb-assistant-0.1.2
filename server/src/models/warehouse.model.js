import { BaseModel } from './base.model.js';

export class WarehouseModel extends BaseModel {
  // РАБОТА СО СКЛАДАМИ

  // Получение склада по ID
  static async getById(warehouseId) {
    const sql = `
      SELECT * FROM Warehouses
      WHERE WarehouseId = $1
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение складов предприятия
  static async getByEnterpriseId(enterpriseId, onlyActive = true) {
    const sql = `
      SELECT * FROM Warehouses
      WHERE EnterpriseId = $1
      ${onlyActive ? 'AND IsActive = true' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового склада
  static async create(warehouse) {
    const sql = `
      INSERT INTO Warehouses (
        EnterpriseId, Name, Address, IsActive
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      warehouse.enterpriseId,
      warehouse.name,
      warehouse.address || null,
      warehouse.isActive === undefined ? true : warehouse.isActive
    ]);
    return result.rows[0];
  }

  // Обновление склада
  static async update(warehouseId, warehouse) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (warehouse.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(warehouse.name);
    }
    if (warehouse.address !== undefined) {
      fields.push(`Address = $${paramIndex++}`);
      values.push(warehouse.address);
    }
    if (warehouse.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(warehouse.isActive);
    }

    if (fields.length === 0) {
      return this.getById(warehouseId);
    }

    const sql = `
      UPDATE Warehouses
      SET ${fields.join(', ')}
      WHERE WarehouseId = $${paramIndex}
      RETURNING *
    `;
    values.push(warehouseId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация склада
  static async deactivate(warehouseId) {
    const sql = `
      UPDATE Warehouses
      SET IsActive = FALSE
      WHERE WarehouseId = $1
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rowCount > 0;
  }

  // РАБОТА С ЗОНАМИ СКЛАДА

  // Получение зоны по ID
  static async getZoneById(zoneId) {
    const sql = `
      SELECT * FROM WarehouseZones
      WHERE ZoneId = $1
    `;
    const result = await this.query(sql, [zoneId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех зон склада
  static async getZonesByWarehouseId(warehouseId, activeOnly = true) {
    const sql = `
      SELECT * FROM WarehouseZones
      WHERE WarehouseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rows;
  }

  // Создание новой зоны
  static async createZone(zone) {
    const sql = `
      INSERT INTO WarehouseZones (
        WarehouseId, Name, Description, IsActive
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      zone.warehouseId,
      zone.name,
      zone.description || null,
      zone.isActive === undefined ? true : zone.isActive
    ]);
    return result.rows[0];
  }

  // Обновление зоны
  static async updateZone(zoneId, zone) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (zone.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(zone.name);
    }
    if (zone.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(zone.description);
    }
    if (zone.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(zone.isActive);
    }

    if (fields.length === 0) {
      return this.getZoneById(zoneId);
    }

    const sql = `
      UPDATE WarehouseZones
      SET ${fields.join(', ')}
      WHERE ZoneId = $${paramIndex}
      RETURNING *
    `;
    values.push(zoneId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация зоны
  static async deactivateZone(zoneId) {
    const sql = `
      UPDATE WarehouseZones
      SET IsActive = FALSE
      WHERE ZoneId = $1
    `;
    const result = await this.query(sql, [zoneId]);
    return result.rowCount > 0;
  }

  // РАБОТА С ЯЧЕЙКАМИ СКЛАДА

  // Получение ячейки по ID
  static async getCellById(cellId) {
    const sql = `
      SELECT * FROM StorageCells
      WHERE CellId = $1
    `;
    const result = await this.query(sql, [cellId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение ячейки по коду
  static async getCellByCode(warehouseId, cellCode) {
    const sql = `
      SELECT * FROM StorageCells
      WHERE WarehouseId = $1 AND CellCode = $2
    `;
    const result = await this.query(sql, [warehouseId, cellCode]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех ячеек склада
  static async getCellsByWarehouseId(warehouseId, activeOnly = true) {
    const sql = `
      SELECT * FROM StorageCells
      WHERE WarehouseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY CellCode
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rows;
  }

  // Получение ячеек зоны
  static async getCellsByZoneId(zoneId, activeOnly = true) {
    const sql = `
      SELECT * FROM StorageCells
      WHERE ZoneId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY CellCode
    `;
    const result = await this.query(sql, [zoneId]);
    return result.rows;
  }

  // Создание новой ячейки
  static async createCell(cell) {
    const sql = `
      INSERT INTO StorageCells (
        WarehouseId, ZoneId, CellCode, Description, Capacity, IsActive
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      cell.warehouseId,
      cell.zoneId || null,
      cell.cellCode,
      cell.description || null,
      cell.capacity || null,
      cell.isActive === undefined ? true : cell.isActive
    ]);
    return result.rows[0];
  }

  // Обновление ячейки
  static async updateCell(cellId, cell) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (cell.zoneId !== undefined) {
      fields.push(`ZoneId = $${paramIndex++}`);
      values.push(cell.zoneId);
    }
    if (cell.cellCode !== undefined) {
      fields.push(`CellCode = $${paramIndex++}`);
      values.push(cell.cellCode);
    }
    if (cell.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(cell.description);
    }
    if (cell.capacity !== undefined) {
      fields.push(`Capacity = $${paramIndex++}`);
      values.push(cell.capacity);
    }
    if (cell.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(cell.isActive);
    }

    if (fields.length === 0) {
      return this.getCellById(cellId);
    }

    const sql = `
      UPDATE StorageCells
      SET ${fields.join(', ')}
      WHERE CellId = $${paramIndex}
      RETURNING *
    `;
    values.push(cellId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация ячейки
  static async deactivateCell(cellId) {
    const sql = `
      UPDATE StorageCells
      SET IsActive = FALSE
      WHERE CellId = $1
    `;
    const result = await this.query(sql, [cellId]);
    return result.rowCount > 0;
  }

  // Проверка наличия товаров в ячейке
  static async isCellEmpty(cellId) {
    const sql = `
      SELECT COUNT(*) as count FROM Inventory
      WHERE CellId = $1 AND Quantity > 0
    `;
    const result = await this.query(sql, [cellId]);
    return parseInt(result.rows[0].count) === 0;
  }
} 
