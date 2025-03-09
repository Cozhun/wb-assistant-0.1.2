export const ENDPOINTS = {
  orders: '/api/orders',
  products: '/api/products',
  storage: '/api/storage',
  settings: '/api/settings',
} as const;

export const API_METHODS = {
  orders: {
    list: () => ENDPOINTS.orders,
    get: (id: string) => `${ENDPOINTS.orders}/${id}`,
    create: () => ENDPOINTS.orders,
    update: (id: string) => `${ENDPOINTS.orders}/${id}`,
    delete: (id: string) => `${ENDPOINTS.orders}/${id}`,
  },
  products: {
    list: () => ENDPOINTS.products,
    get: (id: string) => `${ENDPOINTS.products}/${id}`,
    create: () => ENDPOINTS.products,
    update: (id: string) => `${ENDPOINTS.products}/${id}`,
    delete: (id: string) => `${ENDPOINTS.products}/${id}`,
  },
  storage: {
    list: () => ENDPOINTS.storage,
    get: (id: string) => `${ENDPOINTS.storage}/${id}`,
    update: (id: string) => `${ENDPOINTS.storage}/${id}`,
  },
} as const; 