import { Request, Response } from 'express';
import { RequestModel, Request as RequestEntity, RequestItem, RequestComment } from '../models/request.model';
import logger from '../utils/logger';

// Получение списка реквестов с поддержкой фильтрации и пагинации
export const getRequests = async (req: Request, res: Response) => {
  try {
    const { 
      enterpriseId, 
      statusId, 
      requestTypeId, 
      createdBy, 
      assignedTo, 
      startDate, 
      endDate, 
      search,
      sortField,
      sortDirection,
      page, 
      pageSize 
    } = req.query;

    // Проверка наличия обязательного параметра enterpriseId
    if (!enterpriseId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Параметр enterpriseId обязателен' 
      });
    }

    // Формирование параметров запроса
    const filters = {
      statusId: statusId ? Number(statusId) : undefined,
      requestTypeId: requestTypeId ? Number(requestTypeId) : undefined,
      createdBy: createdBy ? Number(createdBy) : undefined,
      assignedTo: assignedTo ? Number(assignedTo) : undefined,
      startDate: startDate ? new Date(startDate as string) : undefined,
      endDate: endDate ? new Date(endDate as string) : undefined,
      search: search as string | undefined
    };

    const sort = {
      field: sortField as 'createdAt' | 'updatedAt' | 'priority' | 'estimatedCompletionDate' | undefined,
      direction: sortDirection as 'ASC' | 'DESC' | undefined
    };

    const pagination = {
      page: page ? Number(page) : 1,
      pageSize: pageSize ? Number(pageSize) : 20
    };

    // Получение данных из модели
    const result = await RequestModel.getByEnterpriseId(
      Number(enterpriseId),
      filters,
      sort,
      pagination
    );

    // Отправка успешного ответа
    res.json({ 
      success: true, 
      data: result.requests, 
      total: result.total,
      page: pagination.page,
      pageSize: pagination.pageSize
    });

  } catch (error) {
    logger.error('Ошибка при получении списка реквестов', { error });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении списка реквестов' 
    });
  }
};

// Получение реквеста по ID
export const getRequestById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID реквеста не указан' 
      });
    }
    
    const request = await RequestModel.getById(Number(id));
    
    if (!request) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден' 
      });
    }
    
    res.json({ 
      success: true, 
      data: request 
    });
    
  } catch (error) {
    logger.error('Ошибка при получении реквеста', { error, requestId: req.params.id });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении реквеста' 
    });
  }
};

// Создание нового реквеста
export const createRequest = async (req: Request, res: Response) => {
  try {
    const requestData: RequestEntity = req.body;
    
    // Валидация данных
    if (!requestData.enterpriseId || !requestData.requestTypeId || 
        !requestData.title || !requestData.statusId || !requestData.createdBy) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    // Создание реквеста
    const newRequest = await RequestModel.create(requestData);
    
    res.status(201).json({ 
      success: true, 
      data: newRequest 
    });
    
  } catch (error) {
    logger.error('Ошибка при создании реквеста', { error, requestData: req.body });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при создании реквеста' 
    });
  }
};

// Обновление реквеста
export const updateRequest = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const requestData: Partial<RequestEntity> = req.body;
    const userId = req.body.userId || req.query.userId;
    
    if (!id) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID реквеста не указан' 
      });
    }
    
    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID пользователя не указан' 
      });
    }
    
    const updatedRequest = await RequestModel.update(
      Number(id), 
      requestData, 
      Number(userId)
    );
    
    if (!updatedRequest) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден' 
      });
    }
    
    res.json({ 
      success: true, 
      data: updatedRequest 
    });
    
  } catch (error) {
    logger.error('Ошибка при обновлении реквеста', { error, requestId: req.params.id, data: req.body });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при обновлении реквеста' 
    });
  }
};

// Изменение статуса реквеста
export const updateRequestStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { statusId, userId, comment } = req.body;
    
    if (!id || !statusId || !userId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    // Обновление статуса реквеста
    const updatedRequest = await RequestModel.updateStatus(
      Number(id), 
      Number(statusId), 
      Number(userId), 
      comment
    );
    
    if (!updatedRequest) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден' 
      });
    }
    
    res.json({ 
      success: true, 
      data: updatedRequest 
    });
    
  } catch (error) {
    logger.error('Ошибка при изменении статуса реквеста', { 
      error, 
      requestId: req.params.id, 
      statusId: req.body.statusId 
    });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при изменении статуса реквеста' 
    });
  }
};

