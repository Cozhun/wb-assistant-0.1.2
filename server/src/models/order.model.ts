import { BaseModel } from '.';

export interface OrderStatus {
  statusId?: number;
  name: string;
  description?: string;
  color?: string;
}

export interface OrderSource {
  sourceId?: number;
  name: string;
  description?: string;
}

export interface Order {
  orderId?: number;
  enterpriseId: number;
  orderNumber: string;
  externalOrderNumber?: string;
  sourceId: number;
  statusId: number;
  customerId?: number;
  customerName?: string;
  customerPhone?: string;
  customerEmail?: string;
  shippingAddress?: string;
  totalAmount?: number;
  createdAt?: Date;
  updatedAt?: Date;
  shippedAt?: Date;
  deliveredAt?: Date;
  notes?: string;
  warehouseId?: number;
  assignedTo?: number;
}

export interface OrderItem {
  orderItemId?: number;
  orderId: number;
  productId: number;
  quantity: number;
  price?: number;
  statusId: number;
  notes?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface OrderEvent {
  eventId?: number;
  orderId: number;
  userId: number;
  eventType: string;
  details: any;
  createdAt?: Date;
}

export class OrderModel extends BaseModel {
  // Получение статусов заказов
  static async getOrderStatuses(): Promise<OrderStatus[]> {
    const sql = `
      SELECT * FROM OrderStatuses
      ORDER BY StatusId
    `;
    const result = await this.query<OrderStatus>(sql);
    return result.rows;
  }

  // Получение источников заказов
  static async getOrderSources(): Promise<OrderSource[]> {
    const sql = `
      SELECT * FROM OrderSources
      ORDER BY SourceId
    `;
    const result = await this.query<OrderSource>(sql);
    return result.rows;
  }

