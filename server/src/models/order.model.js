import { BaseModel } from './base.model.js';

export class OrderModel extends BaseModel {
  // Получение всех статусов заказов
  static async getOrderStatuses() {
    const sql = `
      SELECT * FROM OrderStatuses
      ORDER BY StatusId
    `;
    const result = await this.query(sql);
    return result.rows;
  }

  // Получение всех источников заказов
  static async getOrderSources() {
    const sql = `
      SELECT * FROM OrderSources
      ORDER BY SourceId
    `;
    const result = await this.query(sql);
    return result.rows;
  }

  // Получение заказа по ID
  static async getById(orderId) {
    const sql = `
      SELECT o.*, 
        s.Name as StatusName, 
        src.Name as SourceName,
        w.Name as WarehouseName,
        u.Username as AssignedToUsername
      FROM Orders o
      LEFT JOIN OrderStatuses s ON o.StatusId = s.StatusId
      LEFT JOIN OrderSources src ON o.SourceId = src.SourceId
      LEFT JOIN Warehouses w ON o.WarehouseId = w.WarehouseId
      LEFT JOIN Users u ON o.AssignedTo = u.UserId
      WHERE o.OrderId = $1
    `;
    const result = await this.query(sql, [orderId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение заказа по номеру
  static async getByOrderNumber(enterpriseId, orderNumber) {
    const sql = `
      SELECT o.*, 
        s.Name as StatusName, 
        src.Name as SourceName,
        w.Name as WarehouseName,
        u.Username as AssignedToUsername
      FROM Orders o
      LEFT JOIN OrderStatuses s ON o.StatusId = s.StatusId
      LEFT JOIN OrderSources src ON o.SourceId = src.SourceId
      LEFT JOIN Warehouses w ON o.WarehouseId = w.WarehouseId
      LEFT JOIN Users u ON o.AssignedTo = u.UserId
      WHERE o.EnterpriseId = $1 AND o.OrderNumber = $2
    `;
    const result = await this.query(sql, [enterpriseId, orderNumber]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение заказа по внешнему номеру
  static async getByExternalOrderNumber(enterpriseId, externalOrderNumber) {
    const sql = `
      SELECT o.*, 
        s.Name as StatusName, 
        src.Name as SourceName,
        w.Name as WarehouseName,
        u.Username as AssignedToUsername
      FROM Orders o
      LEFT JOIN OrderStatuses s ON o.StatusId = s.StatusId
      LEFT JOIN OrderSources src ON o.SourceId = src.SourceId
      LEFT JOIN Warehouses w ON o.WarehouseId = w.WarehouseId
      LEFT JOIN Users u ON o.AssignedTo = u.UserId
      WHERE o.EnterpriseId = $1 AND o.ExternalOrderNumber = $2
    `;
    const result = await this.query(sql, [enterpriseId, externalOrderNumber]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Поиск заказов по различным параметрам
  static async search(
    enterpriseId,
    searchParams = {}
  ) {
    const { 
      query,
      statusId,
      sourceId,
      warehouseId,
      assignedTo,
      startDate,
      endDate,
      sortBy = 'CreatedAt',
      sortDirection = 'DESC',
      limit = 100,
      offset = 0
    } = searchParams;
    
    let conditions = ['o.EnterpriseId = $1'];
    const params = [enterpriseId];
    let paramIndex = 2;
    
    // Поиск по номеру заказа, внешнему номеру или данным клиента
    if (query) {
      conditions.push(`(
        LOWER(o.OrderNumber) LIKE LOWER($${paramIndex}) OR
        LOWER(o.ExternalOrderNumber) LIKE LOWER($${paramIndex}) OR
        LOWER(o.CustomerName) LIKE LOWER($${paramIndex}) OR
        LOWER(o.CustomerPhone) LIKE LOWER($${paramIndex}) OR
        LOWER(o.CustomerEmail) LIKE LOWER($${paramIndex}) OR
        LOWER(o.Notes) LIKE LOWER($${paramIndex})
      )`);
      params.push(`%${query}%`);
      paramIndex++;
    }
    
    // Фильтр по статусу
    if (statusId) {
      conditions.push(`o.StatusId = $${paramIndex}`);
      params.push(statusId);
      paramIndex++;
    }
    
    // Фильтр по источнику
    if (sourceId) {
      conditions.push(`o.SourceId = $${paramIndex}`);
      params.push(sourceId);
      paramIndex++;
    }
    
    // Фильтр по складу
    if (warehouseId) {
      conditions.push(`o.WarehouseId = $${paramIndex}`);
      params.push(warehouseId);
      paramIndex++;
    }
    
    // Фильтр по назначенному пользователю
    if (assignedTo) {
      conditions.push(`o.AssignedTo = $${paramIndex}`);
      params.push(assignedTo);
      paramIndex++;
    }
    
    // Фильтр по дате создания
    if (startDate) {
      conditions.push(`o.CreatedAt >= $${paramIndex}`);
      params.push(startDate);
      paramIndex++;
    }
    
    if (endDate) {
      conditions.push(`o.CreatedAt <= $${paramIndex}`);
      params.push(endDate);
      paramIndex++;
    }
    
    const sql = `
      SELECT o.*, 
        s.Name as StatusName, 
        src.Name as SourceName,
        w.Name as WarehouseName,
        u.Username as AssignedToUsername,
        COUNT(*) OVER() as TotalCount
      FROM Orders o
      LEFT JOIN OrderStatuses s ON o.StatusId = s.StatusId
      LEFT JOIN OrderSources src ON o.SourceId = src.SourceId
      LEFT JOIN Warehouses w ON o.WarehouseId = w.WarehouseId
      LEFT JOIN Users u ON o.AssignedTo = u.UserId
      WHERE ${conditions.join(' AND ')}
      ORDER BY o.${sortBy} ${sortDirection}
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

  // Создание нового заказа
  static async create(order) {
    return this.transaction(async (client) => {
      // Генерируем номер заказа, если он не указан
      if (!order.orderNumber) {
        const prefix = 'ORD-';
        const seqResult = await client.query(`SELECT nextval('order_number_seq') as seq`);
        const seq = seqResult.rows[0].seq;
        order.orderNumber = `${prefix}${seq.toString().padStart(8, '0')}`;
      }
      
      const sql = `
        INSERT INTO Orders (
          EnterpriseId, OrderNumber, ExternalOrderNumber, SourceId, StatusId,
          CustomerId, CustomerName, CustomerPhone, CustomerEmail, ShippingAddress,
          TotalAmount, Notes, WarehouseId, AssignedTo
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        order.enterpriseId,
        order.orderNumber,
        order.externalOrderNumber || null,
        order.sourceId,
        order.statusId,
        order.customerId || null,
        order.customerName || null,
        order.customerPhone || null,
        order.customerEmail || null,
        order.shippingAddress ? JSON.stringify(order.shippingAddress) : null,
        order.totalAmount || 0,
        order.notes || null,
        order.warehouseId || null,
        order.assignedTo || null
      ]);
      
      const newOrder = result.rows[0];
      
      // Если есть позиции заказа, добавляем их
      if (order.items && Array.isArray(order.items) && order.items.length > 0) {
        for (const item of order.items) {
          await this.addOrderItem(client, newOrder.orderid, item);
        }
      }
      
      // Создаем запись о событии создания заказа
      await this.logOrderEvent(client, newOrder.orderid, order.createdBy || null, 'CREATE', { message: 'Заказ создан' });
      
      return newOrder;
    });
  }

  // Добавление позиции в заказ
  static async addOrderItem(client, orderId, item) {
    const sql = `
      INSERT INTO OrderItems (
        OrderId, ProductId, Quantity, Price, StatusId, Notes
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING *
    `;
    
    const result = await client.query(sql, [
      orderId,
      item.productId,
      item.quantity,
      item.price || null,
      item.statusId || 1, // По умолчанию "Новый"
      item.notes || null
    ]);
    
    return result.rows[0];
  }

  // Логирование события заказа
  static async logOrderEvent(client, orderId, userId, eventType, details) {
    const sql = `
      INSERT INTO OrderEvents (
        OrderId, UserId, EventType, Details
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    
    const result = await client.query(sql, [
      orderId,
      userId,
      eventType,
      JSON.stringify(details)
    ]);
    
    return result.rows[0];
  }

  // Обновление заказа
  static async update(orderId, orderData, userId) {
    return this.transaction(async (client) => {
      // Получаем текущее состояние заказа для сравнения изменений
      const currentOrderResult = await client.query(
        `SELECT * FROM Orders WHERE OrderId = $1`,
        [orderId]
      );
      
      if (!currentOrderResult.rows.length) {
        return null;
      }
      
      const currentOrder = currentOrderResult.rows[0];
      const changes = {};
      
      const fields = [];
      const values = [];
      let paramIndex = 1;
      
      if (orderData.externalOrderNumber !== undefined) {
        fields.push(`ExternalOrderNumber = $${paramIndex++}`);
        values.push(orderData.externalOrderNumber);
        changes.externalOrderNumber = {
          from: currentOrder.externalordernumber,
          to: orderData.externalOrderNumber
        };
      }
      
      if (orderData.sourceId !== undefined) {
        fields.push(`SourceId = $${paramIndex++}`);
        values.push(orderData.sourceId);
        changes.sourceId = {
          from: currentOrder.sourceid,
          to: orderData.sourceId
        };
      }
      
      if (orderData.statusId !== undefined) {
        fields.push(`StatusId = $${paramIndex++}`);
        values.push(orderData.statusId);
        changes.statusId = {
          from: currentOrder.statusid,
          to: orderData.statusId
        };
      }
      
      if (orderData.customerId !== undefined) {
        fields.push(`CustomerId = $${paramIndex++}`);
        values.push(orderData.customerId);
        changes.customerId = {
          from: currentOrder.customerid,
          to: orderData.customerId
        };
      }
      
      if (orderData.customerName !== undefined) {
        fields.push(`CustomerName = $${paramIndex++}`);
        values.push(orderData.customerName);
        changes.customerName = {
          from: currentOrder.customername,
          to: orderData.customerName
        };
      }
      
      if (orderData.customerPhone !== undefined) {
        fields.push(`CustomerPhone = $${paramIndex++}`);
        values.push(orderData.customerPhone);
        changes.customerPhone = {
          from: currentOrder.customerphone,
          to: orderData.customerPhone
        };
      }
      
      if (orderData.customerEmail !== undefined) {
        fields.push(`CustomerEmail = $${paramIndex++}`);
        values.push(orderData.customerEmail);
        changes.customerEmail = {
          from: currentOrder.customeremail,
          to: orderData.customerEmail
        };
      }
      
      if (orderData.shippingAddress !== undefined) {
        fields.push(`ShippingAddress = $${paramIndex++}`);
        values.push(JSON.stringify(orderData.shippingAddress));
        changes.shippingAddress = {
          from: currentOrder.shippingaddress ? JSON.stringify(currentOrder.shippingaddress) : null,
          to: orderData.shippingAddress ? JSON.stringify(orderData.shippingAddress) : null
        };
      }
      
      if (orderData.totalAmount !== undefined) {
        fields.push(`TotalAmount = $${paramIndex++}`);
        values.push(orderData.totalAmount);
        changes.totalAmount = {
          from: currentOrder.totalamount,
          to: orderData.totalAmount
        };
      }
      
      if (orderData.notes !== undefined) {
        fields.push(`Notes = $${paramIndex++}`);
        values.push(orderData.notes);
        changes.notes = {
          from: currentOrder.notes,
          to: orderData.notes
        };
      }
      
      if (orderData.warehouseId !== undefined) {
        fields.push(`WarehouseId = $${paramIndex++}`);
        values.push(orderData.warehouseId);
        changes.warehouseId = {
          from: currentOrder.warehouseid,
          to: orderData.warehouseId
        };
      }
      
      if (orderData.assignedTo !== undefined) {
        fields.push(`AssignedTo = $${paramIndex++}`);
        values.push(orderData.assignedTo);
        changes.assignedTo = {
          from: currentOrder.assignedto,
          to: orderData.assignedTo
        };
      }
      
      const sql = `
        UPDATE Orders
        SET ${fields.join(', ')}
        WHERE OrderId = $${paramIndex}
        RETURNING *
      `;
      
      const result = await client.query(sql, [...values, orderId]);
      
      const updatedOrder = result.rows[0];
      
      // Если есть изменения, создаем запись о событии обновления заказа
      if (Object.keys(changes).length > 0) {
        await this.logOrderEvent(client, updatedOrder.orderid, userId, 'UPDATE', changes);
      }
      
      return updatedOrder;
    });
  }
}