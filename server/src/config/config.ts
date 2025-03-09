import dotenv from 'dotenv';

dotenv.config();

interface Config {
  server: {
    port: number;
    host: string;
  };
  database: {
    host: string;
    port: number;
    user: string;
    password: string;
    database: string;
  };
  redis: {
    host: string;
    port: number;
  };
  wildberries: {
    apiKey: string;
    baseUrl: string;
    mockEnabled: boolean;
  };
  auth: {
    jwtSecret: string;
    tokenExpiration: string;
  };
  logging: {
    level: string;
    file: string;
  };
}

const config: Config = {
  server: {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || 'localhost',
  },
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'wb_assistant',
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },
  wildberries: {
    apiKey: process.env.WB_API_KEY || '',
    baseUrl: process.env.WB_API_URL || 'https://suppliers-api.wildberries.ru',
    mockEnabled: process.env.WB_MOCK_ENABLED === 'true',
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'your-secret-key',
    tokenExpiration: process.env.TOKEN_EXPIRATION || '24h',
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || 'logs/app.log',
  },
};

export default config; 