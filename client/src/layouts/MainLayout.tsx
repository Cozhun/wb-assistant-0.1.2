import React from 'react';
import { AppShell } from '@mantine/core';
import Navigation from '../components/Navigation';
import { Routes, Route } from 'react-router-dom';
import Dashboard from '../pages/Dashboard';
import Orders from '../pages/Orders';
import Products from '../pages/Products';
import Storage from '../pages/Storage';
import Settings from '../pages/Settings';

const MainLayout: React.FC = () => {
  return (
    <AppShell
      navbar={{ width: 300, breakpoint: 'sm' }}
      padding="md"
    >
      <AppShell.Navbar>
        <Navigation />
      </AppShell.Navbar>

      <AppShell.Main>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/products" element={<Products />} />
          <Route path="/storage" element={<Storage />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </AppShell.Main>
    </AppShell>
  );
};

export default MainLayout; 