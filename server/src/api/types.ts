export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T> {
  total: number;
  page: number;
  pageSize: number;
}

// Базовые типы сущностей
export interface Order {
  id: string;
  status: 'new' | 'processing' | 'shipped' | 'delivered';
  createdAt: string;
  updatedAt: string;
}

export interface Product {
  id: string;
  name: string;
  sku: string;
  quantity: number;
}

export interface StorageCell {
  id: string;
  location: string;
  status: 'empty' | 'occupied' | 'reserved';
  productId?: string;
} 