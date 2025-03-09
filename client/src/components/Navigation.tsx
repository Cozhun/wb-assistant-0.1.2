import React from 'react';
import { NavLink } from '@mantine/core';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  IconDashboard,
  IconShoppingCart,
  IconBox,
  IconTruck,
  IconSettings,
} from '@tabler/icons-react';

const Navigation: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const links = [
    { icon: IconDashboard, label: 'Дашборд', path: '/' },
    { icon: IconShoppingCart, label: 'Заказы', path: '/orders' },
    { icon: IconBox, label: 'Товары', path: '/products' },
    { icon: IconTruck, label: 'Склад', path: '/storage' },
    { icon: IconSettings, label: 'Настройки', path: '/settings' },
  ];

  return (
    <div style={{ padding: '1rem' }}>
      {links.map((link) => (
        <NavLink
          key={link.path}
          active={location.pathname === link.path}
          label={link.label}
          leftSection={<link.icon size="1.2rem" stroke={1.5} />}
          onClick={() => navigate(link.path)}
          style={{ marginBottom: '0.5rem' }}
        />
      ))}
    </div>
  );
};

export default Navigation; 