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
    const sql = 'SELECT * FROM RequestTypes WHERE IsActive = TRUE ORDER BY Name';
    const result = await this.query<RequestType>(sql);
    return result.rows;
  }

  // Получение статусов запросов
  static async getRequestStatuses(): Promise<RequestStatus[]> {
    const sql = 'SELECT * FROM RequestStatuses WHERE IsActive = TRUE ORDER BY DisplayOrder';
    const result = await this.query<RequestStatus>(sql);
    return result.rows;
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

  // Получение запроса по ID
  static async getById(requestId: number): Promise<Request | null> {
    const sql = `
      SELECT * FROM Requests
      WHERE RequestId = $1
    `;
    const result = await this.query<Request>(sql, [requestId]);
    return result.rows.length ? result.rows[0] : null;
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
        JSON.stringify({
          requestTypeId: request.requestTypeId,
          statusId: request.statusId
        })
      ]);

      return result.rows[0];
    });
  }

  // Обновление запроса
  static async update(requestId: number, data: Partial<Request>, userId: number): Promise<Request | null> {
    return this.transaction(async (client) => {
      // Получаем текущее состояние запроса
      const currentResult = await client.query(
        'SELECT * FROM Requests WHERE RequestId = $1',
        [requestId]
      );

      if (!currentResult.rows.length) {
        return null;
      }

      const currentRequest = currentResult.rows[0];

      // Формируем SQL для обновления
      const updates: string[] = [];
      const values: any[] = [];
      let valueIndex = 1;

      if (data.title !== undefined) {
        updates.push(`Title = $${valueIndex++}`);
        values.push(data.title);
      }

      if (data.description !== undefined) {
        updates.push(`Description = $${valueIndex++}`);
        values.push(data.description);
      }

      if (data.requestTypeId !== undefined) {
        updates.push(`RequestTypeId = $${valueIndex++}`);
        values.push(data.requestTypeId);
      }

      if (data.statusId !== undefined) {
        updates.push(`StatusId = $${valueIndex++}`);
        values.push(data.statusId);
      }

      if (data.priority !== undefined) {
        updates.push(`Priority = $${valueIndex++}`);
        values.push(data.priority);
      }

      if (data.estimatedCompletionDate !== undefined) {
        updates.push(`EstimatedCompletionDate = $${valueIndex++}`);
        values.push(data.estimatedCompletionDate);
      }

      if (data.assignedTo !== undefined) {
        updates.push(`AssignedTo = $${valueIndex++}`);
        values.push(data.assignedTo);
      }

      if (data.completedAt !== undefined) {
        updates.push(`CompletedAt = $${valueIndex++}`);
        values.push(data.completedAt);
      }

      // Всегда обновляем дату изменения
      updates.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      // Если нет изменений, возвращаем текущее состояние
      if (updates.length === 1) {
        return currentRequest;
      }

      // Выполняем обновление
      const sql = `
        UPDATE Requests
        SET ${updates.join(', ')}
        WHERE RequestId = $${valueIndex++}
        RETURNING *
      `;

      values.push(requestId);
      const result = await client.query(sql, values);

      // Записываем событие обновления
      const changes: any = {};
      if (data.title !== undefined && data.title !== currentRequest.title) {
        changes.title = { from: currentRequest.title, to: data.title };
      }
      if (data.description !== undefined && data.description !== currentRequest.description) {
        changes.description = { from: currentRequest.description, to: data.description };
      }
      if (data.requestTypeId !== undefined && data.requestTypeId !== currentRequest.requesttypeid) {
        changes.requestTypeId = { from: currentRequest.requesttypeid, to: data.requestTypeId };
      }
      if (data.statusId !== undefined && data.statusId !== currentRequest.statusid) {
        changes.statusId = { from: currentRequest.statusid, to: data.statusId };
      }
      if (data.priority !== undefined && data.priority !== currentRequest.priority) {
        changes.priority = { from: currentRequest.priority, to: data.priority };
      }
      if (data.estimatedCompletionDate !== undefined && 
          data.estimatedCompletionDate !== currentRequest.estimatedcompletiondate) {
        changes.estimatedCompletionDate = { 
          from: currentRequest.estimatedcompletiondate, 
          to: data.estimatedCompletionDate 
        };
      }
      if (data.assignedTo !== undefined && data.assignedTo !== currentRequest.assignedto) {
        changes.assignedTo = { from: currentRequest.assignedto, to: data.assignedTo };
      }
      if (data.completedAt !== undefined && data.completedAt !== currentRequest.completedat) {
        changes.completedAt = { from: currentRequest.completedat, to: data.completedAt };
      }

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

      return result.rows[0];
    });
  }

  // Обновление статуса запроса
  static async updateStatus(
    requestId: number, 
    statusId: number, 
    userId: number, 
    comment?: string
  ): Promise<Request | null> {
    return this.transaction(async (client) => {
      // Получаем текущее состояние запроса
      const currentResult = await client.query(
        'SELECT * FROM Requests WHERE RequestId = $1',
        [requestId]
      );

      if (!currentResult.rows.length) {
        return null;
      }

      const currentRequest = currentResult.rows[0];
      const currentStatusId = currentRequest.statusid;

      // Если статус не изменился, просто возвращаем запрос
      if (currentStatusId === statusId) {
        return currentRequest;
      }

      // Обновляем статус
      const sql = `
        UPDATE Requests
        SET StatusId = $1, UpdatedAt = CURRENT_TIMESTAMP,
            CompletedAt = CASE WHEN 
              (SELECT IsCompletedStatus FROM RequestStatuses WHERE StatusId = $1) = TRUE 
              THEN CURRENT_TIMESTAMP ELSE CompletedAt END
        WHERE RequestId = $2
        RETURNING *
      `;

      const result = await client.query(sql, [statusId, requestId]);

      // Записываем событие изменения статуса
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'STATUS_CHANGE', $3
        )
      `;

      await client.query(eventSql, [
        requestId,
        userId,
        JSON.stringify({
          from: currentStatusId,
          to: statusId,
          comment: comment
        })
      ]);

      // Если передан комментарий, добавляем его
      if (comment) {
        const commentSql = `
          INSERT INTO RequestComments (
            RequestId, UserId, Comment
          ) VALUES (
            $1, $2, $3
          )
        `;
        await client.query(commentSql, [requestId, userId, comment]);
      }

      return result.rows[0];
    });
  }

  // Добавление элемента запроса
  static async addRequestItem(item: RequestItem): Promise<RequestItem> {
    return this.transaction(async (client) => {
      // Проверяем существование запроса
      const checkSql = `SELECT * FROM Requests WHERE RequestId = $1`;
      const checkResult = await client.query(checkSql, [item.requestId]);
      
      if (!checkResult.rows.length) {
        throw new Error(`Request with ID ${item.requestId} not found`);
      }
      
      // Создаем элемент запроса
      const sql = `
        INSERT INTO RequestItems (
          RequestId, ProductId, Quantity, StatusId, Comment
        ) VALUES (
          $1, $2, $3, $4, $5
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        item.requestId,
        item.productId,
        item.quantity,
        item.statusId,
        item.comment || null
      ]);
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, 
          (SELECT CreatedBy FROM Requests WHERE RequestId = $1),
          'ITEM_ADD',
          $2
        )
      `;
      
      await client.query(eventSql, [
        item.requestId,
        JSON.stringify({
          requestItemId: result.rows[0].requestitemid,
          productId: item.productId,
          quantity: item.quantity
        })
      ]);
      
      return result.rows[0];
    });
  }

  // Добавление комментария
  static async addComment(comment: RequestComment): Promise<RequestComment> {
    return this.transaction(async (client) => {
      // Проверяем существование запроса
      const checkSql = `SELECT * FROM Requests WHERE RequestId = $1`;
      const checkResult = await client.query(checkSql, [comment.requestId]);
      
      if (!checkResult.rows.length) {
        throw new Error(`Request with ID ${comment.requestId} not found`);
      }
      
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
      
      // Записываем событие
      const eventSql = `
        INSERT INTO RequestEvents (
          RequestId, UserId, EventType, Details
        ) VALUES (
          $1, $2, 'COMMENT_ADD', $3
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

  // Назначение исполнителя запроса
  static async assignRequest(requestId: number, assignedTo: number, userId: number): Promise<Request | null> {
    return this.transaction(async (client) => {
      // Получаем текущий реквест
      const currentResult = await client.query(
        `SELECT * FROM Requests WHERE RequestId = $1`,
        [requestId]
      );
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentRequest = currentResult.rows[0];
      
      // Обновляем исполнителя
      const sql = `
        UPDATE Requests
        SET AssignedTo = $1, UpdatedAt = CURRENT_TIMESTAMP
        WHERE RequestId = $2
        RETURNING *
      `;
      
      const result = await client.query(sql, [assignedTo, requestId]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      // Записываем событие
      await client.query(
        `INSERT INTO RequestEvents 
          (RequestId, UserId, EventType, Details) 
        VALUES 
          ($1, $2, 'ASSIGN', $3)`,
        [
          requestId, 
          userId, 
          JSON.stringify({
            oldAssignee: currentRequest.assignedto,
            newAssignee: assignedTo
          })
        ]
      );
      
      return result.rows[0];
    });
  }

  // Получение комментариев к реквесту
  static async getComments(requestId: number): Promise<RequestComment[]> {
    const sql = `
      SELECT 
        RC.CommentId,
        RC.RequestId,
        RC.UserId,
        RC.Comment,
        RC.CreatedAt,
        U.UserName,
        U.Email
      FROM RequestComments RC
      LEFT JOIN Users U ON RC.UserId = U.UserId
      WHERE RC.RequestId = $1
      ORDER BY RC.CreatedAt DESC
    `;
    
    const result = await this.query<RequestComment & { username: string; email: string }>(sql, [requestId]);
    return result.rows;
  }

  // Получение элементов реквеста
  static async getRequestItems(requestId: number): Promise<RequestItem[]> {
    const sql = `
      SELECT 
        RI.*,
        P.Name AS ProductName,
        P.SKU,
        P.Description AS ProductDescription
      FROM RequestItems RI
      LEFT JOIN Products P ON RI.ProductId = P.ProductId
      WHERE RI.RequestId = $1
      ORDER BY RI.RequestItemId
    `;
    
    const result = await this.query<RequestItem & { productname: string; sku: string; productdescription: string }>(sql, [requestId]);
    return result.rows;
  }

  // Получение событий реквеста
  static async getRequestEvents(requestId: number): Promise<RequestEvent[]> {
    const sql = `
      SELECT 
        RE.*,
        U.UserName,
        U.Email
      FROM RequestEvents RE
      LEFT JOIN Users U ON RE.UserId = U.UserId
      WHERE RE.RequestId = $1
      ORDER BY RE.CreatedAt DESC
    `;
    
    const result = await this.query<RequestEvent & { username: string; email: string }>(sql, [requestId]);
    return result.rows;
  }
} 