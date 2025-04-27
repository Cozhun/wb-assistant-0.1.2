import { BaseModel } from './base.model.js';
import pkg from 'pg';
const { Pool, QueryResult } = pkg;

export class InventoryModel extends BaseModel {
  // Получение текущих запасов товара по его ID
  static async getInventoryByProductId(productId) {
    const sql = `
      SELECT * FROM InventoryRecords
      WHERE ProductId = $1
    `;
    const result = await this.query(sql, [productId]);
    return result.rows;
  }

  // Получение суммарной информации о запасах товара
  static async getProductInventorySummary(productId) {
    const sql = `
      SELECT 
        p.ProductId,
        p.Name AS ProductName,
        p.SKU,
        p.Barcode,
        p.WbArticle,
        SUM(ir.Quantity) AS TotalQuantity,
        SUM(ir.ReservedQuantity) AS ReservedQuantity,
        SUM(ir.Quantity - ir.ReservedQuantity) AS AvailableQuantity,
        json_agg(
          json_build_object(
            'warehouseId', w.WarehouseId,
            'warehouseName', w.Name,
            'quantity', ir.Quantity,
            'reservedQuantity', ir.ReservedQuantity
          )
        ) AS WarehouseDetails
      FROM 
        Products p
        LEFT JOIN InventoryRecords ir ON p.ProductId = ir.ProductId
        LEFT JOIN Warehouses w ON ir.WarehouseId = w.WarehouseId
      WHERE 
        p.ProductId = $1
      GROUP BY
        p.ProductId, p.Name, p.SKU, p.Barcode, p.WbArticle
    `;
    
    const result = await this.query(sql, [productId]);
    if (!result.rows.length) return null;
    
    // Преобразуем результат в нужный формат
    const row = result.rows[0];
    return {
      productId: row.productid,
      productName: row.productname,
      sku: row.sku,
      barcode: row.barcode,
      wbArticle: row.wbarticle,
      totalQuantity: parseInt(row.totalquantity) || 0,
      reservedQuantity: parseInt(row.reservedquantity) || 0,
      availableQuantity: parseInt(row.availablequantity) || 0,
      warehouseDetails: row.warehousedetails || []
    };
  }

  // Получение запасов товаров на конкретном складе
  static async getInventoryByWarehouseId(warehouseId) {
    const sql = `
      SELECT * FROM InventoryRecords
      WHERE WarehouseId = $1
    `;
    const result = await this.query(sql, [warehouseId]);
    return result.rows;
  }

  // Получение запасов товаров в конкретной зоне склада
  static async getInventoryByZoneId(warehouseId, zoneId) {
    const sql = `
      SELECT * FROM InventoryRecords
      WHERE WarehouseId = $1 AND ZoneId = $2
    `;
    const result = await this.query(sql, [warehouseId, zoneId]);
    return result.rows;
  }

  // Получение запасов товаров в конкретной ячейке склада
  static async getInventoryByCellId(warehouseId, cellId) {
    const sql = `
      SELECT * FROM InventoryRecords
      WHERE WarehouseId = $1 AND CellId = $2
    `;
    const result = await this.query(sql, [warehouseId, cellId]);
    return result.rows;
  }

