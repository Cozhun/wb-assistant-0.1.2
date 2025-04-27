#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Мост между JavaScript и Python для работы с WB API
"""

import os
import sys
import json
import base64
import logging
from datetime import datetime
import argparse
from pathlib import Path

# Настройка пути к библиотеке
lib_path = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent / "lib"
sys.path.append(str(lib_path))

try:
    from wb_assistant_lib import WildberriesFBSClient
except ImportError:
    sys.stderr.write("Ошибка: Не удалось импортировать библиотеку WildberriesFBSClient\n")
    sys.exit(1)

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger("wb_api_bridge")

def parse_args():
    """Обработка аргументов командной строки"""
    parser = argparse.ArgumentParser(description="Мост для работы с Wildberries API")
    parser.add_argument("--method", required=True, help="Метод API для вызова")
    parser.add_argument("--args", help="Аргументы метода в формате JSON", default="{}")
    parser.add_argument("--api-key", help="API ключ Wildberries")
    parser.add_argument("--debug", action="store_true", help="Режим отладки")
    return parser.parse_args()

def init_client(api_key=None):
    """Инициализация клиента API"""
    if not api_key:
        api_key = os.environ.get("WB_API_KEY")
        if not api_key:
            logger.warning("API ключ не указан. Используется режим моков.")
    
    try:
        return WildberriesFBSClient(api_key=api_key)
    except Exception as e:
        logger.error(f"Ошибка инициализации клиента: {str(e)}")
        sys.exit(1)

def encode_base64(data):
    """Кодирование бинарных данных в base64"""
    if isinstance(data, bytes):
        return base64.b64encode(data).decode('utf-8')
    return data

def process_response(response):
    """Обработка ответа от API для правильной сериализации"""
    if isinstance(response, (list, tuple)):
        return [process_response(item) for item in response]
    elif isinstance(response, dict):
        result = {}
        for key, value in response.items():
            if isinstance(value, bytes):
                result[key] = encode_base64(value)
            elif isinstance(value, (list, dict)):
                result[key] = process_response(value)
            elif isinstance(value, datetime):
                result[key] = value.isoformat()
            else:
                result[key] = value
        return result
    elif isinstance(response, bytes):
        return encode_base64(response)
    elif isinstance(response, datetime):
        return response.isoformat()
    else:
        return response

def execute_method(client, method, args):
    """Выполнение метода API"""
    try:
        # Получаем метод из клиента по имени
        api_method = getattr(client, method, None)
        if not api_method:
            raise ValueError(f"Метод {method} не найден в API клиенте")
        
        # Выполняем метод с переданными аргументами
        result = api_method(**args)
        
        # Обрабатываем результат для корректной JSON сериализации
        return process_response(result)
    
    except Exception as e:
        logger.error(f"Ошибка при выполнении метода {method}: {str(e)}")
        return {"error": str(e), "type": type(e).__name__}

def main():
    """Основная функция"""
    args = parse_args()
    
    if args.debug:
        logger.setLevel(logging.DEBUG)
        logger.debug("Включен режим отладки")
    
    try:
        # Инициализация клиента
        client = init_client(args.api_key)
        
        # Парсинг аргументов метода
        method_args = json.loads(args.args)
        
        # Выполнение метода
        result = execute_method(client, args.method, method_args)
        
        # Вывод результата в stdout
        print(json.dumps(result, ensure_ascii=False))
        
        sys.exit(0)
    
    except json.JSONDecodeError as e:
        logger.error(f"Ошибка декодирования JSON: {str(e)}")
    except Exception as e:
        logger.error(f"Непредвиденная ошибка: {str(e)}")
    
    sys.exit(1)

if __name__ == "__main__":
    main() 