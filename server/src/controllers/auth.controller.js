/**
 * Контроллер для аутентификации пользователей
 */
import bcrypt from 'bcrypt';
import logger from '../utils/logger.js';
import { generateTokens, verifyRefreshToken } from '../middlewares/auth.middleware.js';
import { UserModel } from '../models/user.model.js';

/**
 * Авторизация пользователя
 */
export const login = async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Проверяем наличие имени пользователя и пароля
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Необходимо указать имя пользователя и пароль'
      });
    }
    
    // Ищем пользователя в базе данных
    const user = await UserModel.getUserByUsername(username);
    
    // Если пользователь не найден
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Неверное имя пользователя или пароль'
      });
    }
    
    // Проверяем пароль
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Неверное имя пользователя или пароль'
      });
    }
    
    // Генерируем JWT токены
    const { token, refreshToken } = generateTokens(user);
    
    // Сохраняем refresh токен в базе данных
    await UserModel.updateRefreshToken(user.id, refreshToken);
    
    // Записываем лог о успешном входе
    logger.info(`Пользователь ${username} успешно авторизовался`);
    
    // Удаляем пароль и другие чувствительные данные из ответа
    const userWithoutPassword = { ...user };
    delete userWithoutPassword.password;
    delete userWithoutPassword.refreshToken;
    
    // Отправляем ответ с токенами и данными пользователя
    return res.json({
      success: true,
      message: 'Авторизация успешна',
      token,
      refreshToken,
      user: userWithoutPassword
    });
  } catch (error) {
    logger.error('Ошибка при авторизации пользователя:', error);
    return res.status(500).json({
      success: false,
      message: 'Внутренняя ошибка сервера'
    });
  }
};

/**
 * Выход из системы (логаут)
 */
export const logout = async (req, res) => {
  try {
    const { userId } = req.user;
    
    // Удаляем refresh токен из базы данных
    await UserModel.updateRefreshToken(userId, null);
    
    return res.json({
      success: true,
      message: 'Вы успешно вышли из системы'
    });
  } catch (error) {
    logger.error('Ошибка при выходе из системы:', error);
    return res.status(500).json({
      success: false,
      message: 'Внутренняя ошибка сервера'
    });
  }
};

/**
 * Обновление токена доступа
 */
export const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Отсутствует refresh токен'
      });
    }
    
    // Проверяем refresh токен
    const decoded = verifyRefreshToken(refreshToken);
    
    // Ищем пользователя в базе данных
    const user = await UserModel.getUserById(decoded.id);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Пользователь не найден'
      });
    }
    
    // Проверяем, совпадает ли токен в БД с предоставленным
    if (user.refreshToken !== refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Недействительный refresh токен'
      });
    }
    
    // Генерируем новые токены
    const tokens = generateTokens(user);
    
    // Обновляем refresh токен в базе данных
    await UserModel.updateRefreshToken(user.id, tokens.refreshToken);
    
    return res.json({
      success: true,
      message: 'Токены успешно обновлены',
      token: tokens.token,
      refreshToken: tokens.refreshToken
    });
  } catch (error) {
    logger.error('Ошибка при обновлении токена:', error);
    return res.status(401).json({
      success: false,
      message: 'Ошибка при обновлении токена'
    });
  }
}; 