  // Получение товаров с низким запасом
  static async getLowStockProducts(enterpriseId) {
    const sql = `
      SELECT 
        p.ProductId,
        p.Name,
        p.SKU,
        p.MinStock,
        SUM(ir.Quantity) AS TotalQuantity,
        SUM(ir.ReservedQuantity) AS ReservedQuantity,
        SUM(ir.Quantity - ir.ReservedQuantity) AS AvailableQuantity
      FROM 
        Products p
        LEFT JOIN InventoryRecords ir ON p.ProductId = ir.ProductId
      WHERE 
        p.EnterpriseId = $1
        AND p.IsActive = TRUE
        AND p.MinStock IS NOT NULL
      GROUP BY
        p.ProductId, p.Name, p.SKU, p.MinStock
      HAVING 
        SUM(ir.Quantity - ir.ReservedQuantity) < p.MinStock
      ORDER BY
        (p.MinStock - SUM(ir.Quantity - ir.ReservedQuantity)) DESC
    `;
    
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Добавление товара на склад
  static async addStock(productId, warehouseId, quantity, zoneId, cellId, userId = 0, referenceId, comments) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем существующую запись инвентаризации
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (zoneId) checkParams.push(zoneId);
      if (cellId) checkParams.push(cellId);
      
      const existingRecord = await client.query(checkSql, checkParams);
      
      if (existingRecord.rows.length > 0) {
        // Обновляем существующую запись
        const updateSql = `
          UPDATE InventoryRecords
          SET Quantity = Quantity + $1, UpdatedAt = CURRENT_TIMESTAMP
          WHERE ProductId = $2 AND WarehouseId = $3
          ${zoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
          ${cellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
        `;
        
        const updateParams = [quantity, productId, warehouseId];
        if (zoneId) updateParams.push(zoneId);
        if (cellId) updateParams.push(cellId);
        
        await client.query(updateSql, updateParams);
      } else {
        // Создаем новую запись
        const insertSql = `
          INSERT INTO InventoryRecords (
            ProductId, WarehouseId, ZoneId, CellId, Quantity, ReservedQuantity
          ) VALUES (
            $1, $2, $3, $4, $5, 0
          )
        `;
        
        await client.query(insertSql, [
          productId, 
          warehouseId, 
          zoneId || null, 
          cellId || null, 
          quantity
        ]);
      }
      
      // Получаем информацию о предприятии
      const productSql = `
        SELECT EnterpriseId FROM Products WHERE ProductId = $1
      `;
      const productResult = await client.query(productSql, [productId]);
      const enterpriseId = productResult.rows[0]?.enterpriseid;
      
      // Записываем движение инвентаря
      const movementSql = `
        INSERT INTO InventoryMovements (
          EnterpriseId, ProductId, WarehouseId, 
          DestinationZoneId, DestinationCellId,
          Quantity, MovementType, ReferenceId, 
          Comments, CreatedBy
        ) VALUES (
          $1, $2, $3, $4, $5, $6, 'RECEIPT', $7, $8, $9
        )
      `;
      
      await client.query(movementSql, [
        enterpriseId,
        productId,
        warehouseId,
        zoneId || null,
        cellId || null,
        quantity,
        referenceId || null,
        comments || 'Поступление товара',
        userId
      ]);
      
      return true;
    });
  }

  // Перемещение товара между зонами/ячейками склада
  static async transferStock(
    productId,
    warehouseId,
    quantity,
    sourceZoneId,
    sourceCellId,
    destinationZoneId,
    destinationCellId,
    userId = 0,
    referenceId,
    comments
  ) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем наличие достаточного количества товара в исходном месте
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${sourceZoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${sourceCellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (sourceZoneId) checkParams.push(sourceZoneId);
      if (sourceCellId) checkParams.push(sourceCellId);
      
      const sourceRecord = await client.query(checkSql, checkParams);
      
      if (sourceRecord.rows.length === 0 || 
          sourceRecord.rows[0].quantity < quantity || 
          sourceRecord.rows[0].quantity - sourceRecord.rows[0].reservedquantity < quantity) {
        throw new Error('Недостаточно товара для перемещения');
      }
      
      // Уменьшаем количество в исходном месте
      const updateSourceSql = `
        UPDATE InventoryRecords
        SET Quantity = Quantity - $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE ProductId = $2 AND WarehouseId = $3
        ${sourceZoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
        ${sourceCellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
      `;
      
      const updateSourceParams = [quantity, productId, warehouseId];
      if (sourceZoneId) updateSourceParams.push(sourceZoneId);
      if (sourceCellId) updateSourceParams.push(sourceCellId);
      
      await client.query(updateSourceSql, updateSourceParams);
      
      // Проверяем существующую запись в целевом месте
      const checkDestSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${destinationZoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${destinationCellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkDestParams = [productId, warehouseId];
      if (destinationZoneId) checkDestParams.push(destinationZoneId);
      if (destinationCellId) checkDestParams.push(destinationCellId);
      
      const destRecord = await client.query(checkDestSql, checkDestParams);
      
      if (destRecord.rows.length > 0) {
        // Обновляем существующую запись в целевом месте
        const updateDestSql = `
          UPDATE InventoryRecords
          SET Quantity = Quantity + $1, UpdatedAt = CURRENT_TIMESTAMP
          WHERE ProductId = $2 AND WarehouseId = $3
          ${destinationZoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
          ${destinationCellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
        `;
        
        const updateDestParams = [quantity, productId, warehouseId];
        if (destinationZoneId) updateDestParams.push(destinationZoneId);
        if (destinationCellId) updateDestParams.push(destinationCellId);
        
        await client.query(updateDestSql, updateDestParams);
      } else {
        // Создаем новую запись в целевом месте
        const insertDestSql = `
          INSERT INTO InventoryRecords (
            ProductId, WarehouseId, ZoneId, CellId, Quantity, ReservedQuantity
          ) VALUES (
            $1, $2, $3, $4, $5, 0
          )
        `;
        
        await client.query(insertDestSql, [
          productId, 
          warehouseId, 
          destinationZoneId || null, 
          destinationCellId || null, 
          quantity
        ]);
      }
      
      // Получаем информацию о предприятии
      const productSql = `
        SELECT EnterpriseId FROM Products WHERE ProductId = $1
      `;
      const productResult = await client.query(productSql, [productId]);
      const enterpriseId = productResult.rows[0]?.enterpriseid;
      
      // Записываем движение инвентаря
      const movementSql = `
        INSERT INTO InventoryMovements (
          EnterpriseId, ProductId, WarehouseId, 
          SourceZoneId, SourceCellId,
          DestinationZoneId, DestinationCellId,
          Quantity, MovementType, ReferenceId, 
          Comments, CreatedBy
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, 'TRANSFER', $9, $10, $11
        )
      `;
      
      await client.query(movementSql, [
        enterpriseId,
        productId,
        warehouseId,
        sourceZoneId || null,
        sourceCellId || null,
        destinationZoneId || null,
        destinationCellId || null,
        quantity,
        referenceId || null,
        comments || 'Перемещение товара',
        userId
      ]);
      
      // Удаляем записи с нулевым количеством
      await client.query(`
        DELETE FROM InventoryRecords
        WHERE Quantity = 0 AND ReservedQuantity = 0
      `);
      
      return true;
    });
  }

  // Списание товара со склада
  static async removeStock(productId, warehouseId, quantity, zoneId, cellId, userId = 0, referenceId, comments) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем наличие достаточного количества товара
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (zoneId) checkParams.push(zoneId);
      if (cellId) checkParams.push(cellId);
      
      const existingRecord = await client.query(checkSql, checkParams);
      
      if (existingRecord.rows.length === 0 || 
          existingRecord.rows[0].quantity < quantity || 
          existingRecord.rows[0].quantity - existingRecord.rows[0].reservedquantity < quantity) {
        throw new Error('Недостаточно товара для списания');
      }
      
      // Обновляем количество
      const updateSql = `
        UPDATE InventoryRecords
        SET Quantity = Quantity - $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE ProductId = $2 AND WarehouseId = $3
        ${zoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
      `;
      
      const updateParams = [quantity, productId, warehouseId];
      if (zoneId) updateParams.push(zoneId);
      if (cellId) updateParams.push(cellId);
      
      await client.query(updateSql, updateParams);
      
      // Получаем информацию о предприятии
      const productSql = `
        SELECT EnterpriseId FROM Products WHERE ProductId = $1
      `;
      const productResult = await client.query(productSql, [productId]);
      const enterpriseId = productResult.rows[0]?.enterpriseid;
      
      // Записываем движение инвентаря
      const movementSql = `
        INSERT INTO InventoryMovements (
          EnterpriseId, ProductId, WarehouseId, 
          SourceZoneId, SourceCellId,
          Quantity, MovementType, ReferenceId, 
          Comments, CreatedBy
        ) VALUES (
          $1, $2, $3, $4, $5, $6, 'ISSUE', $7, $8, $9
        )
      `;
      
      await client.query(movementSql, [
        enterpriseId,
        productId,
        warehouseId,
        zoneId || null,
        cellId || null,
        quantity,
        referenceId || null,
        comments || 'Списание товара',
        userId
      ]);
      
      // Удаляем записи с нулевым количеством
      await client.query(`
        DELETE FROM InventoryRecords
        WHERE Quantity = 0 AND ReservedQuantity = 0
      `);
      
      return true;
    });
  }

  // Резервирование товара
  static async reserveStock(productId, warehouseId, quantity, zoneId, cellId, userId = 0, referenceId, comments) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем наличие достаточного количества товара
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (zoneId) checkParams.push(zoneId);
      if (cellId) checkParams.push(cellId);
      
      const existingRecord = await client.query(checkSql, checkParams);
      
      if (existingRecord.rows.length === 0 || 
          existingRecord.rows[0].quantity - existingRecord.rows[0].reservedquantity < quantity) {
        throw new Error('Недостаточно товара для резервирования');
      }
      
      // Обновляем зарезервированное количество
      const updateSql = `
        UPDATE InventoryRecords
        SET ReservedQuantity = ReservedQuantity + $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE ProductId = $2 AND WarehouseId = $3
        ${zoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
      `;
      
      const updateParams = [quantity, productId, warehouseId];
      if (zoneId) updateParams.push(zoneId);
      if (cellId) updateParams.push(cellId);
      
      await client.query(updateSql, updateParams);
      
      return true;
    });
  }

  // Отмена резервирования товара
  static async unreserveStock(productId, warehouseId, quantity, zoneId, cellId) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем наличие зарезервированного количества
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (zoneId) checkParams.push(zoneId);
      if (cellId) checkParams.push(cellId);
      
      const existingRecord = await client.query(checkSql, checkParams);
      
      if (existingRecord.rows.length === 0 || 
          existingRecord.rows[0].reservedquantity < quantity) {
        throw new Error('Недостаточно зарезервированного товара для отмены резервирования');
      }
      
      // Обновляем зарезервированное количество
      const updateSql = `
        UPDATE InventoryRecords
        SET ReservedQuantity = ReservedQuantity - $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE ProductId = $2 AND WarehouseId = $3
        ${zoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
      `;
      
      const updateParams = [quantity, productId, warehouseId];
      if (zoneId) updateParams.push(zoneId);
      if (cellId) updateParams.push(cellId);
      
      await client.query(updateSql, updateParams);
      
      return true;
    });
  }

  // Получение истории движений товара
  static async getProductMovementHistory(productId, startDate, endDate, limit = 50, offset = 0) {
    const params = [productId];
    let dateCondition = '';
    let paramIndex = 2;
    
    if (startDate) {
      dateCondition += ` AND CreatedAt >= $${paramIndex++}`;
      params.push(startDate);
    }
    
    if (endDate) {
      dateCondition += ` AND CreatedAt <= $${paramIndex++}`;
      params.push(endDate);
    }
    
    const sql = `
      SELECT * FROM InventoryMovements
      WHERE ProductId = $1
      ${dateCondition}
      ORDER BY CreatedAt DESC
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;
    
    params.push(limit, offset);
    
    const result = await this.query(sql, params);
    return result.rows;
  }

  // Проведение инвентаризации (корректировка количества)
  static async adjustInventory(productId, warehouseId, newQuantity, zoneId, cellId, userId = 0, comments) {
    // Начинаем транзакцию
    return this.transaction(async (client) => {
      // Проверяем существующую запись
      const checkSql = `
        SELECT * FROM InventoryRecords
        WHERE ProductId = $1 AND WarehouseId = $2
        ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
        ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
      `;
      
      const checkParams = [productId, warehouseId];
      if (zoneId) checkParams.push(zoneId);
      if (cellId) checkParams.push(cellId);
      
      const existingRecord = await client.query(checkSql, checkParams);
      let adjustmentQuantity = newQuantity;
      let adjustmentType = 'ADJUSTMENT';
      
      if (existingRecord.rows.length > 0) {
        const currentQuantity = existingRecord.rows[0].quantity;
        adjustmentQuantity = newQuantity - currentQuantity;
        
        // Обновляем запись
        const updateSql = `
          UPDATE InventoryRecords
          SET Quantity = $1, UpdatedAt = CURRENT_TIMESTAMP
          WHERE ProductId = $2 AND WarehouseId = $3
          ${zoneId ? 'AND ZoneId = $4' : 'AND ZoneId IS NULL'}
          ${cellId ? 'AND CellId = $5' : 'AND CellId IS NULL'}
        `;
        
        const updateParams = [newQuantity, productId, warehouseId];
        if (zoneId) updateParams.push(zoneId);
        if (cellId) updateParams.push(cellId);
        
        await client.query(updateSql, updateParams);
      } else if (newQuantity > 0) {
        // Создаем новую запись
        const insertSql = `
          INSERT INTO InventoryRecords (
            ProductId, WarehouseId, ZoneId, CellId, Quantity, ReservedQuantity
          ) VALUES (
            $1, $2, $3, $4, $5, 0
          )
        `;
        
        await client.query(insertSql, [
          productId, 
          warehouseId, 
          zoneId || null, 
          cellId || null, 
          newQuantity
        ]);
      }
      
      if (adjustmentQuantity !== 0) {
        // Получаем информацию о предприятии
        const productSql = `
          SELECT EnterpriseId FROM Products WHERE ProductId = $1
        `;
        const productResult = await client.query(productSql, [productId]);
        const enterpriseId = productResult.rows[0]?.enterpriseid;
        
        // Записываем движение инвентаря
        const movementSql = `
          INSERT INTO InventoryMovements (
            EnterpriseId, ProductId, WarehouseId, 
            DestinationZoneId, DestinationCellId,
            Quantity, MovementType, 
            Comments, CreatedBy
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9
          )
        `;
        
        await client.query(movementSql, [
          enterpriseId,
          productId,
          warehouseId,
          zoneId || null,
          cellId || null,
          Math.abs(adjustmentQuantity),
          adjustmentType,
          comments || 'Корректировка инвентаря',
          userId
        ]);
      }
      
      // Удаляем записи с нулевым количеством
      if (newQuantity === 0) {
        const deleteSql = `
          DELETE FROM InventoryRecords
          WHERE ProductId = $1 AND WarehouseId = $2
          ${zoneId ? 'AND ZoneId = $3' : 'AND ZoneId IS NULL'}
          ${cellId ? 'AND CellId = $4' : 'AND CellId IS NULL'}
          AND ReservedQuantity = 0
        `;
        
        const deleteParams = [productId, warehouseId];
        if (zoneId) deleteParams.push(zoneId);
        if (cellId) deleteParams.push(cellId);
        
        await client.query(deleteSql, deleteParams);
      }
      
      return true;
    });
  }
} 
