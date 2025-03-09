const API_URL = '/api';

export interface Metrics {
  activeOrders: number;
  totalProducts: number;
  todaySales: number;
  averageRating: number;
}

export interface Order {
  id: number;
  number: string;
  status: string;
  total: number;
}

export interface Product {
  id: number;
  name: string;
  sku: string;
  stock: number;
  price: number;
}

export const api = {
  async getMetrics(): Promise<Metrics> {
    const response = await fetch(`${API_URL}/metrics`);
    if (!response.ok) throw new Error('Failed to fetch metrics');
    return response.json();
  },

  async getOrders(): Promise<Order[]> {
    const response = await fetch(`${API_URL}/orders`);
    if (!response.ok) throw new Error('Failed to fetch orders');
    return response.json();
  },

  async getProducts(): Promise<Product[]> {
    const response = await fetch(`${API_URL}/products`);
    if (!response.ok) throw new Error('Failed to fetch products');
    return response.json();
  }
}; 