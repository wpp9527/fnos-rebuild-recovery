import {
  banAccountAction,
  clearStoredToken,
  fetchAccountDetail,
  fetchAccounts,
  fetchCharacterDetail,
  fetchCharacters,
  fetchPVFItems,
  fetchPVFStats,
  fetchPVFCategories,
  grantCurrencyAction,
  loadDashboardData,
  login,
  planGrantItem,
  sendMailAction
} from './lib/api.js';

// State
const state = {
  me: null,
  currentView: 'dashboard',
  pvf: {
    items: [],
    total: 0,
    page: 1,
    pageSize: 20,
    totalPages: 0
  },
  pvfCategories: [],
  pvfStats: {},
  selectedCategory: 'all',
  selectedPVF: null,
  searchQuery: '',
  accounts: { items: [] },
  characters: { items: [] }
};

// DOM Elements
const app = document.getElementById('app');

// Render Functions
function renderLogin() {
  return `
    <div class="login-page">
      <div class="login-card">
        <div class="login-title">
          <h1>DNF 管理后台</h1>
          <p>请使用管理员账号登录</p>
        </div>
        <form id="login-form">
          <div class="form-group">
            <label class="form-label">用户名</label>
            <input type="text" id="username" class="input" placeholder="请输入用户名" required />
          </div>
          <div class="form-group">
            <label class="form-label">密码</label>
            <input type="password" id="password" class="input" placeholder="请输入密码" required />
          </div>
          <div id="login-error" class="form-error" style="display:none"></div>
          <button type="submit" class="btn btn-primary" style="width:100%">登录</button>
        </form>
      </div>
    </div>
  `;
}

function renderLayout(content) {
  return `
    <div class="layout">
      <aside class="sidebar">
        <div class="sidebar-header">
          <h1>DNF Admin</h1>
        </div>
        <nav class="sidebar-nav">
          <div class="nav-section">
            <div class="nav-section-title">概览</div>
            <a class="nav-item ${state.currentView === 'dashboard' ? 'active' : ''}" data-view="dashboard">
              <span class="nav-item-icon">📊</span>
              <span class="nav-item-text">控制台</span>
            </a>
          </div>
          <div class="nav-section">
            <div class="nav-section-title">数据管理</div>
            <a class="nav-item ${state.currentView === 'pvf' ? 'active' : ''}" data-view="pvf">
              <span class="nav-item-icon">📦</span>
              <span class="nav-item-text">PVF 物品</span>
            </a>
            <a class="nav-item ${state.currentView === 'accounts' ? 'active' : ''}" data-view="accounts">
              <span class="nav-item-icon">👤</span>
              <span class="nav-item-text">账号管理</span>
            </a>
            <a class="nav-item ${state.currentView === 'characters' ? 'active' : ''}" data-view="characters">
              <span class="nav-item-icon">🎮</span>
              <span class="nav-item-text">角色管理</span>
            </a>
          </div>
          <div class="nav-section">
            <div class="nav-section-title">GM 工具</div>
            <a class="nav-item ${state.currentView === 'grant' ? 'active' : ''}" data-view="grant">
              <span class="nav-item-icon">🎁</span>
              <span class="nav-item-text">发放物品</span>
            </a>
            <a class="nav-item ${state.currentView === 'mail' ? 'active' : ''}" data-view="mail">
              <span class="nav-item-icon">📧</span>
              <span class="nav-item-text">发送邮件</span>
            </a>
          </div>
        </nav>
        <div style="padding: 16px; border-top: 1px solid rgba(255,255,255,0.1)">
          <div class="user-info" style="color: #fff">
            <div class="user-avatar">${state.me?.username?.[0]?.toUpperCase() || 'A'}</div>
            <span>${state.me?.username || 'Admin'}</span>
          </div>
        </div>
      </aside>
      <main class="main-content">
        <header class="header">
          <div class="header-left">
            <h2>${getViewTitle()}</h2>
          </div>
          <div class="header-right">
            <button class="btn btn-default" id="logout-btn">退出登录</button>
          </div>
        </header>
        <div class="content">
          ${content}
        </div>
      </main>
    </div>
  `;
}

