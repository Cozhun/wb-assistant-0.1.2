/**
 * Контроллер для управления запросами
 */
import { RequestModel } from '../models/request.model.js';
import logger from '../utils/logger.js';

// Получение списка реквестов с поддержкой фильтрации и пагинации
export const getRequests = async (req, res) => {
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
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      search
    };

    const sort = {
      field: sortField || 'createdAt',
      direction: sortDirection || 'DESC'
    };

    const pagination = {
      page: page ? Number(page) : 1,
      pageSize: pageSize ? Number(pageSize) : 10
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
export const getRequestById = async (req, res) => {
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
export const createRequest = async (req, res) => {
  try {
    const requestData = req.body;
    
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
export const updateRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const requestData = req.body;
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
export const updateRequestStatus = async (req, res) => {
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

// Отмена реквеста
export const cancelRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    // Проверка существования запроса
    const existingRequest = await RequestModel.getById(Number(id));
    if (!existingRequest) {
      return res.status(404).json({ error: 'Запрос не найден' });
    }
    
    // Проверка возможности отмены
    if (existingRequest.status === 'COMPLETED' || existingRequest.status === 'CANCELLED') {
      return res.status(400).json({ 
        error: 'Невозможно отменить завершенный или уже отмененный запрос' 
      });
    }
    
    const cancelledRequest = await RequestModel.cancelRequest(id, {
      cancelledBy: req.user?.userId,
      cancelReason: reason
    });
    
    return res.json(cancelledRequest);
  } catch (error) {
    logger.error(`Ошибка при отмене запроса с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Завершение реквеста
export const completeRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    
    // Проверка существования запроса
    const existingRequest = await RequestModel.getById(Number(id));
    if (!existingRequest) {
      return res.status(404).json({ error: 'Запрос не найден' });
    }
    
    // Проверка возможности завершения
    if (existingRequest.status === 'COMPLETED' || existingRequest.status === 'CANCELLED') {
      return res.status(400).json({ 
        error: 'Невозможно завершить уже завершенный или отмененный запрос' 
      });
    }
    
    const completedRequest = await RequestModel.completeRequest(id, {
      completedBy: req.user?.userId,
      notes
    });
    
    return res.json(completedRequest);
  } catch (error) {
    logger.error(`Ошибка при завершении запроса с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Добавление комментария к реквесту
export const addComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, comment } = req.body;
    
    if (!id || !userId || !comment) {
      return res.status(400).json({ 
        success: false,
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const commentData = {
      requestId: Number(id),
      userId: Number(userId),
      comment
    };
    
    const newComment = await RequestModel.addComment(commentData);
    
    res.status(201).json({ 
      success: true,
      data: newComment
    });
    
  } catch (error) {
    logger.error('Ошибка при добавлении комментария', { 
      error, 
      requestId: req.params.id 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при добавлении комментария' 
    });
  }
};

// Получение комментариев реквеста
export const getComments = async (req, res) => {
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
    logger.error('Ошибка при получении комментариев', { 
      error, 
      requestId: req.params.id 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при получении комментариев' 
    });
  }
};

// Добавление элемента к реквесту
export const addRequestItem = async (req, res) => {
  try {
    const { id } = req.params;
    const itemData = req.body;
    
    if (!id || !itemData.productId || !itemData.quantity) {
      return res.status(400).json({ 
        success: false,
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const newItem = await RequestModel.addItem(
      Number(id), 
      {
        ...itemData,
        productId: Number(itemData.productId),
        quantity: Number(itemData.quantity)
      }
    );
    
    res.status(201).json({ 
      success: true,
      data: newItem
    });
    
  } catch (error) {
    logger.error('Ошибка при добавлении элемента к реквесту', { 
      error, 
      requestId: req.params.id, 
      data: req.body 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при добавлении элемента к реквесту' 
    });
  }
};

// Получение элементов реквеста
export const getRequestItems = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false,
        error: 'ID реквеста не указан' 
      });
    }
    
    const items = await RequestModel.getItems(Number(id));
    
    res.json({ 
      success: true,
      data: items
    });
    
  } catch (error) {
    logger.error('Ошибка при получении элементов реквеста', { 
      error, 
      requestId: req.params.id 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при получении элементов реквеста' 
    });
  }
};

// Получение истории реквеста
export const getRequestHistory = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ 
        success: false,
        error: 'ID реквеста не указан' 
      });
    }
    
    const history = await RequestModel.getHistory(Number(id));
    
    res.json({ 
      success: true,
      data: history
    });
    
  } catch (error) {
    logger.error('Ошибка при получении истории реквеста', { 
      error, 
      requestId: req.params.id 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при получении истории реквеста' 
    });
  }
};

// Назначение реквеста исполнителю
export const assignRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { assignedTo, assignedBy } = req.body;
    
    if (!id || !assignedTo) {
      return res.status(400).json({ 
        success: false,
        error: 'Не все обязательные поля заполнены' 
      });
    }
    
    const updatedRequest = await RequestModel.assign(
      Number(id),
      Number(assignedTo),
      assignedBy ? Number(assignedBy) : undefined
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
    logger.error('Ошибка при назначении реквеста', { 
      error, 
      requestId: req.params.id, 
      assignedTo: req.body.assignedTo 
    });
    res.status(500).json({ 
      success: false,
      error: 'Ошибка при назначении реквеста' 
    });
  }
};

// Обновление элемента реквеста
export const updateRequestItem = async (req, res) => {
  try {
    const { id, itemId } = req.params;
    const { quantity, notes } = req.body;
    
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ error: 'Положительное количество обязательно' });
    }
    
    // Проверка существования запроса и товара
    const existingRequest = await RequestModel.getById(Number(id));
    if (!existingRequest) {
      return res.status(404).json({ error: 'Запрос не найден' });
    }
    
    const result = await RequestModel.updateItem(id, itemId, {
      quantity,
      notes,
      updatedBy: req.user?.userId
    });
    
    if (!result) {
      return res.status(404).json({ error: 'Товар в запросе не найден' });
    }
    
    return res.json(result);
  } catch (error) {
    logger.error(`Ошибка при обновлении товара в запросе:`, {
      requestId: req.params.id,
      itemId: req.params.itemId,
      error: error.message
    });
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Удаление элемента из реквеста
export const removeItemFromRequest = async (req, res) => {
  try {
    const { id, itemId } = req.params;
    
    // Проверка существования запроса
    const existingRequest = await RequestModel.getById(Number(id));
    if (!existingRequest) {
      return res.status(404).json({ error: 'Запрос не найден' });
    }
    
    const result = await RequestModel.removeItem(id, itemId, req.user?.userId);
    
    if (!result) {
      return res.status(404).json({ error: 'Товар в запросе не найден' });
    }
    
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении товара из запроса:`, {
      requestId: req.params.id,
      itemId: req.params.itemId,
      error: error.message
    });
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Получение типов реквестов
export const getRequestTypes = async (req, res) => {
  try {
    const types = await RequestModel.getRequestTypes();
    return res.json(types);
  } catch (error) {
    logger.error('Ошибка при получении типов запросов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Получение статусов реквестов
export const getRequestStatuses = async (req, res) => {
  try {
    const statuses = await RequestModel.getRequestStatuses();
    return res.json(statuses);
  } catch (error) {
    logger.error('Ошибка при получении статусов запросов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

// Получение запросов по ID предприятия
export const getRequestsByEnterpriseId = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const requests = await RequestModel.getRequestsByEnterpriseId(enterpriseId);
    return res.json(requests);
  } catch (error) {
    logger.error('Ошибка при получении запросов предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 
