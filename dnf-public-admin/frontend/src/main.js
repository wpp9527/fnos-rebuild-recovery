import { loadDashboardData } from './lib/api.js';
import { renderDashboard } from './views/dashboard.js';
import './styles/app.css';

const root = document.querySelector('#app');
root.innerHTML = '<main style="padding:24px;font-family:Arial,sans-serif;">正在加载后台演示页...</main>';

loadDashboardData().then((data) => {
  root.innerHTML = renderDashboard(data);
}).catch((err) => {
  root.innerHTML = `<main style="padding:24px;font-family:Arial,sans-serif;">加载失败：${err.message}</main>`;
});
