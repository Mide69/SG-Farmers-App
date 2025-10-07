import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { QueryClient, QueryClientProvider } from 'react-query';

import Header from './components/Header';
import Home from './pages/Home';
import FarmerRegistration from './pages/FarmerRegistration';
import GrantApplication from './pages/GrantApplication';
import Search from './pages/Search';
import Chat from './pages/Chat';
import Dashboard from './pages/Dashboard';

const theme = createTheme({
  palette: {
    primary: {
      main: '#2e7d32',
    },
    secondary: {
      main: '#ff9800',
    },
  },
});

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <div className="App">
            <Header />
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/register" element={<FarmerRegistration />} />
              <Route path="/grants" element={<GrantApplication />} />
              <Route path="/search" element={<Search />} />
              <Route path="/chat" element={<Chat />} />
              <Route path="/dashboard" element={<Dashboard />} />
            </Routes>
          </div>
        </Router>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;