function safeArray(value) {
  return Array.isArray(value) ? value : [];
}

function statusTone(status) {
  if (status === 'active') return 'success';
  if (status === 'in-progress') return 'warning';
  if (status === 'scheduled') return 'info';
  if (status === 'planned') return 'muted';
  if (status === 'disabled') return 'dark';
  return 'muted';
}

function renderSummaryCards(data) {
  const cards = [
    { label: '账号总览', value: safeArray(data.accounts?.items).length, hint: '当前查询窗口内账号数' },
    { label: '角色总览', value: safeArray(data.characters?.items).length, hint: '当前查询窗口内角色数' },
    { label: '活动数量', value: safeArray(data.activities?.items).length, hint: '活动 / 排期条目' },
    { label: '审计动作', value: safeArray(data.audit?.actions).length, hint: '高风险动作基线' }
  ];
  return cards.map((item) => `
    <article class="summary-card">
      <div class="summary-label">${item.label}</div>
      <div class="summary-value">${item.value}</div>
      <div class="summary-hint">${item.hint}</div>
    </article>
  `).join('');
}

function renderModuleTiles(modules) {
  return safeArray(modules).map((item) => `
    <article class="module-tile">
      <div>
        <div class="module-title">${item.name}</div>
        <div class="module-key">${item.key}</div>
      </div>
      <span class="tone-badge ${statusTone(item.status)}">${item.status}</span>
    </article>
  `).join('');
}

function renderAccountTable(items) {
  const list = safeArray(items);
  if (!list.length) return '<tr><td colspan="4" class="muted">未找到账号记录</td></tr>';
  return list.map((item, index) => `
    <tr class="selectable-row" data-account-row="${index}">
      <td>${item.username}</td>
      <td>${item.id}</td>
      <td>${item.status}</td>
      <td>${item.roles}</td>
    </tr>
  `).join('');
}

function renderCharacterTable(items) {
  const list = safeArray(items);
  if (!list.length) return '<tr><td colspan="5" class="muted">未找到角色记录</td></tr>';
  return list.map((item, index) => `
    <tr class="selectable-row" data-character-row="${index}">
      <td>${item.name}</td>
      <td>${item.id}</td>
      <td>${item.job}</td>
      <td>${item.level}</td>
      <td>${item.account_id}</td>
    </tr>
  `).join('');
}

function renderPvfRows(items) {
  const list = safeArray(items);
  if (!list.length) return '<tr><td colspan="4" class="muted">暂无 PVF 物品结果</td></tr>';
  return list.map((item, index) => `
    <tr class="selectable-row" data-pvf-row="${index}">
      <td>${item.name || '-'}</td>
      <td>${item.id || '-'}</td>
      <td>${item.type || item.category || '-'}</td>
      <td>${item.level || item.minimumLevel || '-'}</td>
    </tr>
  `).join('');
}

function renderAuditRows(actions) {
  const list = safeArray(actions);
  if (!list.length) return '<tr><td colspan="4" class="muted">暂无审计动作</td></tr>';
  return list.map((item) => `
    <tr>
      <td>${item.name}</td>
      <td>${item.key}</td>
      <td>${item.risk_level}</td>
      <td>${item.description}</td>
    </tr>
  `).join('');
}

function renderActivityRows(items) {
  const list = safeArray(items);
  if (!list.length) return '<tr><td colspan="6" class="muted">暂无活动数据</td></tr>';
  return list.map((item) => `
    <tr>
      <td>${item.name}</td>
      <td>${item.type}</td>
      <td>${item.source}</td>
      <td>${item.status}</td>
      <td>${item.start_at}</td>
      <td>${item.end_at}</td>
    </tr>
  `).join('');
}

