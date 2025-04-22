import axios from 'axios';

// Базовый URL вашего API сервера
// Предполагается, что клиент и сервер работают на разных портах в режиме разработки,
// или что настроен прокси (например, в package.json или vite.config.js)
// В production сборке, это может быть относительный путь или полный URL
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api'; // Используем переменную окружения или относительный путь
const RETRY_COUNT = 3;

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

// Объект для хранения состояния токенов и запроса обновления
const tokenState = {
  isRefreshing: false,
  refreshPromise: null,
  failedQueue: [], // Очередь запросов, которые ждут обновления токена
  
  // Обработка запросов в очереди после обновления токена
  processQueue: (error, token = null) => {
    tokenState.failedQueue.forEach(prom => {
      if (error) {
        prom.reject(error);
      } else {
        prom.resolve(token);
      }
    });
    
    tokenState.failedQueue = [];
  }
};

// Функция для обновления токена
const refreshAuthToken = async () => {
  try {
    const refreshToken = localStorage.getItem('refreshToken');
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    
    const response = await axios.post(`${API_BASE_URL}/auth/refresh`, { refreshToken });
    const { token, refreshToken: newRefreshToken } = response.data;
    
    // Сохраняем новые токены
    localStorage.setItem('authToken', token);
    if (newRefreshToken) {
      localStorage.setItem('refreshToken', newRefreshToken);
    }
    
    return token;
  } catch (error) {
    // Удаляем токены при ошибке
    localStorage.removeItem('authToken');
    localStorage.removeItem('refreshToken');
    throw error;
  }
};

// Интерцептор для добавления токена аутентификации к каждому запросу
apiClient.interceptors.request.use(
  (config) => {
    // Получаем токен из localStorage (или другого хранилища)
    const token = localStorage.getItem('authToken'); // Настройте ключ хранения токена
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Интерцептор для обработки ответов (например, обработка ошибок 401 Unauthorized)
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    
    // Если запрос не отмечен как повторный и ошибка 401 (Unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (!tokenState.isRefreshing) {
        tokenState.isRefreshing = true;
        tokenState.refreshPromise = refreshAuthToken()
          .then(token => {
            tokenState.isRefreshing = false;
            tokenState.processQueue(null, token);
            return token;
          })
          .catch(err => {
            tokenState.isRefreshing = false;
            tokenState.processQueue(err);
            throw err;
          });
      }
      
      // Возвращаем промис, который либо будет выполнен после обновления токена,
      // либо отклонен, если обновление не удалось
      return new Promise((resolve, reject) => {
        tokenState.failedQueue.push({ resolve, reject });
      })
        .then(token => {
          originalRequest.headers['Authorization'] = `Bearer ${token}`;
          originalRequest._retry = true;
          return apiClient(originalRequest);
        })
        .catch(err => {
          // Если обновление токена не удалось, перенаправляем на страницу входа
          console.error('Unauthorized access - redirecting to login');
          window.location.href = '/login';
          return Promise.reject(err);
        });
    }
    
    // Если запрос не доступен из-за проблем с сетью, попробуем повторить несколько раз
    if (error.code === 'ECONNABORTED' || error.message === 'Network Error') {
      const retryCount = originalRequest._retryCount || 0;
      
      if (retryCount < RETRY_COUNT) {
        originalRequest._retryCount = retryCount + 1;
        console.warn(`Retry request attempt ${originalRequest._retryCount} for ${originalRequest.url}`);
        
        // Небольшая задержка перед повторной попыткой
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(apiClient(originalRequest));
          }, 1000 * (retryCount + 1)); // Увеличиваем задержку с каждой попыткой
        });
      }
    }
    
    // Обработка других типов ошибок
    if (error.response) {
      // Обработка специфичных кодов ошибок
      console.error('API Error:', error.response.data);
    } else if (error.request) {
      // Запрос был сделан, но ответ не был получен
      console.error('Network Error:', error.request);
    } else {
      // Что-то случилось при настройке запроса
      console.error('Error:', error.message);
    }
    
    // Возвращаем ошибку, чтобы ее можно было обработать в вызывающем коде
    return Promise.reject(error);
  }
);