function getViewTitle() {
  const titles = {
    dashboard: '控制台',
    pvf: 'PVF 物品管理',
    accounts: '账号管理',
    characters: '角色管理',
    grant: '发放物品',
    mail: '发送邮件'
  };
  return titles[state.currentView] || '控制台';
}

function renderDashboard() {
  return `
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-value">${state.pvfStats.total_items || 83977}</div>
        <div class="stat-label">PVF 物品总数</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${state.accounts?.items?.length || 0}</div>
        <div class="stat-label">账号数量</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${state.characters?.items?.length || 0}</div>
        <div class="stat-label">角色数量</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${state.pvfCategories?.length || 0}</div>
        <div class="stat-label">物品分类数</div>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <div class="card-title">快速入口</div>
      </div>
      <div class="card-body">
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
          <button class="btn btn-primary" style="height: 80px; font-size: 16px" data-view="pvf">
            📦 PVF 物品查询
          </button>
          <button class="btn btn-default" style="height: 80px; font-size: 16px" data-view="accounts">
            👤 账号管理
          </button>
          <button class="btn btn-default" style="height: 80px; font-size: 16px" data-view="characters">
            🎮 角色管理
          </button>
          <button class="btn btn-default" style="height: 80px; font-size: 16px" data-view="grant">
            🎁 发放物品
          </button>
        </div>
      </div>
    </div>
  `;
}

function renderCategoryTree() {
  const categories = state.pvfCategories || [];
  
  return `
    <div class="category-tree">
      <div class="category-tree-header">物品分类</div>
      <div class="tree-node ${state.selectedCategory === 'all' ? 'active' : ''}" data-category="all">
        <span class="tree-node-expand">📁</span>
        全部分类
        <span class="tree-node-count">${state.pvf?.total || 83977}</span>
      </div>
      ${categories.filter(c => c.id !== 'all').map(cat => `
        <div class="tree-node ${state.selectedCategory === cat.id ? 'active' : ''}" data-category="${cat.id}">
          <span class="tree-node-expand">${getCategoryIcon(cat.id)}</span>
          ${cat.name}
          <span class="tree-node-count">${cat.count}</span>
        </div>
      `).join('')}
    </div>
  `;
}

function getCategoryIcon(id) {
  const icons = {
    weapon: '⚔️',
    armor: '🛡️',
    accessory: '💍',
    title: '🏅',
    pet: '🐾',
    costume: '👔',
    consumable: '🧪',
    material: '📦',
    quest: '📜',
    other: '📄'
  };
  return icons[id] || '📄';
}

function renderPVFContent() {
  return `
    <div class="toolbar">
      <div class="toolbar-left">
        <input type="text" id="pvf-search" class="input input-search" 
               placeholder="搜索物品名称、ID..." value="${state.searchQuery}" />
        <button class="btn btn-primary" id="pvf-search-btn">搜索</button>
      </div>
      <div class="toolbar-right">
        <select id="pvf-page-size" class="select">
          <option value="20" ${state.pvf.pageSize === 20 ? 'selected' : ''}>20 条/页</option>
          <option value="50" ${state.pvf.pageSize === 50 ? 'selected' : ''}>50 条/页</option>
          <option value="100" ${state.pvf.pageSize === 100 ? 'selected' : ''}>100 条/页</option>
        </select>
      </div>
    </div>
    <div class="table-container">
      <table class="table">
        <thead>
          <tr>
            <th>名称</th>
            <th>物品 ID</th>
            <th>类型</th>
            <th>等级</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          ${renderPVFRows()}
        </tbody>
      </table>
    </div>
    ${renderPagination()}
  `;
}