function renderAccountSummary(item) {
  if (!item) {
    return '<div id="selected-account-summary" class="empty-state">选择左侧账号后，这里展示账号详情、角色、风险状态与快捷操作。</div>';
  }
  return `
    <div id="selected-account-summary" class="entity-summary">
      <div class="entity-title">${item.username}</div>
      <div class="detail-group-grid">
        <section class="detail-group">
          <h4>账号基础信息</h4>
          <dl class="detail-list compact">
            <div><dt>账号基础信息</dt><dd>${item.id}</dd></div>
            <div><dt>当前状态</dt><dd>${item.status}</dd></div>
            <div><dt>角色摘要</dt><dd>${item.roles} 个角色位</dd></div>
            <div><dt>最近登录</dt><dd>${item.last_login || '最近登录时间待接真实只读源'}</dd></div>
          </dl>
        </section>
        <section class="detail-group">
          <h4>风险与运营</h4>
          <dl class="detail-list compact">
            <div><dt>风险状态</dt><dd>${item.risk_state || '默认正常，后续接风控标签'}</dd></div>
            <div><dt>货币 / 邮件摘要</dt><dd>点券、金币、邮件入口已与 GM 工作台联动</dd></div>
          </dl>
        </section>
      </div>
      <div class="detail-actions">
        <button class="secondary-btn" type="button">发送邮件</button>
        <button class="secondary-btn" type="button">充值点券</button>
        <button class="secondary-btn" type="button">封禁 / 解封</button>
      </div>
    </div>
  `;
}

function renderCharacterSummary(item) {
  if (!item) {
    return '<div id="selected-character-summary" class="empty-state">选择左侧角色后，这里展示角色详情、装备摘要、背包摘要和 GM 快捷入口。</div>';
  }
  return `
    <div id="selected-character-summary" class="entity-summary">
      <div class="entity-title">${item.name}</div>
      <div class="detail-group-grid">
        <section class="detail-group">
          <h4>角色基础信息</h4>
          <dl class="detail-list compact">
            <div><dt>角色 ID</dt><dd>${item.id}</dd></div>
            <div><dt>职业</dt><dd>${item.job}</dd></div>
            <div><dt>等级</dt><dd>${item.level}</dd></div>
            <div><dt>账号 UID</dt><dd>${item.account_id}</dd></div>
          </dl>
        </section>
        <section class="detail-group">
          <h4>角色摘要</h4>
          <dl class="detail-list compact">
            <div><dt>装备栏位</dt><dd>${item.equipment_slots || 12} 个槽位（主武器 / 防具 / 首饰）</dd></div>
            <div><dt>背包槽位</dt><dd>${item.inventory_slots || 56} 个槽位（材料、消耗品、礼包）</dd></div>
            <div><dt>装备 / 背包摘要</dt><dd>详情区已预留，下一步接真实数据</dd></div>
            <div><dt>邮件数量</dt><dd>${item.mail_count || 0} 封未读邮件</dd></div>
            <div><dt>货币 / 邮件摘要</dt><dd>${item.currency_state || '详情区已预留，下一步接真实数据'}</dd></div>
          </dl>
        </section>
      </div>
      <div class="detail-actions">
        <button class="secondary-btn" type="button">发放物品</button>
        <button class="secondary-btn" type="button">发送邮件</button>
      </div>
    </div>
  `;
}

function renderPvfSummary(item, stats) {
  if (!item) {
    return `
      <div id="selected-pvf-summary" class="entity-summary">
        <div class="entity-title">详情面板</div>
        <dl class="detail-list compact">
          <div><dt>当前状态</dt><dd>${stats?.pvf_loaded ? '已加载' : '待接真实索引'}</dd></div>
          <div><dt>PVF 路径</dt><dd>${stats?.pvf_path || '-'}</dd></div>
          <div><dt>加载错误</dt><dd>${stats?.last_error || '无'}</dd></div>
          <div><dt>Bridge</dt><dd>${stats?.bridge_available ? '可用' : '不可用'}</dd></div>
        </dl>
      </div>
    `;
  }
  return `
    <div id="selected-pvf-summary" class="entity-summary">
      <div class="entity-title">${item.name || '-'}</div>
      <dl class="detail-list compact">
        <div><dt>物品 ID</dt><dd>${item.id || '-'}</dd></div>
        <div><dt>类型</dt><dd>${item.type || item.category || '-'}</dd></div>
        <div><dt>等级</dt><dd>${item.level || item.minimumLevel || '-'}</dd></div>
      </dl>
      <div class="detail-actions">
        <button id="pvf-apply-grant" class="primary-btn" type="button">带入发放</button>
        <button id="pvf-apply-mail" class="secondary-btn" type="button">带入邮件附件</button>
      </div>
    </div>
  `;
}

