import { BaseModel } from '.';

export interface RequestType {
  requestTypeId?: number;
  name: string;
  description?: string;
}

export interface RequestStatus {
  statusId?: number;
  name: string;
  description?: string;
  color?: string;
}

export interface Request {
  requestId?: number;
  enterpriseId: number;
  requestTypeId: number;
  requestNumber?: string;
  title: string;
  description?: string;
  statusId: number;
  createdBy: number;
  createdAt?: Date;
  updatedAt?: Date;
  completedAt?: Date;
  priority?: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  estimatedCompletionDate?: Date;
  assignedTo?: number;
}

export interface RequestItem {
  requestItemId?: number;
  requestId: number;
  productId: number;
  quantity: number;
  statusId: number;
  comment?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface RequestComment {
  commentId?: number;
  requestId: number;
  userId: number;
  comment: string;
  createdAt?: Date;
}

export interface RequestEvent {
  eventId?: number;
  requestId: number;
  userId: number;
  eventType: string;
  details: any;
  createdAt?: Date;
}

export class RequestModel extends BaseModel {
  // Получение типов запросов
  static async getRequestTypes(): Promise<RequestType[]> {
    const sql = `
      SELECT * FROM RequestTypes
      ORDER BY RequestTypeId
    `;
    const result = await this.query<RequestType>(sql);
    return result.rows;
  }

  // Получение статусов запросов
  static async getRequestStatuses(): Promise<RequestStatus[]> {
    const sql = `
      SELECT * FROM RequestStatuses
      ORDER BY StatusId
    `;
    const result = await this.query<RequestStatus>(sql);
    return result.rows;
  }

