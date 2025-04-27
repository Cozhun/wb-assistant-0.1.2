/**
 * Контроллер для управления пользователями
 */
import { UserModel } from '../models/user.model.js';
import logger from '../utils/logger.js';

/**
 * Получить пользователей по ID предприятия
 */
export const getUsersByEnterpriseId = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const users = await UserModel.getUsersByEnterpriseId(enterpriseId);
    return res.json(users);
  } catch (error) {
    logger.error('Ошибка при получении пользователей предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить пользователя по ID
 */
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await UserModel.getUserById(id);
    
    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    return res.json(user);
  } catch (error) {
    logger.error(`Ошибка при получении пользователя с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать нового пользователя
 */
export const createUser = async (req, res) => {
  try {
    const { email, name, password, enterpriseId, role } = req.body;
    
    if (!email || !enterpriseId) {
      return res.status(400).json({ 
        error: 'Email и ID предприятия обязательны' 
      });
    }
    
    // Проверка на существующий email
    const existingUser = await UserModel.getUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({ 
        error: 'Пользователь с таким email уже существует' 
      });
    }
    
    const newUser = await UserModel.createUser({ 
      email, name, password, enterpriseId, role 
    });
    
    return res.status(201).json(newUser);
  } catch (error) {
    logger.error('Ошибка при создании пользователя:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить пользователя
 */
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { email, name, password, enterpriseId, role } = req.body;
    
    // Проверка существования пользователя
    const existingUser = await UserModel.getUserById(id);
    if (!existingUser) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    // Проверка email на уникальность, если он меняется
    if (email && email !== existingUser.email) {
      const userWithSameEmail = await UserModel.getUserByEmail(email);
      if (userWithSameEmail) {
        return res.status(409).json({ 
          error: 'Пользователь с таким email уже существует' 
        });
      }
    }
    
    const updatedUser = await UserModel.updateUser(id, { 
      email, name, password, enterpriseId, role 
    });
    
    return res.json(updatedUser);
  } catch (error) {
    logger.error(`Ошибка при обновлении пользователя с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить пользователя
 */
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверка существования пользователя
    const existingUser = await UserModel.getUserById(id);
    if (!existingUser) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    await UserModel.deleteUser(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении пользователя с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 