/**
 * Middleware для аутентификации и авторизации
 */
import jwt from 'jsonwebtoken';
import logger from '../utils/logger.js';

// Конфигурация JWT
const JWT_SECRET = process.env.JWT_SECRET || 'wb-assistant-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'wb-assistant-refresh-secret-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

/**
 * Middleware для проверки JWT токена
 */
export const authenticateJWT = (req, res, next) => {
  // Получаем токен из заголовка Authorization
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: 'Отсутствует токен авторизации'
    });
  }
  
  // Токен в формате "Bearer <token>"
  const tokenParts = authHeader.split(' ');
  if (tokenParts.length !== 2 || tokenParts[0] !== 'Bearer') {
    return res.status(401).json({
      success: false,
      message: 'Неверный формат токена авторизации'
    });
  }
  
  const token = tokenParts[1];
  
  try {
    // Проверяем токен
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Добавляем данные пользователя к запросу
    req.user = decoded;
    
    // Проверяем срок действия токена (опционально)
    const currentTime = Date.now() / 1000;
    if (decoded.exp && decoded.exp < currentTime) {
      return res.status(401).json({
        success: false,
        message: 'Срок действия токена истек'
      });
    }
    
    next();
  } catch (error) {
    logger.error('Ошибка аутентификации:', error);
    
    return res.status(401).json({
      success: false,
      message: 'Недействительный токен авторизации'
    });
  }
};

/**
 * Middleware для проверки роли пользователя
 */
export const authorizeRole = (roles) => {
  return (req, res, next) => {
    // Проверяем, прошел ли пользователь аутентификацию
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Требуется аутентификация'
      });
    }
    
    // Получаем роль пользователя
    const { role } = req.user;
    
    // Проверяем, имеет ли пользователь необходимую роль
    if (!roles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Доступ запрещен'
      });
    }
    
    next();
  };
};

/**
 * Генерация JWT токена и refresh токена
 */
export const generateTokens = (user) => {
  // Создаем payload для JWT
  const payload = {
    id: user.id,
    username: user.username,
    email: user.email,
    role: user.role,
  };
  
  // Генерируем access token
  const token = jwt.sign(
    payload,
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
  
  // Генерируем refresh token с более длительным сроком действия
  const refreshToken = jwt.sign(
    { id: user.id },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES_IN }
  );
  
  return { token, refreshToken };
};

/**
 * Проверка и обновление refresh токена
 */
export const verifyRefreshToken = (refreshToken) => {
  try {
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    return decoded;
  } catch (error) {
    logger.error('Ошибка проверки refresh токена:', error);
    throw new Error('Недействительный refresh токен');
  }
}; 