  // Получение заказа по ID
  static async getById(orderId: number): Promise<Order | null> {
    const sql = `
      SELECT * FROM Orders
      WHERE OrderId = $1
    `;
    const result = await this.query<Order>(sql, [orderId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение заказа по номеру
  static async getByOrderNumber(enterpriseId: number, orderNumber: string): Promise<Order | null> {
    const sql = `
      SELECT * FROM Orders
      WHERE EnterpriseId = $1 AND OrderNumber = $2
    `;
    const result = await this.query<Order>(sql, [enterpriseId, orderNumber]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение заказа по внешнему номеру
  static async getByExternalOrderNumber(enterpriseId: number, externalOrderNumber: string): Promise<Order | null> {
    const sql = `
      SELECT * FROM Orders
      WHERE EnterpriseId = $1 AND ExternalOrderNumber = $2
    `;
    const result = await this.query<Order>(sql, [enterpriseId, externalOrderNumber]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение списка заказов по предприятию
  static async getByEnterpriseId(
    enterpriseId: number,
    filters: {
      statusId?: number;
      sourceId?: number;
      warehouseId?: number;
      assignedTo?: number;
      startDate?: Date;
      endDate?: Date;
      search?: string;
    } = {},
    sort: {
      field?: 'createdAt' | 'updatedAt' | 'orderNumber' | 'totalAmount';
      direction?: 'ASC' | 'DESC';
    } = { field: 'createdAt', direction: 'DESC' },
    pagination: {
      page?: number;
      pageSize?: number;
    } = { page: 1, pageSize: 20 }
  ): Promise<{ orders: Order[]; total: number }> {
    // Собираем условия фильтрации
    const conditions: string[] = ['EnterpriseId = $1'];
    const params: any[] = [enterpriseId];
    let paramIndex = 2;

    if (filters.statusId !== undefined) {
      conditions.push(`StatusId = $${paramIndex++}`);
      params.push(filters.statusId);
    }

    if (filters.sourceId !== undefined) {
      conditions.push(`SourceId = $${paramIndex++}`);
      params.push(filters.sourceId);
    }

    if (filters.warehouseId !== undefined) {
      conditions.push(`WarehouseId = $${paramIndex++}`);
      params.push(filters.warehouseId);
    }

    if (filters.assignedTo !== undefined) {
      conditions.push(`AssignedTo = $${paramIndex++}`);
      params.push(filters.assignedTo);
    }

    if (filters.startDate) {
      conditions.push(`CreatedAt >= $${paramIndex++}`);
      params.push(filters.startDate);
    }

    if (filters.endDate) {
      conditions.push(`CreatedAt <= $${paramIndex++}`);
      params.push(filters.endDate);
    }

    if (filters.search) {
      conditions.push(`(
        OrderNumber ILIKE $${paramIndex} OR 
        ExternalOrderNumber ILIKE $${paramIndex} OR 
        CustomerName ILIKE $${paramIndex} OR 
        CustomerPhone ILIKE $${paramIndex} OR 
        CustomerEmail ILIKE $${paramIndex}
      )`);
      params.push(`%${filters.search}%`);
      paramIndex++;
    }

    // Собираем запрос
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    
    // Определяем сортировку
    const sortField = sort.field || 'createdAt';
    const sortDirection = sort.direction || 'DESC';
    const orderBy = `ORDER BY ${this.mapFieldToColumn(sortField)} ${sortDirection}`;
    
    // Определяем пагинацию
    const page = pagination.page || 1;
    const pageSize = pagination.pageSize || 20;
    const offset = (page - 1) * pageSize;
    const limit = `LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(pageSize, offset);

    // Получаем данные
    const sql = `
      SELECT * FROM Orders
      ${where}
      ${orderBy}
      ${limit}
    `;

    const countSql = `
      SELECT COUNT(*) as total FROM Orders
      ${where}
    `;

    const result = await this.query<Order>(sql, params);
    
    // Убираем параметры пагинации для запроса подсчета
    params.pop();
    params.pop();
    const countResult = await this.query<{ total: string }>(countSql, params);

    return {
      orders: result.rows,
      total: parseInt(countResult.rows[0].total)
    };
  }

  // Вспомогательный метод для маппинга полей на столбцы БД
  private static mapFieldToColumn(field: string): string {
    const mapping: Record<string, string> = {
      'createdAt': 'CreatedAt',
      'updatedAt': 'UpdatedAt',
      'orderNumber': 'OrderNumber',
      'totalAmount': 'TotalAmount'
    };
    return mapping[field] || 'CreatedAt';
  }

  // Создание нового заказа
  static async create(order: Order): Promise<Order> {
    return this.transaction(async (client) => {
      // Генерируем номер заказа, если он не указан
      let orderNumber = order.orderNumber;
      if (!orderNumber) {
        const yearMonth = new Date().toISOString().slice(2, 7).replace('-', '');
        const counterResult = await client.query(`
          SELECT COUNT(*) + 1 as counter FROM Orders
          WHERE EnterpriseId = $1 AND CreatedAt >= date_trunc('month', CURRENT_DATE)
        `, [order.enterpriseId]);
        const counter = counterResult.rows[0].counter.toString().padStart(4, '0');
        orderNumber = `ORD-${yearMonth}-${counter}`;
      }

      // Создаем заказ
      const sql = `
        INSERT INTO Orders (
          EnterpriseId, OrderNumber, ExternalOrderNumber, SourceId, 
          StatusId, CustomerId, CustomerName, CustomerPhone, 
          CustomerEmail, ShippingAddress, TotalAmount,
          Notes, WarehouseId, AssignedTo
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
        ) RETURNING *
      `;

      const result = await client.query(sql, [
        order.enterpriseId,
        orderNumber,
        order.externalOrderNumber || null,
        order.sourceId,
        order.statusId,
        order.customerId || null,
        order.customerName || null,
        order.customerPhone || null,
        order.customerEmail || null,
        order.shippingAddress || null,
        order.totalAmount || 0,
        order.notes || null,
        order.warehouseId || null,
        order.assignedTo || null
      ]);

      // Записываем событие создания заказа
      const userId = 1; // TODO: Заменить на реального пользователя
      const eventSql = `
        INSERT INTO OrderEvents (
          OrderId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'CREATE', $3
        )
      `;

      await client.query(eventSql, [
        result.rows[0].orderid,
        userId,
        JSON.stringify({ statusId: order.statusId, message: 'Заказ создан' })
      ]);

      return result.rows[0];
    });
  }

  // Обновление заказа
  static async update(orderId: number, order: Partial<Order>, userId: number): Promise<Order | null> {
    return this.transaction(async (client) => {
      // Получаем текущий заказ
      const currentResult = await client.query(`
        SELECT * FROM Orders WHERE OrderId = $1
      `, [orderId]);
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentOrder = currentResult.rows[0];
      
      // Собираем поля для обновления
      const fields: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;
      const changes: any = {};

      if (order.externalOrderNumber !== undefined) {
        fields.push(`ExternalOrderNumber = $${paramIndex++}`);
        values.push(order.externalOrderNumber);
        changes.externalOrderNumber = { 
          from: currentOrder.externalordernumber, 
          to: order.externalOrderNumber 
        };
      }

      if (order.sourceId !== undefined) {
        fields.push(`SourceId = $${paramIndex++}`);
        values.push(order.sourceId);
        changes.sourceId = { from: currentOrder.sourceid, to: order.sourceId };
      }

      if (order.statusId !== undefined && order.statusId !== currentOrder.statusid) {
        fields.push(`StatusId = $${paramIndex++}`);
        values.push(order.statusId);
        changes.statusId = { from: currentOrder.statusid, to: order.statusId };
        
        // Если статус изменился на отгруженный, устанавливаем дату отгрузки
        if (order.statusId === 3) { // Предполагаемый ID для статуса "Отгружен"
          fields.push(`ShippedAt = CURRENT_TIMESTAMP`);
        }
        
        // Если статус изменился на доставленный, устанавливаем дату доставки
        if (order.statusId === 4) { // Предполагаемый ID для статуса "Доставлен"
          fields.push(`DeliveredAt = CURRENT_TIMESTAMP`);
        }
      }

      if (order.customerId !== undefined) {
        fields.push(`CustomerId = $${paramIndex++}`);
        values.push(order.customerId);
        changes.customerId = { from: currentOrder.customerid, to: order.customerId };
      }

      if (order.customerName !== undefined) {
        fields.push(`CustomerName = $${paramIndex++}`);
        values.push(order.customerName);
        changes.customerName = { from: currentOrder.customername, to: order.customerName };
      }

      if (order.customerPhone !== undefined) {
        fields.push(`CustomerPhone = $${paramIndex++}`);
        values.push(order.customerPhone);
        changes.customerPhone = { from: currentOrder.customerphone, to: order.customerPhone };
      }

      if (order.customerEmail !== undefined) {
        fields.push(`CustomerEmail = $${paramIndex++}`);
        values.push(order.customerEmail);
        changes.customerEmail = { from: currentOrder.customeremail, to: order.customerEmail };
      }

      if (order.shippingAddress !== undefined) {
        fields.push(`ShippingAddress = $${paramIndex++}`);
        values.push(order.shippingAddress);
        changes.shippingAddress = { from: currentOrder.shippingaddress, to: order.shippingAddress };
      }

      if (order.totalAmount !== undefined) {
        fields.push(`TotalAmount = $${paramIndex++}`);
        values.push(order.totalAmount);
        changes.totalAmount = { from: currentOrder.totalamount, to: order.totalAmount };
      }

      if (order.notes !== undefined) {
        fields.push(`Notes = $${paramIndex++}`);
        values.push(order.notes);
        changes.notes = { from: currentOrder.notes, to: order.notes };
      }

      if (order.warehouseId !== undefined) {
        fields.push(`WarehouseId = $${paramIndex++}`);
        values.push(order.warehouseId);
        changes.warehouseId = { from: currentOrder.warehouseid, to: order.warehouseId };
      }

      if (order.assignedTo !== undefined) {
        fields.push(`AssignedTo = $${paramIndex++}`);
        values.push(order.assignedTo);
        changes.assignedTo = { from: currentOrder.assignedto, to: order.assignedTo };
      }

      // Всегда обновляем дату обновления
      fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      // Если нет полей для обновления, возвращаем текущий заказ
      if (fields.length === 0) {
        return currentOrder;
      }

      // Обновляем заказ
      const sql = `
        UPDATE Orders
        SET ${fields.join(', ')}
        WHERE OrderId = $${paramIndex}
        RETURNING *
      `;
      values.push(orderId);

      const result = await client.query(sql, values);

      // Записываем событие обновления заказа
      if (Object.keys(changes).length > 0) {
        const eventSql = `
          INSERT INTO OrderEvents (
            OrderId, UserId, EventType, Details
          ) VALUES (
            $1, $2, 'UPDATE', $3
          )
        `;

        await client.query(eventSql, [
          orderId,
          userId,
          JSON.stringify(changes)
        ]);
      }

      return result.rows[0];
    });
  }

  // Получение элементов заказа
  static async getOrderItems(orderId: number): Promise<OrderItem[]> {
    const sql = `
      SELECT oi.*, 
        p.Name AS ProductName,
        p.SKU AS ProductSKU,
        p.Barcode AS ProductBarcode,
        s.Name AS StatusName,
        s.Color AS StatusColor
      FROM OrderItems oi
      LEFT JOIN Products p ON oi.ProductId = p.ProductId
      LEFT JOIN OrderStatuses s ON oi.StatusId = s.StatusId
      WHERE oi.OrderId = $1
      ORDER BY oi.OrderItemId
    `;
    const result = await this.query<OrderItem>(sql, [orderId]);
    return result.rows;
  }

  // Добавление элемента в заказ
  static async addOrderItem(orderItem: OrderItem, userId: number): Promise<OrderItem> {
    return this.transaction(async (client) => {
      // Создаем элемент заказа
      const sql = `
        INSERT INTO OrderItems (
          OrderId, ProductId, Quantity, Price, StatusId, Notes
        ) VALUES (
          $1, $2, $3, $4, $5, $6
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        orderItem.orderId,
        orderItem.productId,
        orderItem.quantity,
        orderItem.price || 0,
        orderItem.statusId,
        orderItem.notes || null
      ]);
      
      // Обновляем общую сумму заказа
      await client.query(`
        UPDATE Orders
        SET TotalAmount = (
          SELECT SUM(Quantity * COALESCE(Price, 0))
          FROM OrderItems
          WHERE OrderId = $1
        ),
        UpdatedAt = CURRENT_TIMESTAMP
        WHERE OrderId = $1
      `, [orderItem.orderId]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO OrderEvents (
          OrderId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'ADD_ITEM', $3
        )
      `;
      
      await client.query(eventSql, [
        orderItem.orderId,
        userId,
        JSON.stringify({ 
          orderItemId: result.rows[0].orderitemid,
          productId: orderItem.productId,
          quantity: orderItem.quantity,
          price: orderItem.price
        })
      ]);
      
      return result.rows[0];
    });
  }

  // Обновление элемента заказа
  static async updateOrderItem(
    orderItemId: number, 
    orderItem: Partial<OrderItem>, 
    userId: number
  ): Promise<OrderItem | null> {
    return this.transaction(async (client) => {
      // Получаем текущий элемент
      const currentResult = await client.query(`
        SELECT * FROM OrderItems WHERE OrderItemId = $1
      `, [orderItemId]);
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentItem = currentResult.rows[0];
      
      // Собираем поля для обновления
      const fields: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;
      const changes: any = {};

      if (orderItem.quantity !== undefined) {
        fields.push(`Quantity = $${paramIndex++}`);
        values.push(orderItem.quantity);
        changes.quantity = { from: currentItem.quantity, to: orderItem.quantity };
      }

      if (orderItem.price !== undefined) {
        fields.push(`Price = $${paramIndex++}`);
        values.push(orderItem.price);
        changes.price = { from: currentItem.price, to: orderItem.price };
      }

      if (orderItem.statusId !== undefined) {
        fields.push(`StatusId = $${paramIndex++}`);
        values.push(orderItem.statusId);
        changes.statusId = { from: currentItem.statusid, to: orderItem.statusId };
      }

      if (orderItem.notes !== undefined) {
        fields.push(`Notes = $${paramIndex++}`);
        values.push(orderItem.notes);
        changes.notes = { from: currentItem.notes, to: orderItem.notes };
      }

      // Всегда обновляем дату обновления
      fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      // Если нет полей для обновления, возвращаем текущий элемент
      if (fields.length === 0) {
        return currentItem;
      }

      // Обновляем элемент
      const sql = `
        UPDATE OrderItems
        SET ${fields.join(', ')}
        WHERE OrderItemId = $${paramIndex}
        RETURNING *
      `;
      values.push(orderItemId);

      const result = await client.query(sql, values);

      // Обновляем общую сумму заказа
      await client.query(`
        UPDATE Orders
        SET TotalAmount = (
          SELECT SUM(Quantity * COALESCE(Price, 0))
          FROM OrderItems
          WHERE OrderId = $1
        ),
        UpdatedAt = CURRENT_TIMESTAMP
        WHERE OrderId = $1
      `, [currentItem.orderid]);

      // Записываем событие обновления
      if (Object.keys(changes).length > 0) {
        const eventSql = `
          INSERT INTO OrderEvents (
            OrderId, UserId, EventType, Details
          ) VALUES (
            $1, $2, 'UPDATE_ITEM', $3
          )
        `;

        await client.query(eventSql, [
          currentItem.orderid,
          userId,
          JSON.stringify({
            orderItemId,
            ...changes
          })
        ]);
      }

      return result.rows[0];
    });
  }

  // Удаление элемента заказа
  static async deleteOrderItem(orderItemId: number, userId: number): Promise<boolean> {
    return this.transaction(async (client) => {
      // Получаем информацию об элементе
      const itemResult = await client.query(`
        SELECT * FROM OrderItems WHERE OrderItemId = $1
      `, [orderItemId]);
      
      if (!itemResult.rows.length) {
        return false;
      }
      
      const item = itemResult.rows[0];
      
      // Удаляем элемент
      const sql = `
        DELETE FROM OrderItems
        WHERE OrderItemId = $1
      `;
      
      await client.query(sql, [orderItemId]);
      
      // Обновляем общую сумму заказа
      await client.query(`
        UPDATE Orders
        SET TotalAmount = COALESCE((
          SELECT SUM(Quantity * COALESCE(Price, 0))
          FROM OrderItems
          WHERE OrderId = $1
        ), 0),
        UpdatedAt = CURRENT_TIMESTAMP
        WHERE OrderId = $1
      `, [item.orderid]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO OrderEvents (
          OrderId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'DELETE_ITEM', $3
        )
      `;
      
      await client.query(eventSql, [
        item.orderid,
        userId,
        JSON.stringify({ 
          orderItemId,
          productId: item.productid,
          quantity: item.quantity,
          price: item.price
        })
      ]);
      
      return true;
    });
  }

  // Получение истории событий заказа
  static async getOrderEvents(orderId: number): Promise<OrderEvent[]> {
    const sql = `
      SELECT oe.*,
        u.FirstName,
        u.LastName
      FROM OrderEvents oe
      LEFT JOIN Users u ON oe.UserId = u.UserId
      WHERE oe.OrderId = $1
      ORDER BY oe.CreatedAt DESC
    `;
    const result = await this.query<OrderEvent>(sql, [orderId]);
    return result.rows;
  }

  // Получение детальной информации о заказе
  static async getOrderDetails(orderId: number): Promise<any> {
    return this.transaction(async (client) => {
      // Получаем основную информацию о заказе
      const orderResult = await client.query(`
        SELECT o.*, 
          os.Name as SourceName,
          st.Name as StatusName,
          st.Color as StatusColor,
          w.Name as WarehouseName,
          u.FirstName as AssigneeFirstName,
          u.LastName as AssigneeLastName
        FROM Orders o
        LEFT JOIN OrderSources os ON o.SourceId = os.SourceId
        LEFT JOIN OrderStatuses st ON o.StatusId = st.StatusId
        LEFT JOIN Warehouses w ON o.WarehouseId = w.WarehouseId
        LEFT JOIN Users u ON o.AssignedTo = u.UserId
        WHERE o.OrderId = $1
      `, [orderId]);
      
      if (!orderResult.rows.length) {
        return null;
      }
      
      // Получаем элементы заказа
      const itemsResult = await client.query(`
        SELECT oi.*, 
          p.Name as ProductName,
          p.SKU as ProductSKU,
          p.Barcode as ProductBarcode,
          s.Name as StatusName,
          s.Color as StatusColor
        FROM OrderItems oi
        LEFT JOIN Products p ON oi.ProductId = p.ProductId
        LEFT JOIN OrderStatuses s ON oi.StatusId = s.StatusId
        WHERE oi.OrderId = $1
        ORDER BY oi.OrderItemId
      `, [orderId]);
      
      // Получаем события
      const eventsResult = await client.query(`
        SELECT oe.*,
          u.FirstName,
          u.LastName
        FROM OrderEvents oe
        LEFT JOIN Users u ON oe.UserId = u.UserId
        WHERE oe.OrderId = $1
        ORDER BY oe.CreatedAt DESC
      `, [orderId]);
      
      // Формируем результат
      return {
        order: orderResult.rows[0],
        items: itemsResult.rows,
        events: eventsResult.rows
      };
    });
  }
} 