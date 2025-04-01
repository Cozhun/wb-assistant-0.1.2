import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_client/main.dart' as app;
import 'package:mobile_client/modules/orders/services/supply_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Сборка поставок - интеграция со сканером', () {
    testWidgets('Полный цикл сборки поставки с использованием сканера', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Проверка, что приложение запустилось и отображается экран логина
      expect(find.text('Войти'), findsOneWidget);

      // Ввод данных логина
      await tester.enterText(find.byType(TextField).at(0), 'user');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pumpAndSettle();

      // Нажатие на кнопку входа
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на экран поставок
      await tester.tap(find.text('Поставки'));
      await tester.pumpAndSettle();

      // Проверка, что отображается экран поставок
      expect(find.text('Поставки'), findsOneWidget);

      // Получение списка поставок (в реальном тесте это должно быть через сервис)
      final mockSupplies = await SupplyService().getMockSupplies();
      
      if (mockSupplies.isNotEmpty) {
        // Находим первую поставку в статусе сборки
        final supplyInCollection = mockSupplies
            .where((s) => s.status == SupplyStatus.collecting)
            .first;
            
        // Находим и нажимаем на карточку поставки
        if (find.textContaining(supplyInCollection.id).evaluate().isNotEmpty) {
          await tester.tap(find.textContaining(supplyInCollection.id).first);
          await tester.pumpAndSettle();

          // Проверка, что отображается экран деталей поставки
          expect(find.text('Поставка ${supplyInCollection.id}'), findsOneWidget);

          // Нажатие на кнопку сканирования
          await tester.tap(find.text('Сканировать'));
          await tester.pumpAndSettle();

          // Проверка, что открылся экран сканера
          expect(find.textContaining('Сканирование товаров - Поставка'), findsOneWidget);

          // Ввод штрихкода для тестирования
          await tester.enterText(find.byType(TextField), '123456789');
          await tester.pumpAndSettle();

          // Нажатие на кнопку отправки
          await tester.tap(find.text('Отправить'));
          await tester.pumpAndSettle();

          // Проверка, что отображается сообщение об успешном сканировании
          expect(find.textContaining('добавлен'), findsOneWidget);

          // Возврат к экрану поставки
          await tester.tap(find.text('Вернуться'));
          await tester.pumpAndSettle();

          // Проверка, что вернулись на экран поставки
          expect(find.text('Поставка ${supplyInCollection.id}'), findsOneWidget);
        }
      }
    });
  });
} 