function renderConfirmPanel(data) {
  const pending = data.pendingAction;
  return `
    <section class="workspace-block" id="confirm-workspace">
      <div class="block-head">
        <div>
          <h2>操作确认</h2>
          <p>高风险操作统一进入确认层，避免后台变成“点了就发”。</p>
        </div>
      </div>
      <section class="panel confirm-panel">
        <h3>待提交动作</h3>
        ${pending ? `
          <dl class="detail-list compact">
            <div><dt>动作类型</dt><dd>${pending.label}</dd></div>
            <div><dt>目标对象</dt><dd>${pending.target || '-'}</dd></div>
            <div><dt>摘要</dt><dd>${pending.summary || '-'}</dd></div>
          </dl>
        ` : '<div class="empty-state">当前没有待确认动作。你可以从 GM 操作台先填表，再进入确认层。</div>'}
        <div class="detail-actions">
          <button id="confirm-submit-btn" class="primary-btn" type="button">确认提交</button>
          <button id="confirm-cancel-btn" class="secondary-btn" type="button">取消确认</button>
        </div>
      </section>
    </section>
  `;
}

export function renderPvfWorkspace(data) {
  const pvf = data.pvf || { items: [], total: 0, page: 1, page_size: 20, total_pages: 0 };
  const categories = data.pvfCategories || [];
  const selectedCategory = data.selectedCategory || 'all';
  
  // Render category filter
  let categoryHtml = '<ul class="category-list">';
  categories.forEach(cat => {
    const isActive = (selectedCategory === cat.id) || (!selectedCategory && cat.id === 'all');
    categoryHtml += `<li class="category-item ${isActive ? 'active' : ''}" data-category="${cat.id}">${cat.name} (${cat.count})</li>`;
  });
  categoryHtml += '</ul>';
  
  // Render pagination
  let paginationHtml = '';
  if (pvf.total_pages > 1) {
    const startItem = (pvf.page - 1) * pvf.page_size + 1;
    const endItem = Math.min(pvf.page * pvf.page_size, pvf.total);
    
    paginationHtml = `<div class="pagination-controls"><div class="pagination-info">显示 ${startItem}-${endItem} / 共 ${pvf.total} 件物品</div><div class="pagination-buttons">`;
    
    if (pvf.page > 1) {
      paginationHtml += `<button class="secondary-btn pvf-page-btn" data-page="${pvf.page - 1}">上一页</button>`;
    }
    
    const maxVisible = 5;
    let startP = Math.max(1, pvf.page - Math.floor(maxVisible / 2));
    let endP = Math.min(pvf.total_pages, startP + maxVisible - 1);
    if (endP - startP + 1 < maxVisible) startP = Math.max(1, endP - maxVisible + 1);
    
    if (startP > 1) {
      paginationHtml += `<button class="secondary-btn pvf-page-btn" data-page="1">1</button>`;
      if (startP > 2) paginationHtml += '<span class="pagination-ellipsis">...</span>';
    }
    for (let i = startP; i <= endP; i++) {
      if (i === pvf.page) {
        paginationHtml += `<button class="primary-btn pvf-page-btn active" data-page="${i}">${i}</button>`;
      } else {
        paginationHtml += `<button class="secondary-btn pvf-page-btn" data-page="${i}">${i}</button>`;
      }
    }
    if (endP < pvf.total_pages) {
      if (endP < pvf.total_pages - 1) paginationHtml += '<span class="pagination-ellipsis">...</span>';
      paginationHtml += `<button class="secondary-btn pvf-page-btn" data-page="${pvf.total_pages}">${pvf.total_pages}</button>`;
    }
    if (pvf.page < pvf.total_pages) {
      paginationHtml += `<button class="secondary-btn pvf-page-btn" data-page="${pvf.page + 1}">下一页</button>`;
    }
    paginationHtml += '</div></div>';
  }
  
  return `
    <section class="workspace-block" id="pvf-workspace">
      <div class="block-head">
        <div>
          <h2>PVF 物品工作台</h2>
          <p>按旧版后台习惯保留物品检索、结果表格、详情预览与发放联动入口。</p>
        </div>
        <div class="inline-actions">
          <button id="pvf-refresh-btn" class="secondary-btn" type="button">刷新 PVF</button>
          <button id="pvf-quick-grant-btn" class="primary-btn" type="button">加入发放清单</button>
        </div>
      </div>
      <div class="workspace-grid pvf-grid">
        <aside class="panel category-panel">
          <h3>分类导航</h3>
          <div id="pvf-categories">${categoryHtml}</div>
        </aside>
        <section class="panel">
          <div class="toolbar">
            <input id="pvf-search-input" class="toolbar-input" placeholder="搜索物品名 / 物品ID / 类型" />
            <button id="pvf-search-btn" class="primary-btn" type="button">搜索物品</button>
          </div>
          <table>
            <thead>
              <tr><th>名称</th><th>ID</th><th>类型</th><th>等级</th></tr>
            </thead>
            <tbody id="pvf-items-tbody">${renderPvfRows(pvf.items)}</tbody>
          </table>
          <div id="pvf-pagination">${paginationHtml}</div>
        </section>
        <aside class="panel detail-panel">${renderPvfSummary(data.selectedPVF, data.pvfStats)}</aside>
      </div>
    </section>
  `;
}

