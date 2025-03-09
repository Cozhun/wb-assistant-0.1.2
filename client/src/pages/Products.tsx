import React, { useEffect } from 'react';
import { Text, Table, Group, Loader, Badge } from '@mantine/core';
import { useStore } from '../store';

const Products: React.FC = () => {
  const { products, isLoading, errors, fetchProducts } = useStore();

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  if (isLoading.products) {
    return (
      <Group justify="center" style={{ minHeight: 200 }} align="center">
        <Loader size="xl" />
      </Group>
    );
  }

  if (errors.products) {
    return (
      <Text c="red" size="xl" ta="center">
        {errors.products}
      </Text>
    );
  }

  return (
    <>
      <Text size="xl" mb="xl">Товары</Text>

      <Table>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>Артикул</Table.Th>
            <Table.Th>Наименование</Table.Th>
            <Table.Th ta="right">Остаток</Table.Th>
            <Table.Th ta="right">Цена</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {products.map((product) => (
            <Table.Tr key={product.id}>
              <Table.Td>{product.sku}</Table.Td>
              <Table.Td>{product.name}</Table.Td>
              <Table.Td ta="right">
                <Badge 
                  color={product.stock > 50 ? 'green' : product.stock > 10 ? 'yellow' : 'red'}
                >
                  {product.stock}
                </Badge>
              </Table.Td>
              <Table.Td ta="right">{product.price} ₽</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </>
  );
};

export default Products; 