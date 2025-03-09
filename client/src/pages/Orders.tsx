import React, { useEffect } from 'react';
import { Text, Table, Group, Loader, Badge } from '@mantine/core';
import { useStore } from '../store';

const getStatusColor = (status: string) => {
  switch (status) {
    case 'new':
      return 'blue';
    case 'processing':
      return 'yellow';
    case 'shipped':
      return 'green';
    default:
      return 'gray';
  }
};

const getStatusText = (status: string) => {
  switch (status) {
    case 'new':
      return 'Новый';
    case 'processing':
      return 'В обработке';
    case 'shipped':
      return 'Отправлен';
    default:
      return status;
  }
};

const Orders: React.FC = () => {
  const { orders, isLoading, errors, fetchOrders } = useStore();

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  if (isLoading.orders) {
    return (
      <Group justify="center" style={{ minHeight: 200 }} align="center">
        <Loader size="xl" />
      </Group>
    );
  }

  if (errors.orders) {
    return (
      <Text c="red" size="xl" ta="center">
        {errors.orders}
      </Text>
    );
  }

  return (
    <>
      <Text size="xl" mb="xl">Заказы</Text>

      <Table>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>Номер</Table.Th>
            <Table.Th>Статус</Table.Th>
            <Table.Th ta="right">Сумма</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {orders.map((order) => (
            <Table.Tr key={order.id}>
              <Table.Td>{order.number}</Table.Td>
              <Table.Td>
                <Badge color={getStatusColor(order.status)}>
                  {getStatusText(order.status)}
                </Badge>
              </Table.Td>
              <Table.Td ta="right">{order.total} ₽</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </>
  );
};

export default Orders; 