// Добавление комментария к реквесту
export const addComment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { userId, comment } = req.body;
    
    if (!id || !userId || !comment) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const commentData: RequestComment = {
      requestId: Number(id),
      userId: Number(userId),
      comment
    };
    
    const result = await RequestModel.addComment(commentData);
    
    if (!result) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден или ошибка при добавлении комментария' 
      });
    }
    
    res.status(201).json({ 
      success: true, 
      data: result 
    });
    
  } catch (error) {
    logger.error('Ошибка при добавлении комментария', { 
      error, 
      requestId: req.params.id, 
      userId: req.body.userId 
    });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при добавлении комментария' 
    });
  }
};

// Получение комментариев к реквесту
export const getComments = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID реквеста не указан' 
      });
    }
    
    const comments = await RequestModel.getComments(Number(id));
    
    res.json({ 
      success: true, 
      data: comments 
    });
    
  } catch (error) {
    logger.error('Ошибка при получении комментариев', { error, requestId: req.params.id });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении комментариев' 
    });
  }
};

// Добавление элемента реквеста
export const addRequestItem = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const itemData: Omit<RequestItem, 'requestId'> = req.body;
    
    if (!id || !itemData.productId || !itemData.quantity || !itemData.statusId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const item: RequestItem = {
      ...itemData,
      requestId: Number(id)
    };
    
    const result = await RequestModel.addRequestItem(item);
    
    if (!result) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден или ошибка при добавлении элемента' 
      });
    }
    
    res.status(201).json({ 
      success: true, 
      data: result 
    });
    
  } catch (error) {
    logger.error('Ошибка при добавлении элемента реквеста', { 
      error, 
      requestId: req.params.id, 
      itemData: req.body 
    });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при добавлении элемента реквеста' 
    });
  }
};

// Получение элементов реквеста
export const getRequestItems = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID реквеста не указан' 
      });
    }
    
    const items = await RequestModel.getRequestItems(Number(id));
    
    res.json({ 
      success: true, 
      data: items 
    });
    
  } catch (error) {
    logger.error('Ошибка при получении элементов реквеста', { error, requestId: req.params.id });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении элементов реквеста' 
    });
  }
};

// Получение истории реквеста
export const getRequestHistory = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false, 
        error: 'ID реквеста не указан' 
      });
    }
    
    const history = await RequestModel.getRequestEvents(Number(id));
    
    res.json({ 
      success: true, 
      data: history 
    });
    
  } catch (error) {
    logger.error('Ошибка при получении истории реквеста', { error, requestId: req.params.id });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении истории реквеста' 
    });
  }
};

// Назначение исполнителя для реквеста
export const assignRequest = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { assignedTo, userId } = req.body;
    
    if (!id || !assignedTo || !userId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const result = await RequestModel.assignRequest(
      Number(id), 
      Number(assignedTo), 
      Number(userId)
    );
    
    if (!result) {
      return res.status(404).json({ 
        success: false, 
        error: 'Реквест не найден' 
      });
    }
    
    res.json({ 
      success: true, 
      data: result 
    });
    
  } catch (error) {
    logger.error('Ошибка при назначении исполнителя', { 
      error, 
      requestId: req.params.id, 
      assignedTo: req.body.assignedTo 
    });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при назначении исполнителя' 
    });
  }
};

// Получение типов реквестов
export const getRequestTypes = async (req: Request, res: Response) => {
  try {
    logger.info('Получение типов запросов', {});
    
    const types = await RequestModel.getRequestTypes();
    return res.json({ types });
  } catch (error) {
    logger.error('Ошибка при получении типов запросов', { error });
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Получение статусов реквестов
export const getRequestStatuses = async (req: Request, res: Response) => {
  try {
    const statuses = await RequestModel.getRequestStatuses();
    
    res.json({ 
      success: true, 
      data: statuses 
    });
    
  } catch (error) {
    logger.error('Ошибка при получении статусов реквестов', { error });
    res.status(500).json({ 
      success: false, 
      error: 'Ошибка при получении статусов реквестов' 
    });
  }
}; 