export function renderGMWorkspace(data) {
  return `
    <section class="workspace-block" id="gm-workspace">
      <div class="block-head">
        <div>
          <h2>GM 操作台</h2>
          <p>把旧版常用 GM 流程重组为可审计的表单工作区。</p>
        </div>
      </div>
      <div class="gm-grid">
        <section class="panel action-panel">
          <h3>发放物品</h3>
          <form class="form-grid">
            <input id="grant-character-input" placeholder="目标角色 ID / 名称" value="${data.selectedCharacter?.id || ''}" />
            <input id="grant-item-input" placeholder="物品 ID / 已选物品" value="${data.selectedPVF?.id || ''}" />
            <input id="grant-qty-input" placeholder="数量" value="1" />
            <textarea placeholder="发放原因">${data.selectedPVF ? `运营发放：${data.selectedPVF.name || data.selectedPVF.id}` : ''}</textarea>
            <div id="grant-feedback" class="action-feedback ${data.feedback?.grant ? "visible" : ""}">${data.feedback?.grant || "写操作仍受控：当前先生成 dry-run 计划。"}</div>
            <button id="grant-submit-btn" class="primary-btn" type="button">提交发放</button>
          </form>
        </section>
        <section class="panel action-panel">
          <h3>发送邮件</h3>
          <form class="form-grid">
            <input id="mail-target-input" placeholder="目标角色 / 账号" value="${data.selectedCharacter?.name || data.selectedAccount?.username || ''}" />
            <input id="mail-title-input" placeholder="邮件标题" value="${data.selectedPVF ? `附件：${data.selectedPVF.name || data.selectedPVF.id}` : ''}" />
            <textarea id="mail-body-input" placeholder="邮件内容"></textarea>
            <input id="mail-attachment-input" placeholder="附件物品 / 礼包" value="${data.selectedPVF?.id || ''}" />
            <div id="mail-feedback" class="action-feedback ${data.feedback?.mail ? "visible" : ""}">${data.feedback?.mail || "写操作仍受控：邮件发送暂未放行。"}</div>
            <button id="mail-submit-btn" class="primary-btn" type="button">提交邮件</button>
          </form>
        </section>
        <section class="panel action-panel">
          <h3>封禁 / 解封</h3>
          <form class="form-grid">
            <input id="ban-target-input" placeholder="目标账号 / 角色" value="${data.selectedAccount?.username || data.selectedCharacter?.name || ''}" />
            <input id="ban-until-input" placeholder="时长 / 结束时间" />
            <textarea id="ban-reason-input" placeholder="封禁原因"></textarea>
            <div id="ban-feedback" class="action-feedback ${data.feedback?.ban ? "visible" : ""}">${data.feedback?.ban || "写操作仍受控：封禁 / 解封暂未放行。"}</div>
            <button id="ban-submit-btn" class="secondary-btn" type="button">提交状态变更</button>
          </form>
        </section>
        <section class="panel action-panel">
          <h3>充值点券</h3>
          <form class="form-grid">
            <input id="recharge-target-input" placeholder="目标账号" value="${data.selectedAccount?.username || ''}" />
            <input id="recharge-amount-input" placeholder="充值数量" />
            <textarea id="recharge-reason-input" placeholder="渠道 / 原因"></textarea>
            <div id="recharge-feedback" class="action-feedback ${data.feedback?.recharge ? "visible" : ""}">${data.feedback?.recharge || "写操作仍受控：充值点券暂未放行。"}</div>
            <button id="recharge-submit-btn" class="secondary-btn" type="button">提交充值</button>
          </form>
        </section>
      </div>
    </section>
  `;
}

