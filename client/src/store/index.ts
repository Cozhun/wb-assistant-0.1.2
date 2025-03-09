import { create } from 'zustand';
import { api, Metrics, Order, Product } from '../api/client';

interface AppState {
  // Данные
  metrics: Metrics | null;
  orders: Order[];
  products: Product[];
  
  // Состояния загрузки
  isLoading: {
    metrics: boolean;
    orders: boolean;
    products: boolean;
  };
  
  // Ошибки
  errors: {
    metrics: string | null;
    orders: string | null;
    products: string | null;
  };

  // Действия
  fetchMetrics: () => Promise<void>;
  fetchOrders: () => Promise<void>;
  fetchProducts: () => Promise<void>;
}

export const useStore = create<AppState>((set) => ({
  // Начальное состояние
  metrics: null,
  orders: [],
  products: [],
  
  isLoading: {
    metrics: false,
    orders: false,
    products: false,
  },
  
  errors: {
    metrics: null,
    orders: null,
    products: null,
  },

  // Методы для загрузки данных
  fetchMetrics: async () => {
    set((state) => ({
      isLoading: { ...state.isLoading, metrics: true },
      errors: { ...state.errors, metrics: null },
    }));

    try {
      const metrics = await api.getMetrics();
      set({ metrics });
    } catch (error) {
      set((state) => ({
        errors: { ...state.errors, metrics: 'Ошибка загрузки метрик' },
      }));
    } finally {
      set((state) => ({
        isLoading: { ...state.isLoading, metrics: false },
      }));
    }
  },

  fetchOrders: async () => {
    set((state) => ({
      isLoading: { ...state.isLoading, orders: true },
      errors: { ...state.errors, orders: null },
    }));

    try {
      const orders = await api.getOrders();
      set({ orders });
    } catch (error) {
      set((state) => ({
        errors: { ...state.errors, orders: 'Ошибка загрузки заказов' },
      }));
    } finally {
      set((state) => ({
        isLoading: { ...state.isLoading, orders: false },
      }));
    }
  },

  fetchProducts: async () => {
    set((state) => ({
      isLoading: { ...state.isLoading, products: true },
      errors: { ...state.errors, products: null },
    }));

    try {
      const products = await api.getProducts();
      set({ products });
    } catch (error) {
      set((state) => ({
        errors: { ...state.errors, products: 'Ошибка загрузки товаров' },
      }));
    } finally {
      set((state) => ({
        isLoading: { ...state.isLoading, products: false },
      }));
    }
  },
})); 