// Основной API-сервис с методами для работы с бэкендом
const apiService = {
  // =========== Аутентификация ===========
  login: async (credentials) => {
    const response = await apiClient.post('/auth/login', credentials);
    // Сохраняем токены после успешного входа
    if (response.data.token) {
      localStorage.setItem('authToken', response.data.token);
      if (response.data.refreshToken) {
        localStorage.setItem('refreshToken', response.data.refreshToken);
      }
    }
    return response.data;
  },

  logout: async () => {
    try {
      const response = await apiClient.post('/auth/logout');
      return response.data;
    } finally {
      // Всегда удаляем локальные токены при выходе
      localStorage.removeItem('authToken');
      localStorage.removeItem('refreshToken');
    }
  },

  refreshToken: async (refreshToken) => {
    const response = await apiClient.post('/auth/refresh', { refreshToken });
    return response.data;
  },

  // =========== Заказы ===========
  getOrders: async (params) => {
    const response = await apiClient.get('/orders', { params });
    return response.data;
  },

  getOrderById: async (id) => {
    const response = await apiClient.get(`/orders/${id}`);
    return response.data;
  },

  createOrder: async (orderData) => {
    const response = await apiClient.post('/orders', orderData);
    return response.data;
  },

  updateOrder: async (id, orderData) => {
    const response = await apiClient.put(`/orders/${id}`, orderData);
    return response.data;
  },

  updateOrderStatus: async (id, status) => {
    const response = await apiClient.patch(`/orders/${id}/status`, { status });
    return response.data;
  },

  // =========== Поставки ===========
  getSupplies: async (params) => {
    const response = await apiClient.get('/supplies', { params });
    return response.data;
  },

  getSupplyById: async (id) => {
    const response = await apiClient.get(`/supplies/${id}`);
    return response.data;
  },

  createSupply: async (supplyData) => {
    const response = await apiClient.post('/supplies', supplyData);
    return response.data;
  },

  updateSupply: async (id, supplyData) => {
    const response = await apiClient.put(`/supplies/${id}`, supplyData);
    return response.data;
  },

  // =========== Wildberries API ===========
  
  // Заказы
  getNewWbOrders: async () => {
    const response = await apiClient.get('/wb-api/orders/new');
    return response.data;
  },

  getCompletedWbOrders: async (params) => {
    const response = await apiClient.get('/wb-api/orders', { params });
    return response.data;
  },

  getWbClientInfo: async (orderIds) => {
    const response = await apiClient.post('/wb-api/orders/client', { orderIds });
    return response.data;
  },

  getWbOrderStatuses: async (orderIds) => {
    const response = await apiClient.post('/wb-api/orders/status', { orderIds });
    return response.data;
  },

  getWbOrderStickers: async (orderIds, type) => {
    const response = await apiClient.post('/wb-api/orders/stickers', { 
      orderIds, 
      type 
    });
    return response.data;
  },

  cancelWbOrder: async (orderId, reason) => {
    const response = await apiClient.patch(`/wb-api/orders/${orderId}/cancel`, { reason });
    return response.data;
  },

  confirmWbOrder: async (orderId) => {
    const response = await apiClient.patch(`/wb-api/orders/${orderId}/confirm`);
    return response.data;
  },

  deliverWbOrder: async (orderId) => {
    const response = await apiClient.patch(`/wb-api/orders/${orderId}/deliver`);
    return response.data;
  },

  receiveWbOrder: async (orderId) => {
    const response = await apiClient.patch(`/wb-api/orders/${orderId}/receive`);
    return response.data;
  },

  rejectWbOrder: async (orderId) => {
    const response = await apiClient.patch(`/wb-api/orders/${orderId}/reject`);
    return response.data;
  },

  getWbOrderMeta: async (orderId) => {
    const response = await apiClient.get(`/wb-api/orders/${orderId}/meta`);
    return response.data;
  },

  setWbOrderSgtin: async (orderId, sgtinData) => {
    const response = await apiClient.put(`/wb-api/orders/${orderId}/meta/sgtin`, sgtinData);
    return response.data;
  },

  // Поставки
  createWbSupply: async (name) => {
    const response = await apiClient.post('/wb-api/supplies/create', { name });
    return response.data;
  },

  getWbSupplyInfo: async (id) => {
    const response = await apiClient.get(`/wb-api/supplies/${id}/info`);
    return response.data;
  },

  addOrdersToWbSupply: async (id, orderIds) => {
    const response = await apiClient.post(`/wb-api/supplies/${id}/orders`, { orderIds });
    return response.data;
  },

  // Отзывы и вопросы
  getWbFeedbacksCount: async () => {
    const response = await apiClient.get('/wb-api/feedbacks/count');
    return response.data;
  },

  getWbFeedbacks: async (params) => {
    const response = await apiClient.get('/wb-api/feedbacks', { params });
    return response.data;
  },

  getWbQuestionsCount: async () => {
    const response = await apiClient.get('/wb-api/questions/count');
    return response.data;
  },

  getWbQuestions: async (params) => {
    const response = await apiClient.get('/wb-api/questions', { params });
    return response.data;
  },

  // Чаты
  getWbChats: async (params) => {
    const response = await apiClient.get('/wb-api/chats', { params });
    return response.data;
  },

  getWbChatEvents: async (params) => {
    const response = await apiClient.get('/wb-api/events', { params });
    return response.data;
  },

  sendWbMessage: async (message) => {
    const response = await apiClient.post('/wb-api/message', message);
    return response.data;
  },

  // =========== Настройки ===========
  getSettings: async () => {
    const response = await apiClient.get('/settings');
    return response.data;
  },

  updateSettings: async (settingsData) => {
    const response = await apiClient.put('/settings', settingsData);
    return response.data;
  },
};

export default apiService; 