  // Получение запроса по ID
  static async getById(requestId: number): Promise<Request | null> {
    const sql = `
      SELECT * FROM Requests
      WHERE RequestId = $1
    `;
    const result = await this.query<Request>(sql, [requestId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение списка запросов по предприятию
  static async getByEnterpriseId(
    enterpriseId: number,
    filters: {
      statusId?: number;
      requestTypeId?: number;
      createdBy?: number;
      assignedTo?: number;
      startDate?: Date;
      endDate?: Date;
      search?: string;
    } = {},
    sort: {
      field?: 'createdAt' | 'updatedAt' | 'priority' | 'estimatedCompletionDate';
      direction?: 'ASC' | 'DESC';
    } = { field: 'createdAt', direction: 'DESC' },
    pagination: {
      page?: number;
      pageSize?: number;
    } = { page: 1, pageSize: 20 }
  ): Promise<{ requests: Request[]; total: number }> {
    // Собираем условия фильтрации
    const conditions: string[] = ['EnterpriseId = $1'];
    const params: any[] = [enterpriseId];
    let paramIndex = 2;

    if (filters.statusId !== undefined) {
      conditions.push(`StatusId = $${paramIndex++}`);
      params.push(filters.statusId);
    }

    if (filters.requestTypeId !== undefined) {
      conditions.push(`RequestTypeId = $${paramIndex++}`);
      params.push(filters.requestTypeId);
    }

    if (filters.createdBy !== undefined) {
      conditions.push(`CreatedBy = $${paramIndex++}`);
      params.push(filters.createdBy);
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
      conditions.push(`(Title ILIKE $${paramIndex} OR Description ILIKE $${paramIndex} OR RequestNumber ILIKE $${paramIndex})`);
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
      SELECT * FROM Requests
      ${where}
      ${orderBy}
      ${limit}
    `;

    const countSql = `
      SELECT COUNT(*) as total FROM Requests
      ${where}
    `;

    const result = await this.query<Request>(sql, params);
    
    // Убираем параметры пагинации для запроса подсчета
    params.pop();
    params.pop();
    const countResult = await this.query<{ total: string }>(countSql, params);

    return {
      requests: result.rows,
      total: parseInt(countResult.rows[0].total)
    };
  }

  // Вспомогательный метод для маппинга полей на столбцы БД
  private static mapFieldToColumn(field: string): string {
    const mapping: Record<string, string> = {
      'createdAt': 'CreatedAt',
      'updatedAt': 'UpdatedAt',
      'priority': 'Priority',
      'estimatedCompletionDate': 'EstimatedCompletionDate'
    };
    return mapping[field] || 'CreatedAt';
  }

  // Создание нового запроса
  static async create(request: Request): Promise<Request> {
    return this.transaction(async (client) => {
      // Генерируем номер запроса, если он не указан
      let requestNumber = request.requestNumber;
      if (!requestNumber) {
        const yearMonth = new Date().toISOString().slice(2, 7).replace('-', '');
        const counterResult = await client.query(`
          SELECT COUNT(*) + 1 as counter FROM Requests
          WHERE EnterpriseId = $1 AND CreatedAt >= date_trunc('month', CURRENT_DATE)
        `, [request.enterpriseId]);
        const counter = counterResult.rows[0].counter.toString().padStart(3, '0');
        requestNumber = `REQ-${yearMonth}-${counter}`;
      }

      // Создаем запрос
      const sql = `
        INSERT INTO Requests (
          EnterpriseId, RequestTypeId, RequestNumber, Title, Description, 
          StatusId, CreatedBy, Priority, EstimatedCompletionDate, AssignedTo
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
        ) RETURNING *
      `;

      const result = await client.query(sql, [
        request.enterpriseId,
        request.requestTypeId,
        requestNumber,
        request.title,
        request.description || null,
        request.statusId,
        request.createdBy,
        request.priority || 'NORMAL',
        request.estimatedCompletionDate || null,
        request.assignedTo || null
      ]);

      // Записываем событие создания запроса
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'CREATE', $3
        )
      `;

      await client.query(eventSql, [
        result.rows[0].requestid,
        request.createdBy,
        JSON.stringify({ statusId: request.statusId, message: 'Запрос создан' })
      ]);

      return result.rows[0];
    });
  }

  // Обновление запроса
  static async update(requestId: number, request: Partial<Request>, userId: number): Promise<Request | null> {
    return this.transaction(async (client) => {
      // Получаем текущий запрос
      const currentResult = await client.query(`
        SELECT * FROM Requests WHERE RequestId = $1
      `, [requestId]);
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentRequest = currentResult.rows[0];
      
      // Собираем поля для обновления
      const fields: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;
      const changes: any = {};

      if (request.requestTypeId !== undefined) {
        fields.push(`RequestTypeId = $${paramIndex++}`);
        values.push(request.requestTypeId);
        changes.requestTypeId = { from: currentRequest.requesttypeid, to: request.requestTypeId };
      }

      if (request.title !== undefined) {
        fields.push(`Title = $${paramIndex++}`);
        values.push(request.title);
        changes.title = { from: currentRequest.title, to: request.title };
      }

      if (request.description !== undefined) {
        fields.push(`Description = $${paramIndex++}`);
        values.push(request.description);
        changes.description = { from: currentRequest.description, to: request.description };
      }

      if (request.statusId !== undefined && request.statusId !== currentRequest.statusid) {
        fields.push(`StatusId = $${paramIndex++}`);
        values.push(request.statusId);
        changes.statusId = { from: currentRequest.statusid, to: request.statusId };
        
        // Если статус изменился на завершенный, устанавливаем дату завершения
        if ([3, 4, 5].includes(request.statusId)) { // Предполагаемые ID для завершенных статусов
          fields.push(`CompletedAt = CURRENT_TIMESTAMP`);
          changes.completedAt = { to: new Date() };
        }
      }

      if (request.priority !== undefined) {
        fields.push(`Priority = $${paramIndex++}`);
        values.push(request.priority);
        changes.priority = { from: currentRequest.priority, to: request.priority };
      }

      if (request.estimatedCompletionDate !== undefined) {
        fields.push(`EstimatedCompletionDate = $${paramIndex++}`);
        values.push(request.estimatedCompletionDate);
        changes.estimatedCompletionDate = { 
          from: currentRequest.estimatedcompletiondate, 
          to: request.estimatedCompletionDate 
        };
      }

      if (request.assignedTo !== undefined) {
        fields.push(`AssignedTo = $${paramIndex++}`);
        values.push(request.assignedTo);
        changes.assignedTo = { from: currentRequest.assignedto, to: request.assignedTo };
      }

      // Всегда обновляем дату обновления
      fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      // Если нет полей для обновления, возвращаем текущий запрос
      if (fields.length === 0) {
        return currentRequest;
      }

      // Обновляем запрос
      const sql = `
        UPDATE Requests
        SET ${fields.join(', ')}
        WHERE RequestId = $${paramIndex}
        RETURNING *
      `;
      values.push(requestId);

      const result = await client.query(sql, values);

      // Записываем событие обновления запроса
      if (Object.keys(changes).length > 0) {
        const eventSql = `
          INSERT INTO RequestEvents (
            RequestId, UserId, EventType, Details
          ) VALUES (
            $1, $2, 'UPDATE', $3
          )
        `;

        await client.query(eventSql, [
          requestId,
          userId,
          JSON.stringify(changes)
        ]);
      }

      return result.rows[0];
    });
  }

  // Назначение исполнителя запроса
  static async assignRequest(requestId: number, assignedTo: number, userId: number): Promise<boolean> {
    return this.transaction(async (client) => {
      // Проверяем существование запроса
      const checkSql = `
        SELECT AssignedTo FROM Requests WHERE RequestId = $1
      `;
      const checkResult = await client.query(checkSql, [requestId]);
      
      if (!checkResult.rows.length) {
        return false;
      }
      
      const currentAssignedTo = checkResult.rows[0].assignedto;
      
      // Обновляем запрос
      const sql = `
        UPDATE Requests
        SET AssignedTo = $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $2
      `;
      await client.query(sql, [assignedTo, requestId]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'ASSIGN', $3
        )
      `;
      
      await client.query(eventSql, [
        requestId,
        userId,
        JSON.stringify({ 
          assignedTo: { 
            from: currentAssignedTo, 
            to: assignedTo 
          } 
        })
      ]);
      
      return true;
    });
  }

  // Получение элементов запроса
  static async getRequestItems(requestId: number): Promise<RequestItem[]> {
    const sql = `
      SELECT * FROM RequestItems
      WHERE RequestId = $1
      ORDER BY RequestItemId
    `;
    const result = await this.query<RequestItem>(sql, [requestId]);
    return result.rows;
  }

  // Добавление элемента в запрос
  static async addRequestItem(requestItem: RequestItem, userId: number): Promise<RequestItem> {
    return this.transaction(async (client) => {
      // Создаем элемент запроса
      const sql = `
        INSERT INTO RequestItems (
          RequestId, ProductId, Quantity, StatusId, Comment
        ) VALUES (
          $1, $2, $3, $4, $5
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        requestItem.requestId,
        requestItem.productId,
        requestItem.quantity,
        requestItem.statusId,
        requestItem.comment || null
      ]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'ADD_ITEM', $3
        )
      `;
      
      await client.query(eventSql, [
        requestItem.requestId,
        userId,
        JSON.stringify({ 
          requestItemId: result.rows[0].requestitemid,
          productId: requestItem.productId,
          quantity: requestItem.quantity
        })
      ]);
      
      // Обновляем дату обновления запроса
      await client.query(`
        UPDATE Requests
        SET UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
      `, [requestItem.requestId]);
      
      return result.rows[0];
    });
  }

  // Обновление элемента запроса
  static async updateRequestItem(
    requestItemId: number, 
    requestItem: Partial<RequestItem>, 
    userId: number
  ): Promise<RequestItem | null> {
    return this.transaction(async (client) => {
      // Получаем текущий элемент
      const currentResult = await client.query(`
        SELECT * FROM RequestItems WHERE RequestItemId = $1
      `, [requestItemId]);
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentItem = currentResult.rows[0];
      
      // Собираем поля для обновления
      const fields: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;
      const changes: any = {};

      if (requestItem.quantity !== undefined) {
        fields.push(`Quantity = $${paramIndex++}`);
        values.push(requestItem.quantity);
        changes.quantity = { from: currentItem.quantity, to: requestItem.quantity };
      }

      if (requestItem.statusId !== undefined) {
        fields.push(`StatusId = $${paramIndex++}`);
        values.push(requestItem.statusId);
        changes.statusId = { from: currentItem.statusid, to: requestItem.statusId };
      }

      if (requestItem.comment !== undefined) {
        fields.push(`Comment = $${paramIndex++}`);
        values.push(requestItem.comment);
        changes.comment = { from: currentItem.comment, to: requestItem.comment };
      }

      // Всегда обновляем дату обновления
      fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      // Если нет полей для обновления, возвращаем текущий элемент
      if (fields.length === 0) {
        return currentItem;
      }

      // Обновляем элемент
      const sql = `
        UPDATE RequestItems
        SET ${fields.join(', ')}
        WHERE RequestItemId = $${paramIndex}
        RETURNING *
      `;
      values.push(requestItemId);

      const result = await client.query(sql, values);

      // Записываем событие обновления
      if (Object.keys(changes).length > 0) {
        const eventSql = `
          INSERT INTO RequestEvents (
            RequestId, UserId, EventType, Details
          ) VALUES (
            $1, $2, 'UPDATE_ITEM', $3
          )
        `;

        await client.query(eventSql, [
          currentItem.requestid,
          userId,
          JSON.stringify({
            requestItemId,
            ...changes
          })
        ]);
        
        // Обновляем дату обновления запроса
        await client.query(`
          UPDATE Requests
          SET UpdatedAt = CURRENT_TIMESTAMP
          WHERE RequestId = $1
        `, [currentItem.requestid]);
      }

      return result.rows[0];
    });
  }

  // Удаление элемента запроса
  static async deleteRequestItem(requestItemId: number, userId: number): Promise<boolean> {
    return this.transaction(async (client) => {
      // Получаем информацию об элементе
      const itemResult = await client.query(`
        SELECT * FROM RequestItems WHERE RequestItemId = $1
      `, [requestItemId]);
      
      if (!itemResult.rows.length) {
        return false;
      }
      
      const item = itemResult.rows[0];
      
      // Удаляем элемент
      const sql = `
        DELETE FROM RequestItems
        WHERE RequestItemId = $1
      `;
      
      await client.query(sql, [requestItemId]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'DELETE_ITEM', $3
        )
      `;
      
      await client.query(eventSql, [
        item.requestid,
        userId,
        JSON.stringify({ 
          requestItemId,
          productId: item.productid,
          quantity: item.quantity
        })
      ]);
      
      // Обновляем дату обновления запроса
      await client.query(`
        UPDATE Requests
        SET UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
      `, [item.requestid]);
      
      return true;
    });
  }

  // Добавление комментария к запросу
  static async addComment(comment: RequestComment): Promise<RequestComment> {
    return this.transaction(async (client) => {
      // Добавляем комментарий
      const sql = `
        INSERT INTO RequestComments (
          RequestId, UserId, Comment
        ) VALUES (
          $1, $2, $3
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        comment.requestId,
        comment.userId,
        comment.comment
      ]);
      
      // Обновляем дату обновления запроса
      await client.query(`
        UPDATE Requests
        SET UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $1
      `, [comment.requestId]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'ADD_COMMENT', $3
        )
      `;
      
      await client.query(eventSql, [
        comment.requestId,
        comment.userId,
        JSON.stringify({ 
          commentId: result.rows[0].commentid
        })
      ]);
      
      return result.rows[0];
    });
  }

  // Получение комментариев к запросу
  static async getComments(requestId: number): Promise<RequestComment[]> {
    const sql = `
      SELECT * FROM RequestComments
      WHERE RequestId = $1
      ORDER BY CreatedAt DESC
    `;
    const result = await this.query<RequestComment>(sql, [requestId]);
    return result.rows;
  }

  // Получение истории событий запроса
  static async getRequestEvents(requestId: number): Promise<RequestEvent[]> {
    const sql = `
      SELECT * FROM RequestEvents
      WHERE RequestId = $1
      ORDER BY CreatedAt DESC
    `;
    const result = await this.query<RequestEvent>(sql, [requestId]);
    return result.rows;
  }

  // Получение детальной информации о запросе
  static async getRequestDetails(requestId: number): Promise<any> {
    return this.transaction(async (client) => {
      // Получаем основную информацию о запросе
      const requestResult = await client.query(`
        SELECT r.*, 
          rt.Name as RequestTypeName,
          rs.Name as StatusName,
          rs.Color as StatusColor,
          uc.FirstName as CreatorFirstName,
          uc.LastName as CreatorLastName,
          ua.FirstName as AssigneeFirstName,
          ua.LastName as AssigneeLastName
        FROM Requests r
        LEFT JOIN RequestTypes rt ON r.RequestTypeId = rt.RequestTypeId
        LEFT JOIN RequestStatuses rs ON r.StatusId = rs.StatusId
        LEFT JOIN Users uc ON r.CreatedBy = uc.UserId
        LEFT JOIN Users ua ON r.AssignedTo = ua.UserId
        WHERE r.RequestId = $1
      `, [requestId]);
      
      if (!requestResult.rows.length) {
        return null;
      }
      
      // Получаем элементы запроса
      const itemsResult = await client.query(`
        SELECT ri.*, 
          p.Name as ProductName,
          p.SKU as ProductSKU,
          p.Barcode as ProductBarcode,
          rs.Name as StatusName,
          rs.Color as StatusColor
        FROM RequestItems ri
        LEFT JOIN Products p ON ri.ProductId = p.ProductId
        LEFT JOIN RequestStatuses rs ON ri.StatusId = rs.StatusId
        WHERE ri.RequestId = $1
        ORDER BY ri.RequestItemId
      `, [requestId]);
      
      // Получаем комментарии
      const commentsResult = await client.query(`
        SELECT rc.*,
          u.FirstName,
          u.LastName
        FROM RequestComments rc
        LEFT JOIN Users u ON rc.UserId = u.UserId
        WHERE rc.RequestId = $1
        ORDER BY rc.CreatedAt DESC
      `, [requestId]);
      
      // Получаем события
      const eventsResult = await client.query(`
        SELECT re.*,
          u.FirstName,
          u.LastName
        FROM RequestEvents re
        LEFT JOIN Users u ON re.UserId = u.UserId
        WHERE re.RequestId = $1
        ORDER BY re.CreatedAt DESC
      `, [requestId]);
      
      // Формируем результат
      return {
        request: requestResult.rows[0],
        items: itemsResult.rows,
        comments: commentsResult.rows,
        events: eventsResult.rows
      };
    });
  }
} 