export function renderWorkbenchShell(data) {
  const modules = data.modules?.modules || data.modules || [];
  return `
    <main class="shell workbench-shell">
      <aside class="sidebar admin-sidebar">
        <div class="brand">DNF Admin</div>
        <div class="sidebar-subtitle">旧版体验 / 新架构工作台</div>
        <nav>
          <a href="#overview">工作台总览</a>
          <a href="#account-workspace">账号工作台</a>
          <a href="#character-workspace">角色工作台</a>
          <a href="#pvf-workspace">PVF 物品工作台</a>
          <a href="#gm-workspace">GM 操作台</a>
          <a href="#confirm-workspace">操作确认</a>
          <a href="#activity-workspace">活动与审计</a>
          <button id="logout-btn" class="logout-btn">退出登录</button>
        </nav>
      </aside>

      <section class="content workbench-content">
        <header class="topbar">
          <div>
            <div class="breadcrumb">控制台 / 旧版兼容工作台</div>
            <h1>工作台总览</h1>
          </div>
          <div class="topbar-actions">
            <input class="toolbar-input top-search" placeholder="全局搜索账号 / 角色 / 物品" />
            <div class="operator-card">
              <strong>${data.me?.user?.username || 'gmadmin'}</strong>
              <span>${data.me?.user?.role || 'super_admin'}</span>
            </div>
          </div>
        </header>

        <section id="overview" class="workspace-block">
          <div class="block-head">
            <div>
              <h2>工作台总览</h2>
              <p>先把旧后台的骨架和工作流立住，再逐步替换成真实写控与明细接口。</p>
            </div>
          </div>
          <div class="summary-grid">${renderSummaryCards(data)}</div>
          <div class="module-grid">${renderModuleTiles(modules)}</div>
        </section>

        <section id="account-workspace" class="workspace-block">
          <div class="block-head">
            <div>
              <h2>账号工作台</h2>
              <p>先查账号，再展开角色和风险状态，保留旧后台运营节奏。</p>
            </div>
          </div>
          <div class="workspace-grid dual-grid">
            <section class="panel">
              <div class="toolbar">
                <input id="account-search-input" class="toolbar-input" placeholder="搜索账号 / UID / 手机号" />
                <button id="account-search-btn" class="primary-btn" type="button">搜索账号</button>
              </div>
              <table>
                <thead><tr><th>账号</th><th>UID</th><th>状态</th><th>角色标记</th></tr></thead>
                <tbody id="accounts-tbody">${renderAccountTable(data.accounts?.items)}</tbody>
              </table>
            </section>
            <aside id="account-detail-panel" class="panel detail-panel">${renderAccountSummary(data.selectedAccount)}</aside>
          </div>
        </section>

        <section id="character-workspace" class="workspace-block">
          <div class="block-head">
            <div>
              <h2>角色工作台</h2>
              <p>列表负责定位，详情负责装备、背包、邮件、货币与 GM 联动。</p>
            </div>
          </div>
          <div class="workspace-grid dual-grid">
            <section class="panel">
              <div class="toolbar">
                <input id="character-search-input" class="toolbar-input" placeholder="搜索角色 / 角色ID / 账号 / 职业" />
                <button id="character-search-btn" class="primary-btn" type="button">搜索角色</button>
              </div>
              <table>
                <thead><tr><th>角色名</th><th>角色ID</th><th>职业</th><th>等级</th><th>账号UID</th></tr></thead>
                <tbody id="characters-tbody">${renderCharacterTable(data.characters?.items)}</tbody>
              </table>
            </section>
            <aside id="character-detail-panel" class="panel detail-panel">${renderCharacterSummary(data.selectedCharacter)}</aside>
          </div>
        </section>

        ${renderPvfWorkspace(data)}
        ${renderGMWorkspace(data)}
        ${renderConfirmPanel(data)}

        <section id="activity-workspace" class="workspace-block">
          <div class="block-head">
            <div>
              <h2>活动与审计</h2>
              <p>活动排期与高风险动作都保留独立工作区，而不是塞进说明卡片。</p>
            </div>
          </div>
          <div class="workspace-grid dual-grid">
            <section class="panel">
              <h3>活动列表</h3>
              <table>
                <thead><tr><th>活动</th><th>类型</th><th>来源</th><th>状态</th><th>开始</th><th>结束</th></tr></thead>
                <tbody>${renderActivityRows(data.activities?.items)}</tbody>
              </table>
            </section>
            <section class="panel">
              <h3>审计日志</h3>
              <table>
                <thead><tr><th>动作</th><th>Key</th><th>风险</th><th>说明</th></tr></thead>
                <tbody>${renderAuditRows(data.audit?.actions)}</tbody>
              </table>
            </section>
          </div>
        </section>
      </section>
    </main>
  `;
}
