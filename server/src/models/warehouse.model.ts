import { BaseModel } from '.';

export interface Warehouse {
  warehouseId?: number;
  enterpriseId: number;
  name: string;
  address?: string;
  isActive?: boolean;
  createdAt?: Date;
}

export interface WarehouseZone {
  zoneId?: number;
  warehouseId: number;
  name: string;
  description?: string;
  isActive?: boolean;
}

export interface StorageCell {
  cellId?: number;
  warehouseId: number;
  zoneId?: number;
  cellCode: string;
  description?: string;
  capacity?: number;
  isActive?: boolean;
}

export class WarehouseModel extends BaseModel {
  // РАБОТА СО СКЛАДАМИ

  // Получение склада по ID
  static async getById(warehouseId: number): Promise<Warehouse | null> {
    const sql = `
      SELECT * FROM Warehouses
      WHERE WarehouseId = $1
    `;
    const result = await this.query<Warehouse>(sql, [warehouseId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение складов предприятия
  static async getByEnterpriseId(enterpriseId: number, activeOnly: boolean = true): Promise<Warehouse[]> {
    const sql = `
      SELECT * FROM Warehouses
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query<Warehouse>(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового склада
  static async create(warehouse: Warehouse): Promise<Warehouse> {
    const sql = `
      INSERT INTO Warehouses (
        EnterpriseId, Name, Address, IsActive
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query<Warehouse>(sql, [
      warehouse.enterpriseId,
      warehouse.name,
      warehouse.address || null,
      warehouse.isActive === undefined ? true : warehouse.isActive
    ]);
    return result.rows[0];
  }

  // Обновление склада
  static async update(warehouseId: number, warehouse: Partial<Warehouse>): Promise<Warehouse | null> {
    const fields: string[] = [];
    const values: any[] = [];
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

    const result = await this.query<Warehouse>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация склада
  static async deactivate(warehouseId: number): Promise<boolean> {
    const sql = `
      UPDATE Warehouses
      SET IsActive = FALSE
      WHERE WarehouseId = $1
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // РАБОТА С ЗОНАМИ СКЛАДА

  // Получение зоны по ID
  static async getZoneById(zoneId: number): Promise<WarehouseZone | null> {
    const sql = `
      SELECT * FROM WarehouseZones
      WHERE ZoneId = $1
    `;
    const result = await this.query<WarehouseZone>(sql, [zoneId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех зон склада
  static async getZonesByWarehouseId(warehouseId: number, activeOnly: boolean = true): Promise<WarehouseZone[]> {
    const sql = `
      SELECT * FROM WarehouseZones
      WHERE WarehouseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query<WarehouseZone>(sql, [warehouseId]);
    return result.rows;
  }

  // Создание новой зоны
  static async createZone(zone: WarehouseZone): Promise<WarehouseZone> {
    const sql = `
      INSERT INTO WarehouseZones (
        WarehouseId, Name, Description, IsActive
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    const result = await this.query<WarehouseZone>(sql, [
      zone.warehouseId,
      zone.name,
      zone.description || null,
      zone.isActive === undefined ? true : zone.isActive
    ]);
    return result.rows[0];
  }

  // Обновление зоны
  static async updateZone(zoneId: number, zone: Partial<WarehouseZone>): Promise<WarehouseZone | null> {
    const fields: string[] = [];
    const values: any[] = [];
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

    const result = await this.query<WarehouseZone>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация зоны
  static async deactivateZone(zoneId: number): Promise<boolean> {
    const sql = `
      UPDATE WarehouseZones
      SET IsActive = FALSE
      WHERE ZoneId = $1
    `;
    const result = await this.query(sql, [zoneId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // РАБОТА С ЯЧЕЙКАМИ СКЛАДА

  // Получение ячейки по ID
  static async getCellById(cellId: number): Promise<StorageCell | null> {
    const sql = `
      SELECT * FROM StorageCells
      WHERE CellId = $1
    `;
    const result = await this.query<StorageCell>(sql, [cellId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение ячейки по коду
  static async getCellByCode(warehouseId: number, cellCode: string): Promise<StorageCell | null> {
    const sql = `
      SELECT * FROM StorageCells
      WHERE WarehouseId = $1 AND CellCode = $2
    `;
    const result = await this.query<StorageCell>(sql, [warehouseId, cellCode]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех ячеек склада
  static async getCellsByWarehouseId(warehouseId: number, activeOnly: boolean = true): Promise<StorageCell[]> {
    const sql = `
      SELECT * FROM StorageCells
      WHERE WarehouseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY CellCode
    `;
    const result = await this.query<StorageCell>(sql, [warehouseId]);
    return result.rows;
  }

  // Получение ячеек зоны
  static async getCellsByZoneId(zoneId: number, activeOnly: boolean = true): Promise<StorageCell[]> {
    const sql = `
      SELECT * FROM StorageCells
      WHERE ZoneId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY CellCode
    `;
    const result = await this.query<StorageCell>(sql, [zoneId]);
    return result.rows;
  }

  // Создание новой ячейки
  static async createCell(cell: StorageCell): Promise<StorageCell> {
    const sql = `
      INSERT INTO StorageCells (
        WarehouseId, ZoneId, CellCode, Description, Capacity, IsActive
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING *
    `;
    const result = await this.query<StorageCell>(sql, [
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
  static async updateCell(cellId: number, cell: Partial<StorageCell>): Promise<StorageCell | null> {
    const fields: string[] = [];
    const values: any[] = [];
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

    const result = await this.query<StorageCell>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Деактивация ячейки
  static async deactivateCell(cellId: number): Promise<boolean> {
    const sql = `
      UPDATE StorageCells
      SET IsActive = FALSE
      WHERE CellId = $1
    `;
    const result = await this.query(sql, [cellId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Проверка наличия товаров в ячейке
  static async isCellEmpty(cellId: number): Promise<boolean> {
    const sql = `
      SELECT COUNT(*) as count FROM Inventory
      WHERE CellId = $1 AND Quantity > 0
    `;
    const result = await this.query<{ count: string }>(sql, [cellId]);
    return parseInt(result.rows[0].count) === 0;
  }
} 