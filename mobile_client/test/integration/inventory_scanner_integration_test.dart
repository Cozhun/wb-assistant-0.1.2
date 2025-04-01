import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_client/main.dart' as app;
import 'package:mobile_client/modules/inventory/models/inventory_session.dart';
import 'package:mobile_client/modules/inventory/services/inventory_service.dart';
import 'package:mobile_client/modules/orders/services/supply_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Сканирование и инвентаризация - интеграция', () {
    testWidgets('Полный цикл работы инвентаризации и сканера', (WidgetTester tester) async {
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

      // Переход на экран инвентаризации
      await tester.tap(find.text('Инвентаризация'));
      await tester.pumpAndSettle();

      // Проверка, что отображается экран инвентаризации
      expect(find.text('Инвентаризация'), findsOneWidget);
      expect(find.text('Сеансы инвентаризации'), findsOneWidget);

      // Получение списка сессий (в реальном тесте это должно быть через сервис)
      final mockSessions = await InventoryService().getSessions();
      
      if (mockSessions.isNotEmpty) {
        // Выбор первой сессии
        final sessionName = mockSessions.first.name;
        if (find.text(sessionName).evaluate().isNotEmpty) {
          await tester.tap(find.text(sessionName));
          await tester.pumpAndSettle();

          // Проверка, что отображается экран сессии
          expect(find.text('Зона: ${mockSessions.first.zone}'), findsOneWidget);

          // Нажатие на кнопку сканирования
          await tester.tap(find.text('Сканировать'));
          await tester.pumpAndSettle();

          // Проверка, что открылся экран сканера
          expect(find.byType(TextFormField), findsOneWidget);

          // Ввод штрихкода для тестирования
          await tester.enterText(find.byType(TextFormField), '123456789');
          await tester.pumpAndSettle();

          // Нажатие на кнопку отправки
          await tester.tap(find.text('Отправить'));
          await tester.pumpAndSettle();

          // Проверка, что отображается сообщение об успешном сканировании
          expect(find.textContaining('добавлен'), findsOneWidget);

          // Возврат к экрану инвентаризации
          await tester.tap(find.text('Вернуться'));
          await tester.pumpAndSettle();

          // Проверка, что вернулись на экран сессии
          expect(find.text('Зона: ${mockSessions.first.zone}'), findsOneWidget);
        }
      }
    });
  });
} 