function renderPVFRows() {
  const items = state.pvf.items || [];
  if (!items.length) {
    return `<tr><td colspan="5" class="table-empty">暂无数据</td></tr>`;
  }
  return items.map((item, index) => `
    <tr class="${state.selectedPVF?.id === item.id ? 'selected' : ''}" data-pvf-index="${index}">
      <td><strong>${item.name || '-'}</strong></td>
      <td><code>${item.id || '-'}</code></td>
      <td><span class="tag tag-blue">${item.type || item.category || '-'}</span></td>
      <td>${item.level || item.minimumLevel || '-'}</td>
      <td>
        <button class="btn btn-link btn-sm" data-detail="${index}">详情</button>
        <button class="btn btn-link btn-sm" data-grant="${index}">发放</button>
      </td>
    </tr>
  `).join('');
}

function renderPagination() {
  const { page, totalPages, total, pageSize } = state.pvf;
  if (totalPages <= 1) return '';
  
  const start = (page - 1) * pageSize + 1;
  const end = Math.min(page * pageSize, total);
  
  let buttons = [];
  
  // Previous
  buttons.push(`<button class="pagination-btn" data-page="${page - 1}" ${page === 1 ? 'disabled' : ''}>‹</button>`);
  
  // Page numbers
  const maxVisible = 5;
  let startPage = Math.max(1, page - Math.floor(maxVisible / 2));
  let endPage = Math.min(totalPages, startPage + maxVisible - 1);
  
  if (startPage > 1) {
    buttons.push(`<button class="pagination-btn" data-page="1">1</button>`);
    if (startPage > 2) buttons.push(`<span class="pagination-ellipsis">...</span>`);
  }
  
  for (let i = startPage; i <= endPage; i++) {
    buttons.push(`<button class="pagination-btn ${i === page ? 'active' : ''}" data-page="${i}">${i}</button>`);
  }
  
  if (endPage < totalPages) {
    if (endPage < totalPages - 1) buttons.push(`<span class="pagination-ellipsis">...</span>`);
    buttons.push(`<button class="pagination-btn" data-page="${totalPages}">${totalPages}</button>`);
  }
  
  // Next
  buttons.push(`<button class="pagination-btn" data-page="${page + 1}" ${page === totalPages ? 'disabled' : ''}>›</button>`);
  
  return `
    <div class="pagination">
      <div class="pagination-info">
        显示 ${start}-${end} 条，共 ${total} 条
      </div>
      <div class="pagination-buttons">
        ${buttons.join('')}
        <div class="pagination-jump">
          <span>跳至</span>
          <input type="number" id="page-jump" class="input" min="1" max="${totalPages}" value="${page}" />
          <span>页</span>
          <button class="btn btn-default btn-sm" id="page-jump-btn">确定</button>
        </div>
      </div>
    </div>
  `;
}

function renderDetailPanel() {
  const item = state.selectedPVF;
  if (!item) {
    return `
      <div class="detail-panel">
        <div class="detail-header">物品详情</div>
        <div class="detail-content">
          <div class="table-empty">请选择一个物品查看详情</div>
        </div>
      </div>
    `;
  }
  
  return `
    <div class="detail-panel">
      <div class="detail-header">物品详情</div>
      <div class="detail-content">
        <div class="detail-item">
          <div class="detail-label">名称</div>
          <div class="detail-value"><strong>${item.name || '-'}</strong></div>
        </div>
        <div class="detail-item">
          <div class="detail-label">物品 ID</div>
          <div class="detail-value"><code>${item.id || '-'}</code></div>
        </div>
        <div class="detail-item">
          <div class="detail-label">类型</div>
          <div class="detail-value"><span class="tag tag-blue">${item.type || item.category || '-'}</span></div>
        </div>
        <div class="detail-item">
          <div class="detail-label">等级</div>
          <div class="detail-value">${item.level || item.minimumLevel || '-'}</div>
        </div>
        ${item.description ? `
        <div class="detail-item">
          <div class="detail-label">描述</div>
          <div class="detail-value">${item.description}</div>
        </div>
        ` : ''}
        <div class="detail-actions">
          <button class="btn btn-primary" id="detail-grant-btn">发放此物品</button>
          <button class="btn btn-default" id="detail-mail-btn">发送邮件</button>
        </div>
      </div>
    </div>
  `;
}

