import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // Настройка прокси для перенаправления API запросов на сервер
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
        // Опционально: удаление префикса '/api' перед перенаправлением на сервер
        // rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  }
})
