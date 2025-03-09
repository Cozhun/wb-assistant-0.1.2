import React, { useEffect } from 'react';
import { Card, Text, Group, SimpleGrid, Loader } from '@mantine/core';
import { useStore } from '../store';

const Dashboard: React.FC = () => {
  const { metrics, isLoading, errors, fetchMetrics } = useStore();

  useEffect(() => {
    fetchMetrics();
  }, [fetchMetrics]);

  if (isLoading.metrics) {
    return (
      <Group justify="center" style={{ minHeight: 200 }} align="center">
        <Loader size="xl" />
      </Group>
    );
  }

  if (errors.metrics) {
    return (
      <Text c="red" size="xl" ta="center">
        {errors.metrics}
      </Text>
    );
  }

  const metricsData = [
    { label: 'Активных заказов', value: metrics?.activeOrders.toString() ?? '0' },
    { label: 'Товаров на складе', value: metrics?.totalProducts.toString() ?? '0' },
    { label: 'Продаж за сегодня', value: metrics?.todaySales.toString() ?? '0' },
    { label: 'Средний рейтинг', value: metrics?.averageRating.toString() ?? '0' },
  ];

  return (
    <>
      <Text size="xl" mb="xl">Дашборд</Text>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }}>
        {metricsData.map((metric) => (
          <Card key={metric.label} withBorder>
            <Text size="lg" c="dimmed" tt="uppercase" fw={700} ta="center">
              {metric.label}
            </Text>
            <Text fz="24px" fw={700} ta="center">
              {metric.value}
            </Text>
          </Card>
        ))}
      </SimpleGrid>
    </>
  );
};

export default Dashboard; 