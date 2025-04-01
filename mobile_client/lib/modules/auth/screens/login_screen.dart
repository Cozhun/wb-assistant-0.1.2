import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Экран авторизации
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _apiService = ApiService();
  final _storageService = StorageService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// Проверка авторизации при запуске
  Future<void> _checkAuth() async {
    // Убедимся, что StorageService инициализирован
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Если пользователь уже авторизован, переходим сразу к смене
    final token = _storageService.getToken();
    if (token != null) {
      if (!mounted) return;
      
      _apiService.setAuthToken(token);
      context.go('/shift');
    }
  }
  
  /// Выполнение авторизации
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Убедимся, что StorageService инициализирован
      if (!_storageService.isInitialized) {
        await _storageService.init();
      }
      
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      // Сохраняем данные пользователя и токен
      await _storageService.saveToken(response['token'] as String);
      await _storageService.saveUserData(response['user'] as Map<String, dynamic>);
      
      if (!mounted) return;
      context.go('/shift');
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка авторизации. Проверьте логин и пароль.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип или заголовок
                  const Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'WB Assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Поле ввода логина
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите логин';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  
                  // Поле ввода пароля
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Вывод ошибки, если есть
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Кнопка входа
                  SizedBox(
                    height: 50,
                    child: _isLoading
                        ? const LoadingIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            child: const Text(
                              'Войти',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                  
                  // Demo режим
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      _usernameController.text = 'demo';
                      _passwordController.text = 'demo123';
                      _login();
                    },
                    child: const Text('Демо режим'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 