function renderPVFView() {
  return `
    <div style="display: flex; gap: 24px; height: calc(100vh - 180px);">
      ${renderCategoryTree()}
      <div style="flex: 1; overflow: hidden; display: flex; flex-direction: column;">
        <div class="card" style="flex: 1; overflow: hidden; display: flex; flex-direction: column;">
          <div class="card-body" style="flex: 1; overflow-y: auto;">
            ${renderPVFContent()}
          </div>
        </div>
      </div>
      ${renderDetailPanel()}
    </div>
  `;
}

function renderAccountsView() {
  return `
    <div class="card">
      <div class="card-header">
        <div class="card-title">账号列表</div>
      </div>
      <div class="card-body">
        <div class="toolbar">
          <input type="text" id="account-search" class="input input-search" placeholder="搜索账号..." />
          <button class="btn btn-primary" id="account-search-btn">搜索</button>
        </div>
        <table class="table">
          <thead>
            <tr>
              <th>账号</th>
              <th>UID</th>
              <th>状态</th>
              <th>角色数</th>
            </tr>
          </thead>
          <tbody>
            ${(state.accounts?.items || []).map(acc => `
              <tr>
                <td>${acc.username}</td>
                <td>${acc.id}</td>
                <td><span class="tag tag-green">${acc.status || '正常'}</span></td>
                <td>${acc.roles || '-'}</td>
              </tr>
            `).join('') || '<tr><td colspan="4" class="table-empty">暂无数据</td></tr>'}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderCharactersView() {
  return `
    <div class="card">
      <div class="card-header">
        <div class="card-title">角色列表</div>
      </div>
      <div class="card-body">
        <div class="toolbar">
          <input type="text" id="character-search" class="input input-search" placeholder="搜索角色..." />
          <button class="btn btn-primary" id="character-search-btn">搜索</button>
        </div>
        <table class="table">
          <thead>
            <tr>
              <th>角色名</th>
              <th>ID</th>
              <th>职业</th>
              <th>等级</th>
              <th>账号</th>
            </tr>
          </thead>
          <tbody>
            ${(state.characters?.items || []).map(char => `
              <tr>
                <td>${char.name}</td>
                <td>${char.id}</td>
                <td>${char.job}</td>
                <td>${char.level}</td>
                <td>${char.account_id}</td>
              </tr>
            `).join('') || '<tr><td colspan="5" class="table-empty">暂无数据</td></tr>'}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderView() {
  let content = '';
  
  switch (state.currentView) {
    case 'dashboard':
      content = renderDashboard();
      break;
    case 'pvf':
      content = renderPVFView();
      break;
    case 'accounts':
      content = renderAccountsView();
      break;
    case 'characters':
      content = renderCharactersView();
      break;
    default:
      content = renderDashboard();
  }
  
  return renderLayout(content);
}

// API Functions
async function loadPVFData() {
  const data = await fetchPVFItems(
    state.searchQuery,
    state.selectedCategory === 'all' ? '' : state.selectedCategory,
    state.pvf.page,
    state.pvf.pageSize
  );
  state.pvf = {
    items: data.items || [],
    total: data.total || 0,
    page: data.page || 1,
    pageSize: data.page_size || 20,
    totalPages: data.total_pages || 0
  };
}

async function loadCategories() {
  const data = await fetchPVFCategories();
  state.pvfCategories = data.categories || [];
}

async function loadStats() {
  state.pvfStats = await fetchPVFStats();
}

async function loadAccounts() {
  state.accounts = await fetchAccounts('', 100);
}

async function loadCharacters() {
  state.characters = await fetchCharacters('', 100);
}

// Event Handlers
async function handleLogin(e) {
  e.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  const errorEl = document.getElementById('login-error');
  
  try {
    const result = await login(username, password);
    state.me = { username };
    await initApp();
  } catch (err) {
    errorEl.textContent = err.message || '登录失败';
    errorEl.style.display = 'block';
  }
}

function handleLogout() {
  clearStoredToken();
  state.me = null;
  render();
}

function handleViewChange(view) {
  state.currentView = view;
  state.selectedPVF = null;
  render();
  
  // Load data for the view
  if (view === 'pvf') {
    loadPVFData();
  } else if (view === 'accounts') {
    loadAccounts();
  } else if (view === 'characters') {
    loadCharacters();
  }
}

async function handlePVFSearch() {
  state.searchQuery = document.getElementById('pvf-search')?.value || '';
  state.pvf.page = 1;
  await loadPVFData();
  render();
}

async function handleCategoryChange(category) {
  state.selectedCategory = category;
  state.pvf.page = 1;
  state.selectedPVF = null;
  await loadPVFData();
  render();
}

async function handlePageChange(page) {
  if (page < 1 || page > state.pvf.totalPages) return;
  state.pvf.page = page;
  state.selectedPVF = null;
  await loadPVFData();
  render();
}

function handlePVFSelect(index) {
  state.selectedPVF = state.pvf.items[index];
  render();
}

async function handlePageSizeChange() {
  const select = document.getElementById('pvf-page-size');
  if (select) {
    state.pvf.pageSize = parseInt(select.value);
    state.pvf.page = 1;
    await loadPVFData();
    render();
  }
}

async function handlePageJump() {
  const input = document.getElementById('page-jump');
  if (input) {
    const page = parseInt(input.value);
    if (page >= 1 && page <= state.pvf.totalPages) {
      await handlePageChange(page);
    }
  }
}

// Bind Events
function bindEvents() {
  // Login form
  const loginForm = document.getElementById('login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', handleLogin);
    return;
  }
  
  // Logout
  document.getElementById('logout-btn')?.addEventListener('click', handleLogout);
  
  // Navigation
  document.querySelectorAll('.nav-item, [data-view]').forEach(el => {
    el.addEventListener('click', (e) => {
      const view = e.currentTarget.dataset.view;
      if (view) handleViewChange(view);
    });
  });
  
  // PVF Search
  document.getElementById('pvf-search-btn')?.addEventListener('click', handlePVFSearch);
  document.getElementById('pvf-search')?.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handlePVFSearch();
  });
  
  // Category Tree
  document.querySelectorAll('[data-category]').forEach(el => {
    el.addEventListener('click', () => handleCategoryChange(el.dataset.category));
  });
  
  // PVF Rows
  document.querySelectorAll('[data-pvf-index]').forEach(el => {
    el.addEventListener('click', () => handlePVFSelect(parseInt(el.dataset.pvfIndex)));
  });
  
  // Detail buttons
  document.querySelectorAll('[data-detail]').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      handlePVFSelect(parseInt(el.dataset.detail));
    });
  });
  
  document.querySelectorAll('[data-grant]').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      // TODO: Grant item
    });
  });
  
  // Pagination
  document.querySelectorAll('[data-page]').forEach(el => {
    el.addEventListener('click', () => handlePageChange(parseInt(el.dataset.page)));
  });
  
  // Page size
  document.getElementById('pvf-page-size')?.addEventListener('change', handlePageSizeChange);
  
  // Page jump
  document.getElementById('page-jump-btn')?.addEventListener('click', handlePageJump);
  document.getElementById('page-jump')?.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handlePageJump();
  });
  
  // Detail actions
  document.getElementById('detail-grant-btn')?.addEventListener('click', () => {
    // TODO: Grant selected item
  });
  
  document.getElementById('detail-mail-btn')?.addEventListener('click', () => {
    // TODO: Send mail with item
  });
}

// Render
function render() {
  app.innerHTML = state.me ? renderView() : renderLogin();
  bindEvents();
}

// Initialize
async function initApp() {
  await Promise.all([
    loadCategories(),
    loadStats(),
    loadAccounts(),
    loadCharacters()
  ]);
  
  if (state.currentView === 'pvf') {
    await loadPVFData();
  }
  
  render();
}

// Check if already logged in
async function init() {
  const token = localStorage.getItem('dnf_public_admin_token');
  if (token) {
    try {
      state.me = { username: 'admin' }; // TODO: Get from API
      await initApp();
    } catch (err) {
      render();
    }
  } else {
    render();
  }
}

init();
