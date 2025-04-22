import { useState, useEffect } from 'react';
import { 
  Container, 
  Typography, 
  Box, 
  Paper, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow,
  TablePagination,
  Button,
  Chip,
  CircularProgress
} from '@mui/material';
import apiService from '../services/apiService';

// Функция для определения цвета статуса заказа
const getStatusColor = (status) => {
  switch (status) {
    case 'new': return 'primary';
    case 'in_progress': return 'info';
    case 'packed': return 'warning';
    case 'shipped': return 'success';
    case 'cancelled': return 'error';
    case 'impossible': return 'error';
    default: return 'default';
  }
};

// Функция для форматирования статуса
const formatStatus = (status) => {
  const statusMap = {
    'new': 'Новый',
    'in_progress': 'В обработке',
    'packed': 'Упакован',
    'shipped': 'Отправлен',
    'cancelled': 'Отменен',
    'impossible': 'Невозможно собрать'
  };
  
  return statusMap[status] || status;
};

// Компонент страницы заказов
function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [wbOrders, setWbOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  
  // Загрузка заказов
  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setLoading(true);
        // Получаем обычные заказы
        const ordersData = await apiService.getOrders();
        setOrders(ordersData.data || ordersData);
        
        // Получаем WB заказы
        const wbOrdersData = await apiService.getNewWbOrders();
        setWbOrders(wbOrdersData);
        
        setLoading(false);
      } catch (err) {
        setError(err.message || 'Ошибка при загрузке заказов');
        setLoading(false);
      }
    };
    
    fetchOrders();
  }, []);
  
  // Обработчики пагинации
  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };
  
  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };
  
  // Форматирование даты
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  };
  
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Заказы
        </Typography>
        
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
            <CircularProgress />
          </Box>
        ) : error ? (
          <Box sx={{ mt: 2 }}>
            <Typography color="error">{error}</Typography>
            <Button 
              variant="contained" 
              sx={{ mt: 1 }}
              onClick={() => window.location.reload()}
            >
              Попробовать снова
            </Button>
          </Box>
        ) : (
          <>
            {/* Обычные заказы */}
            <Typography variant="h5" sx={{ mt: 4, mb: 2 }}>
              Заказы системы
            </Typography>
            <TableContainer component={Paper}>
              <Table sx={{ minWidth: 650 }}>
                <TableHead>
                  <TableRow>
                    <TableCell>№ заказа</TableCell>
                    <TableCell>Дата создания</TableCell>
                    <TableCell>Срок выполнения</TableCell>
                    <TableCell>Клиент</TableCell>
                    <TableCell>Сумма</TableCell>
                    <TableCell>Статус</TableCell>
                    <TableCell>Действия</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(rowsPerPage > 0
                    ? orders.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                    : orders
                  ).map((order) => (
                    <TableRow key={order.id} hover>
                      <TableCell>{order.orderNumber}</TableCell>
                      <TableCell>{formatDate(order.createdAt)}</TableCell>
                      <TableCell>{formatDate(order.dueDate)}</TableCell>
                      <TableCell>{order.customerName}</TableCell>
                      <TableCell>{order.totalAmount} ₽</TableCell>
                      <TableCell>
                        <Chip 
                          label={formatStatus(order.status)} 
                          color={getStatusColor(order.status)} 
                          size="small" 
                        />
                      </TableCell>
                      <TableCell>
                        <Button 
                          size="small" 
                          variant="outlined"
                          onClick={() => window.location.href = `/orders/${order.id}`}
                        >
                          Просмотр
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <TablePagination
                rowsPerPageOptions={[5, 10, 25]}
                component="div"
                count={orders.length}
                rowsPerPage={rowsPerPage}
                page={page}
                onPageChange={handleChangePage}
                onRowsPerPageChange={handleChangeRowsPerPage}
                labelRowsPerPage="Строк на странице:"
                labelDisplayedRows={({ from, to, count }) => 
                  `${from}–${to} из ${count !== -1 ? count : `более чем ${to}`}`
                }
              />
            </TableContainer>
            
            {/* Заказы Wildberries */}
            <Typography variant="h5" sx={{ mt: 4, mb: 2 }}>
              Заказы Wildberries
            </Typography>
            <TableContainer component={Paper}>
              <Table sx={{ minWidth: 650 }}>
                <TableHead>
                  <TableRow>
                    <TableCell>№ заказа WB</TableCell>
                    <TableCell>Дата создания</TableCell>
                    <TableCell>Срок выполнения</TableCell>
                    <TableCell>Артикул</TableCell>
                    <TableCell>Товар</TableCell>
                    <TableCell>Количество</TableCell>
                    <TableCell>Статус</TableCell>
                    <TableCell>Действия</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(rowsPerPage > 0
                    ? wbOrders.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                    : wbOrders
                  ).map((order) => (
                    <TableRow key={order.id} hover>
                      <TableCell>{order.wbOrderNumber}</TableCell>
                      <TableCell>{formatDate(order.createdAt)}</TableCell>
                      <TableCell>{formatDate(order.dueDate)}</TableCell>
                      <TableCell>
                        {order.items && order.items.length > 0 ? order.items[0].article : ''}
                      </TableCell>
                      <TableCell>
                        {order.items && order.items.length > 0 ? order.items[0].name : ''}
                      </TableCell>
                      <TableCell>
                        {order.items && order.items.length > 0 ? order.items[0].quantity : ''}
                      </TableCell>
                      <TableCell>
                        <Chip 
                          label={formatStatus(order.status)} 
                          color={getStatusColor(order.status)} 
                          size="small" 
                        />
                      </TableCell>
                      <TableCell>
                        <Button 
                          size="small" 
                          variant="outlined"
                          onClick={() => window.location.href = `/wildberries/orders/${order.id}`}
                        >
                          Просмотр
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <TablePagination
                rowsPerPageOptions={[5, 10, 25]}
                component="div"
                count={wbOrders.length}
                rowsPerPage={rowsPerPage}
                page={page}
                onPageChange={handleChangePage}
                onRowsPerPageChange={handleChangeRowsPerPage}
                labelRowsPerPage="Строк на странице:"
                labelDisplayedRows={({ from, to, count }) => 
                  `${from}–${to} из ${count !== -1 ? count : `более чем ${to}`}`
                }
              />
            </TableContainer>
          </>
        )}
      </Box>
    </Container>
  );
}

export default OrdersPage; 