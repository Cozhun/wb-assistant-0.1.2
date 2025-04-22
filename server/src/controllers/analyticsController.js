const analyticsService = require('../services/analyticsService');

/**
 * Контроллер для обработки запросов, связанных с аналитикой
 */
class AnalyticsController {
  /**
   * Получение данных для дашборда аналитики
   * @param {object} req - Объект запроса Express
   * @param {object} res - Объект ответа Express
   * @param {function} next - Функция для передачи управления следующему middleware
   */
  async getDashboardData(req, res, next) {
    try {
      // Извлекаем параметры из запроса
      const { period, categories, compare } = req.query;
      const selectedCategories = categories ? categories.split(',') : [];
      const compareMode = compare === 'true'; // Преобразуем строку в boolean

      // Вызываем сервис для получения данных
      const data = await analyticsService.getAnalyticsDashboardData({
        period: period || 'month', // Значение по умолчанию, если не передано
        selectedCategories,
        compareMode,
        // userId: req.user.id // Если нужна привязка к пользователю
      });

      res.json(data);
    } catch (error) {
      next(error); // Передаем ошибку в обработчик ошибок Express
    }
  }

  // Другие методы контроллера для аналитики (если понадобятся)
  // Например, экспорт данных, получение специфических отчетов и т.д.

}

module.exports = new AnalyticsController(); 