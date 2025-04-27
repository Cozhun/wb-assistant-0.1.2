export const ENDPOINTS = {
  orders: '/api/orders',
  products: '/api/products',
  storage: '/api/storage',
  settings: '/api/settings',
};

export const API_METHODS = {
  orders: {
    list: () => ENDPOINTS.orders,
    get: (id) => `${ENDPOINTS.orders}/${id}`,
    create: () => ENDPOINTS.orders,
    update: (id) => `${ENDPOINTS.orders}/${id}`,
    delete: (id) => `${ENDPOINTS.orders}/${id}`,
  },
  products: {
    list: () => ENDPOINTS.products,
    get: (id) => `${ENDPOINTS.products}/${id}`,
    create: () => ENDPOINTS.products,
    update: (id) => `${ENDPOINTS.products}/${id}`,
    delete: (id) => `${ENDPOINTS.products}/${id}`,
  },
  storage: {
    list: () => ENDPOINTS.storage,
    get: (id) => `${ENDPOINTS.storage}/${id}`,
    update: (id) => `${ENDPOINTS.storage}/${id}`,
  },
}; 
