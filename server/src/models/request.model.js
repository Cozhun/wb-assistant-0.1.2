import { BaseModel } from './base.model.js';

export class RequestModel extends BaseModel {
  // Получение всех заявок предприятия
  static async getAllByEnterpriseId(enterpriseId, searchParams = {}) {
    const { 
      search, 
      status, 
      type, 
      dateFrom, 
      dateTo, 
      sortBy = 'CreatedAt', 
      sortDirection = 'DESC',
      limit = 100,
      offset = 0
    } = searchParams;
    
    let conditions = ['EnterpriseId = $1'];
    const params = [enterpriseId];
    let paramIndex = 2;
    
    // Фильтрация по поисковой строке
    if (search) {
      conditions.push(`(
        CAST(RequestId AS TEXT) LIKE $${paramIndex} 
        OR LOWER(RequestName) LIKE LOWER($${paramIndex})
      )`);
      params.push(`%${search}%`);
      paramIndex++;
    }
    
    // Фильтрация по статусу
    if (status && status !== 'ALL') {
      conditions.push(`Status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }
    
    // Фильтрация по типу заявки
    if (type && type !== 'ALL') {
      conditions.push(`RequestType = $${paramIndex}`);
      params.push(type);
      paramIndex++;
    }
    
    // Фильтрация по дате создания (от)
    if (dateFrom) {
      conditions.push(`CreatedAt >= $${paramIndex}`);
      params.push(dateFrom);
      paramIndex++;
    }
    
    // Фильтрация по дате создания (до)
    if (dateTo) {
      conditions.push(`CreatedAt <= $${paramIndex}`);
      params.push(dateTo);
      paramIndex++;
    }
    
    const sql = `
      SELECT 
        r.*,
        u.UserName as CreatedByUserName,
        COUNT(*) OVER() as TotalCount
      FROM 
        Requests r
        LEFT JOIN Users u ON r.CreatedBy = u.UserId
      WHERE 
        ${conditions.join(' AND ')}
      ORDER BY 
        ${sortBy} ${sortDirection}
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
  
  // Получение заявки по ID
  static async getById(requestId) {
    const sql = `
      SELECT 
        r.*,
        u.UserName as CreatedByUserName,
        w.Name as WarehouseName
      FROM 
        Requests r
        LEFT JOIN Users u ON r.CreatedBy = u.UserId
        LEFT JOIN Warehouses w ON r.WarehouseId = w.WarehouseId
      WHERE 
        r.RequestId = $1
    `;
    
    const result = await this.query(sql, [requestId]);
    return result.rows.length ? result.rows[0] : null;
  }
  
  // Создание новой заявки
  static async create(request) {
    // Определение базовых полей заявки
    const baseFields = [
      'EnterpriseId', 'RequestName', 'RequestType', 
      'Status', 'CreatedBy', 'WarehouseId'
    ];
    const baseValues = [
      request.enterpriseId,
      request.requestName,
      request.requestType,
      request.status || 'DRAFT',
      request.createdBy,
      request.warehouseId
    ];
    
    // Добавление дополнительных полей в зависимости от типа заявки
    let additionalFields = [];
    let additionalValues = [];
    
    if (request.requestType === 'SUPPLY') {
      additionalFields = ['SupplierName', 'ExpectedDate', 'Comments'];
      additionalValues = [
        request.supplierName || null,
        request.expectedDate || null,
        request.comments || null
      ];
    } else if (request.requestType === 'TRANSFER') {
      additionalFields = ['SourceWarehouseId', 'DestinationWarehouseId', 'Comments'];
      additionalValues = [
        request.sourceWarehouseId || null,
        request.destinationWarehouseId || null,
        request.comments || null
      ];
    } else if (request.requestType === 'INVENTORY') {
      additionalFields = ['InventoryDate', 'InventoryType', 'ZoneId', 'Comments'];
      additionalValues = [
        request.inventoryDate || null,
        request.inventoryType || 'FULL',
        request.zoneId || null,
        request.comments || null
      ];
    } else if (request.requestType === 'WRITEOFF') {
      additionalFields = ['WriteoffReason', 'Comments'];
      additionalValues = [
        request.writeoffReason || null,
        request.comments || null
      ];
    }
    
    // Формирование SQL запроса
    const fields = [...baseFields, ...additionalFields];
    const values = [...baseValues, ...additionalValues];
    const placeholders = values.map((_, index) => `$${index + 1}`);
    
    const sql = `
      INSERT INTO Requests (
        ${fields.join(', ')}
      ) VALUES (
        ${placeholders.join(', ')}
      ) RETURNING *
    `;
    
    const result = await this.query(sql, values);
    return result.rows[0];
  }
  
  // Обновление заявки
  static async update(requestId, requestData) {
    // Проверяем, существует ли заявка
    const existingRequest = await this.getById(requestId);
    if (!existingRequest) {
      throw new Error('Заявка не найдена');
    }
    
    // Проверяем возможность обновления в зависимости от статуса
    if (['COMPLETED', 'CANCELED'].includes(existingRequest.status) && 
        !(requestData.status === 'DRAFT' && existingRequest.status === 'CANCELED')) {
      throw new Error('Невозможно обновить заявку в статусе COMPLETED или CANCELED');
    }
    
    const fields = [];
    const values = [];
    let paramIndex = 1;
    
    // Обновляем общие поля
    if (requestData.requestName !== undefined) {
      fields.push(`RequestName = $${paramIndex++}`);
      values.push(requestData.requestName);
    }
    
    if (requestData.status !== undefined) {
      fields.push(`Status = $${paramIndex++}`);
      values.push(requestData.status);
      
      // Если меняем статус на COMPLETED или CANCELED, добавляем дату завершения
      if (['COMPLETED', 'CANCELED'].includes(requestData.status)) {
        fields.push(`CompletedAt = $${paramIndex++}`);
        values.push(new Date());
      }
    }
    
    if (requestData.warehouseId !== undefined) {
      fields.push(`WarehouseId = $${paramIndex++}`);
      values.push(requestData.warehouseId);
    }
    
    // Обновляем специфичные поля в зависимости от типа заявки
    const requestType = existingRequest.requesttype;
    
    if (requestType === 'SUPPLY') {
      if (requestData.supplierName !== undefined) {
        fields.push(`SupplierName = $${paramIndex++}`);
        values.push(requestData.supplierName);
      }
      if (requestData.expectedDate !== undefined) {
        fields.push(`ExpectedDate = $${paramIndex++}`);
        values.push(requestData.expectedDate);
      }
    } else if (requestType === 'TRANSFER') {
      if (requestData.sourceWarehouseId !== undefined) {
        fields.push(`SourceWarehouseId = $${paramIndex++}`);
        values.push(requestData.sourceWarehouseId);
      }
      if (requestData.destinationWarehouseId !== undefined) {
        fields.push(`DestinationWarehouseId = $${paramIndex++}`);
        values.push(requestData.destinationWarehouseId);
      }
    } else if (requestType === 'INVENTORY') {
      if (requestData.inventoryDate !== undefined) {
        fields.push(`InventoryDate = $${paramIndex++}`);
        values.push(requestData.inventoryDate);
      }
      if (requestData.inventoryType !== undefined) {
        fields.push(`InventoryType = $${paramIndex++}`);
        values.push(requestData.inventoryType);
      }
      if (requestData.zoneId !== undefined) {
        fields.push(`ZoneId = $${paramIndex++}`);
        values.push(requestData.zoneId);
      }
    } else if (requestType === 'WRITEOFF') {
      if (requestData.writeoffReason !== undefined) {
        fields.push(`WriteoffReason = $${paramIndex++}`);
        values.push(requestData.writeoffReason);
      }
    }
    
    // Обновляем общие комментарии для всех типов заявок
    if (requestData.comments !== undefined) {
      fields.push(`Comments = $${paramIndex++}`);
      values.push(requestData.comments);
    }
    
    // Добавляем поле UpdatedAt
    fields.push(`UpdatedAt = $${paramIndex++}`);
    values.push(new Date());
    
    // Если нет полей для обновления, возвращаем существующую заявку
    if (fields.length === 0) {
      return existingRequest;
    }
    
    const sql = `
      UPDATE Requests
      SET ${fields.join(', ')}
      WHERE RequestId = $${paramIndex}
      RETURNING *
    `;
    values.push(requestId);
    
    const result = await this.query(sql, values);
    return result.rows[0];
  }
  
  // Отмена заявки
  static async cancel(requestId, userId, comments) {
    // Проверяем, существует ли заявка
    const existingRequest = await this.getById(requestId);
    if (!existingRequest) {
      throw new Error('Заявка не найдена');
    }
    
    // Проверяем возможность отмены в зависимости от статуса
    if (['COMPLETED', 'CANCELED'].includes(existingRequest.status)) {
      throw new Error('Невозможно отменить заявку в статусе COMPLETED или CANCELED');
    }
    
    const sql = `
      UPDATE Requests
      SET 
        Status = 'CANCELED',
        CompletedAt = CURRENT_TIMESTAMP,
        UpdatedAt = CURRENT_TIMESTAMP,
        Comments = COALESCE(Comments, '') || $1
      WHERE RequestId = $2
        RETURNING *
      `;
      
    const cancelComment = `\n[${new Date().toISOString()}] Отменено пользователем ${userId}. ${comments || ''}`;
    const result = await this.query(sql, [cancelComment, requestId]);
    
    return result.rows[0];
  }
  
  // Получение позиций заявки
  static async getItems(requestId) {
    const sql = `
      SELECT 
        ri.*,
        p.Name as ProductName,
        p.SKU,
        p.Barcode
      FROM 
        RequestItems ri
        JOIN Products p ON ri.ProductId = p.ProductId
      WHERE 
        ri.RequestId = $1
      ORDER BY
        ri.RequestItemId
    `;
    
    const result = await this.query(sql, [requestId]);
    return result.rows;
  }
  
  // Добавление позиции в заявку
  static async addItem(requestId, item) {
    // Проверяем, существует ли заявка
    const existingRequest = await this.getById(requestId);
    if (!existingRequest) {
      throw new Error('Заявка не найдена');
    }
    
    // Проверяем возможность добавления в зависимости от статуса
    if (['COMPLETED', 'CANCELED'].includes(existingRequest.status)) {
      throw new Error('Невозможно добавить позицию в заявку в статусе COMPLETED или CANCELED');
    }
    
    const sql = `
      INSERT INTO RequestItems (
        RequestId, ProductId, Quantity, RequestedQuantity, Comment
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING *
    `;
    
    const values = [
      requestId,
      item.productId,
      item.quantity || 0,
      item.requestedQuantity || item.quantity || 0,
      item.comment || null
    ];
    
    const result = await this.query(sql, values);
    
    // Обновляем дату изменения заявки
    await this.query(`
      UPDATE Requests
      SET UpdatedAt = CURRENT_TIMESTAMP
      WHERE RequestId = $1
    `, [requestId]);
    
    return result.rows[0];
  }
  
  // Обновление позиции заявки
  static async updateItem(requestId, itemId, itemData) {
    // Проверяем, существует ли заявка
    const existingRequest = await this.getById(requestId);
    if (!existingRequest) {
      throw new Error('Заявка не найдена');
    }
    
    // Проверяем возможность обновления в зависимости от статуса
    if (['COMPLETED', 'CANCELED'].includes(existingRequest.status)) {
      throw new Error('Невозможно обновить позицию в заявке в статусе COMPLETED или CANCELED');
    }
    
    const fields = [];
    const values = [];
    let paramIndex = 1;
    
    if (itemData.quantity !== undefined) {
      fields.push(`Quantity = $${paramIndex++}`);
      values.push(itemData.quantity);
    }
    
    if (itemData.requestedQuantity !== undefined) {
      fields.push(`RequestedQuantity = $${paramIndex++}`);
      values.push(itemData.requestedQuantity);
    }
    
    if (itemData.comment !== undefined) {
      fields.push(`Comment = $${paramIndex++}`);
      values.push(itemData.comment);
    }
    
    // Если нет полей для обновления, получаем текущую позицию
    if (fields.length === 0) {
      const currentItem = await this.query(`
        SELECT * FROM RequestItems WHERE RequestItemId = $1
      `, [itemId]);
      
      return currentItem.rows.length ? currentItem.rows[0] : null;
    }
    
    const sql = `
      UPDATE RequestItems
      SET ${fields.join(', ')}
      WHERE RequestItemId = $${paramIndex} AND RequestId = $${paramIndex + 1}
      RETURNING *
    `;
    
    values.push(itemId, requestId);
    
    const result = await this.query(sql, values);
    
    // Обновляем дату изменения заявки
    await this.query(`
      UPDATE Requests
      SET UpdatedAt = CURRENT_TIMESTAMP
      WHERE RequestId = $1
    `, [requestId]);
    
    return result.rows.length ? result.rows[0] : null;
  }
  
  // Удаление позиции из заявки
  static async removeItem(requestId, itemId) {
    // Проверяем, существует ли заявка
    const existingRequest = await this.getById(requestId);
    if (!existingRequest) {
      throw new Error('Заявка не найдена');
    }
    
    // Проверяем возможность удаления в зависимости от статуса
    if (['COMPLETED', 'CANCELED'].includes(existingRequest.status)) {
      throw new Error('Невозможно удалить позицию из заявки в статусе COMPLETED или CANCELED');
    }
    
    const sql = `
      DELETE FROM RequestItems
      WHERE RequestItemId = $1 AND RequestId = $2
        RETURNING *
      `;
      
    const result = await this.query(sql, [itemId, requestId]);
    
    // Обновляем дату изменения заявки
    await this.query(`
      UPDATE Requests
      SET UpdatedAt = CURRENT_TIMESTAMP
      WHERE RequestId = $1
    `, [requestId]);
    
    return result.rowCount > 0;
  }
  
  // Получение истории изменений заявки
  static async getHistory(requestId) {
    const sql = `
      SELECT 
        rh.*,
        u.UserName as UserName
      FROM 
        RequestHistory rh
        LEFT JOIN Users u ON rh.UserId = u.UserId
      WHERE 
        rh.RequestId = $1
      ORDER BY
        rh.CreatedAt DESC
    `;
    
    const result = await this.query(sql, [requestId]);
    return result.rows;
  }
  
  // Добавление записи в историю изменений
  static async addHistoryRecord(requestId, userId, action, details) {
    const sql = `
      INSERT INTO RequestHistory (
        RequestId, UserId, Action, Details
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    
    const result = await this.query(sql, [
      requestId,
      userId,
      action,
      details || null
    ]);
    
    return result.rows[0];
  }
  
  // Выполнение заявки на поставку
  static async completeSupplyRequest(requestId, userId) {
    return this.transaction(async (client) => {
      // Проверяем, существует ли заявка
      const requestSql = `
        SELECT * FROM Requests
        WHERE RequestId = $1 AND RequestType = 'SUPPLY'
      `;
      const requestResult = await client.query(requestSql, [requestId]);
      
      if (requestResult.rows.length === 0) {
        throw new Error('Заявка на поставку не найдена');
      }
      
      const request = requestResult.rows[0];
      
      // Проверяем возможность выполнения в зависимости от статуса
      if (request.status !== 'IN_PROGRESS') {
        throw new Error('Заявку можно выполнить только в статусе "В работе"');
      }
      
      // Получаем все позиции заявки
      const itemsSql = `
      SELECT 
        ri.*,
          p.EnterpriseId
        FROM 
          RequestItems ri
          JOIN Products p ON ri.ProductId = p.ProductId
      WHERE 
          ri.RequestId = $1
      `;
      const itemsResult = await client.query(itemsSql, [requestId]);
      
      // Добавляем товары на склад
      for (const item of itemsResult.rows) {
        // Проверяем существующую запись инвентаризации
        const checkSql = `
          SELECT * FROM InventoryRecords
          WHERE ProductId = $1 AND WarehouseId = $2
        `;
        
        const checkResult = await client.query(checkSql, [item.productid, request.warehouseid]);
        
        if (checkResult.rows.length > 0) {
          // Обновляем существующую запись
          await client.query(`
            UPDATE InventoryRecords
            SET Quantity = Quantity + $1, UpdatedAt = CURRENT_TIMESTAMP
            WHERE ProductId = $2 AND WarehouseId = $3
          `, [item.quantity, item.productid, request.warehouseid]);
        } else {
          // Создаем новую запись
          await client.query(`
            INSERT INTO InventoryRecords (
              ProductId, WarehouseId, Quantity, ReservedQuantity
            ) VALUES (
              $1, $2, $3, 0
            )
          `, [item.productid, request.warehouseid, item.quantity]);
        }
        
        // Записываем движение инвентаря
        await client.query(`
          INSERT INTO InventoryMovements (
            EnterpriseId, ProductId, WarehouseId, 
            DestinationZoneId, DestinationCellId,
            Quantity, MovementType, ReferenceId, 
            Comments, CreatedBy
          ) VALUES (
            $1, $2, $3, NULL, NULL, $4, 'RECEIPT', $5, $6, $7
          )
        `, [
          item.enterpriseid,
          item.productid,
          request.warehouseid,
          item.quantity,
          requestId,
          `Поступление по заявке №${requestId}`,
          userId
        ]);
      }
      
      // Обновляем статус заявки
      const updateSql = `
        UPDATE Requests
        SET 
          Status = 'COMPLETED',
          CompletedAt = CURRENT_TIMESTAMP,
          UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
        RETURNING *
      `;
      
      const updateResult = await client.query(updateSql, [requestId]);
      
      // Добавляем запись в историю
      await client.query(`
        INSERT INTO RequestHistory (
          RequestId, UserId, Action, Details
        ) VALUES (
          $1, $2, 'COMPLETE', 'Заявка на поставку выполнена'
        )
      `, [requestId, userId]);
      
      return updateResult.rows[0];
    });
  }
  
  // Выполнение заявки на перемещение
  static async completeTransferRequest(requestId, userId) {
    return this.transaction(async (client) => {
      // Проверяем, существует ли заявка
      const requestSql = `
        SELECT * FROM Requests
        WHERE RequestId = $1 AND RequestType = 'TRANSFER'
      `;
      const requestResult = await client.query(requestSql, [requestId]);
      
      if (requestResult.rows.length === 0) {
        throw new Error('Заявка на перемещение не найдена');
      }
      
      const request = requestResult.rows[0];
      
      // Проверяем возможность выполнения в зависимости от статуса
      if (request.status !== 'IN_PROGRESS') {
        throw new Error('Заявку можно выполнить только в статусе "В работе"');
      }
      
      // Получаем все позиции заявки
      const itemsSql = `
      SELECT 
          ri.*,
          p.EnterpriseId
      FROM 
          RequestItems ri
          JOIN Products p ON ri.ProductId = p.ProductId
      WHERE 
          ri.RequestId = $1
      `;
      const itemsResult = await client.query(itemsSql, [requestId]);
      
      // Перемещаем товары между складами
      for (const item of itemsResult.rows) {
        // Проверяем наличие достаточного количества на исходном складе
        const sourceSql = `
          SELECT * FROM InventoryRecords
          WHERE ProductId = $1 AND WarehouseId = $2
        `;
        
        const sourceResult = await client.query(sourceSql, [
          item.productid, 
          request.sourcewarehouseid
        ]);
        
        if (sourceResult.rows.length === 0 || 
            sourceResult.rows[0].quantity < item.quantity ||
            sourceResult.rows[0].quantity - sourceResult.rows[0].reservedquantity < item.quantity) {
          throw new Error(`Недостаточно товара ID ${item.productid} на складе-источнике`);
        }
        
        // Уменьшаем количество на исходном складе
        await client.query(`
          UPDATE InventoryRecords
          SET Quantity = Quantity - $1, UpdatedAt = CURRENT_TIMESTAMP
          WHERE ProductId = $2 AND WarehouseId = $3
        `, [item.quantity, item.productid, request.sourcewarehouseid]);
        
        // Проверяем существующую запись на целевом складе
        const destSql = `
          SELECT * FROM InventoryRecords
          WHERE ProductId = $1 AND WarehouseId = $2
        `;
        
        const destResult = await client.query(destSql, [
          item.productid, 
          request.destinationwarehouseid
        ]);
        
        if (destResult.rows.length > 0) {
          // Обновляем существующую запись
          await client.query(`
            UPDATE InventoryRecords
            SET Quantity = Quantity + $1, UpdatedAt = CURRENT_TIMESTAMP
            WHERE ProductId = $2 AND WarehouseId = $3
          `, [item.quantity, item.productid, request.destinationwarehouseid]);
        } else {
          // Создаем новую запись
          await client.query(`
            INSERT INTO InventoryRecords (
              ProductId, WarehouseId, Quantity, ReservedQuantity
            ) VALUES (
              $1, $2, $3, 0
            )
          `, [item.productid, request.destinationwarehouseid, item.quantity]);
        }
        
        // Записываем движение инвентаря
        await client.query(`
          INSERT INTO InventoryMovements (
            EnterpriseId, ProductId, WarehouseId, 
            SourceWarehouseId, DestinationWarehouseId,
            Quantity, MovementType, ReferenceId, 
            Comments, CreatedBy
          ) VALUES (
            $1, $2, $3, $4, $5, $6, 'TRANSFER', $7, $8, $9
          )
        `, [
          item.enterpriseid,
          item.productid,
          request.sourcewarehouseid,
          request.sourcewarehouseid,
          request.destinationwarehouseid,
          item.quantity,
          requestId,
          `Перемещение по заявке №${requestId}`,
          userId
        ]);
      }
      
      // Удаляем записи с нулевым количеством
      await client.query(`
        DELETE FROM InventoryRecords
        WHERE Quantity = 0 AND ReservedQuantity = 0
      `);
      
      // Обновляем статус заявки
      const updateSql = `
        UPDATE Requests
        SET 
          Status = 'COMPLETED',
          CompletedAt = CURRENT_TIMESTAMP,
          UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
        RETURNING *
      `;
      
      const updateResult = await client.query(updateSql, [requestId]);
      
      // Добавляем запись в историю
      await client.query(`
        INSERT INTO RequestHistory (
          RequestId, UserId, Action, Details
        ) VALUES (
          $1, $2, 'COMPLETE', 'Заявка на перемещение выполнена'
        )
      `, [requestId, userId]);
      
      return updateResult.rows[0];
    });
  }
  
  // Выполнение заявки на списание
  static async completeWriteoffRequest(requestId, userId) {
    return this.transaction(async (client) => {
      // Проверяем, существует ли заявка
      const requestSql = `
        SELECT * FROM Requests
        WHERE RequestId = $1 AND RequestType = 'WRITEOFF'
      `;
      const requestResult = await client.query(requestSql, [requestId]);
      
      if (requestResult.rows.length === 0) {
        throw new Error('Заявка на списание не найдена');
      }
      
      const request = requestResult.rows[0];
      
      // Проверяем возможность выполнения в зависимости от статуса
      if (request.status !== 'IN_PROGRESS') {
        throw new Error('Заявку можно выполнить только в статусе "В работе"');
      }
      
      // Получаем все позиции заявки
      const itemsSql = `
      SELECT 
          ri.*,
          p.EnterpriseId
      FROM 
          RequestItems ri
          JOIN Products p ON ri.ProductId = p.ProductId
      WHERE 
          ri.RequestId = $1
      `;
      const itemsResult = await client.query(itemsSql, [requestId]);
      
      // Списываем товары со склада
      for (const item of itemsResult.rows) {
        // Проверяем наличие достаточного количества на складе
        const inventorySql = `
          SELECT * FROM InventoryRecords
          WHERE ProductId = $1 AND WarehouseId = $2
        `;
        
        const inventoryResult = await client.query(inventorySql, [
          item.productid, 
          request.warehouseid
        ]);
        
        if (inventoryResult.rows.length === 0 || 
            inventoryResult.rows[0].quantity < item.quantity ||
            inventoryResult.rows[0].quantity - inventoryResult.rows[0].reservedquantity < item.quantity) {
          throw new Error(`Недостаточно товара ID ${item.productid} на складе`);
        }
        
        // Уменьшаем количество на складе
        await client.query(`
          UPDATE InventoryRecords
          SET Quantity = Quantity - $1, UpdatedAt = CURRENT_TIMESTAMP
          WHERE ProductId = $2 AND WarehouseId = $3
        `, [item.quantity, item.productid, request.warehouseid]);
        
        // Записываем движение инвентаря
        await client.query(`
          INSERT INTO InventoryMovements (
            EnterpriseId, ProductId, WarehouseId, 
            SourceZoneId, SourceCellId,
            Quantity, MovementType, ReferenceId, 
            Comments, CreatedBy
          ) VALUES (
            $1, $2, $3, NULL, NULL, $4, 'ISSUE', $5, $6, $7
          )
        `, [
          item.enterpriseid,
          item.productid,
          request.warehouseid,
          item.quantity,
          requestId,
          `Списание по заявке №${requestId}: ${request.writeoffreason || 'не указана причина'}`,
          userId
        ]);
      }
      
      // Удаляем записи с нулевым количеством
      await client.query(`
        DELETE FROM InventoryRecords
        WHERE Quantity = 0 AND ReservedQuantity = 0
      `);
      
      // Обновляем статус заявки
      const updateSql = `
        UPDATE Requests
        SET 
          Status = 'COMPLETED',
          CompletedAt = CURRENT_TIMESTAMP,
          UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
      RETURNING *
    `;
    
      const updateResult = await client.query(updateSql, [requestId]);
      
      // Добавляем запись в историю
      await client.query(`
        INSERT INTO RequestHistory (
          RequestId, UserId, Action, Details
        ) VALUES (
          $1, $2, 'COMPLETE', 'Заявка на списание выполнена'
        )
      `, [requestId, userId]);
      
      return updateResult.rows[0];
    });
  }
} 
