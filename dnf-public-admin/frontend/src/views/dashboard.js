function badgeColor(status) {
  if (status === 'active') return '#10b981';
  if (status === 'in-progress') return '#f59e0b';
  if (status === 'scheduled') return '#2563eb';
  if (status === 'planned') return '#6b7280';
  if (status === 'draft') return '#9ca3af';
  if (status === 'disabled') return '#4b5563';
  return '#6b7280';
}

function riskColor(level) {
  if (level === 'high') return '#dc2626';
  if (level === 'medium') return '#f59e0b';
  return '#2563eb';
}

function sourceText(source) {
  if (source === 'native') return '原生';
  if (source === 'pvf_mapped') return 'PVF 映射';
  if (source === 'custom') return '自定义';
  return source;
}

function renderModules(data) {
  return data.modules.map((item) => `
    <article class="card">
      <div class="card-head">
        <h3>${item.name}</h3>
        <span class="badge" style="background:${badgeColor(item.status)}">${item.status}</span>
      </div>
      <p class="muted">模块标识：${item.key}</p>
    </article>
  `).join('');
}

function renderPermissions(data) {
  return data.permissions.map((item) => `
    <tr>
      <td>${item.name}</td>
      <td>${item.key}</td>
      <td>${item.access}</td>
    </tr>
  `).join('');
}

function renderAudit(actions) {
  return actions.map((item) => `
    <tr>
      <td>${item.name}</td>
      <td>${item.key}</td>
      <td><span class="risk" style="color:${riskColor(item.risk_level)}">${item.risk_level}</span></td>
      <td>${item.description}</td>
    </tr>
  `).join('');
}

function renderActivityRows(items) {
  return items.map((item) => `
    <tr>
      <td>${item.name}</td>
      <td>${item.type}</td>
      <td>${sourceText(item.source)}</td>
      <td><span class="badge" style="background:${badgeColor(item.status)}">${item.status}</span></td>
      <td>${item.start_at}</td>
      <td>${item.end_at}</td>
      <td>${item.description}</td>
    </tr>
  `).join('');
}

function renderCalendar(days) {
  return days.map((day) => `
    <article class="calendar-card">
      <div class="calendar-date">${day.date}</div>
      <div class="calendar-items">
        ${day.items.map((item) => `<div class="calendar-item"><strong>${item.name}</strong><span>${sourceText(item.source)} · ${item.status}</span></div>`).join('')}
      </div>
    </article>
  `).join('');
}

function renderNative(items) {
  return items.map((item) => `
    <article class="card">
      <div class="card-head">
        <h3>${item.name}</h3>
        <span class="badge" style="background:${badgeColor(item.status)}">${item.status}</span>
      </div>
      <p class="muted">${item.code} · ${item.control_mode}</p>
      <p>${item.description}</p>
    </article>
  `).join('');
}

export function renderDashboard({ modules, audit, me, activities, calendar, nativeActivities }) {
  return `
    <main class="shell">
      <aside class="sidebar">
        <div class="brand">DNF Admin</div>
        <nav>
          <a href="#overview">总览</a>
          <a href="#modules">模块</a>
          <a href="#activities">活动列表</a>
          <a href="#calendar">活动日历</a>
          <a href="#native">原生活动</a>
          <a href="#permissions">权限</a>
          <a href="#audit">审计</a>
        </nav>
      </aside>

      <section class="content">
        <header class="hero" id="overview">
          <div>
            <h1>融合版 DNF 后台演示台</h1>
            <p>当前版本已融合旧后台业务路径与新管理台结构，并加入活动管理中心首版雏形，可作为账号、角色、GM、PVF、活动的一体化运营中台基础。</p>
          </div>
          <div class="hero-card">
            <div class="hero-label">当前管理员</div>
            <div class="hero-user">${me.user.username}</div>
            <div class="muted">角色：${me.user.role}</div>
          </div>
        </header>

        <section id="modules">
          <div class="section-head">
            <h2>模块状态</h2>
            <p>后端 `/api/v1/meta/modules` 提供。</p>
          </div>
          <div class="grid">${renderModules(modules)}</div>
        </section>

        <section id="activities">
          <div class="section-head">
            <h2>活动列表视图</h2>
            <p>融合原生、PVF 映射、自定义三类活动来源。</p>
          </div>
          <div class="panel">
            <table>
              <thead>
                <tr><th>活动名称</th><th>类型</th><th>来源</th><th>状态</th><th>开始</th><th>结束</th><th>说明</th></tr>
              </thead>
              <tbody>${renderActivityRows(activities.items)}</tbody>
            </table>
          </div>
        </section>

        <section id="calendar">
          <div class="section-head">
            <h2>活动日历视图</h2>
            <p>适合运营排期、活动重叠观察与节日规划。</p>
          </div>
          <div class="calendar-grid">${renderCalendar(calendar.days)}</div>
        </section>

        <section id="native">
          <div class="section-head">
            <h2>原生活动控制视图</h2>
            <p>展示服务端真实活动开关与同步能力入口的承载位。</p>
          </div>
          <div class="grid">${renderNative(nativeActivities.items)}</div>
        </section>

        <section id="permissions">
          <div class="section-head">
            <h2>默认权限矩阵</h2>
            <p>基于 RBAC 骨架的模块级权限映射。</p>
          </div>
          <div class="panel">
            <table>
              <thead>
                <tr><th>模块</th><th>Key</th><th>Access</th></tr>
              </thead>
              <tbody>${renderPermissions(modules)}</tbody>
            </table>
          </div>
        </section>

        <section id="audit">
          <div class="section-head">
            <h2>审计动作</h2>
            <p>高风险操作将以审计清单驱动留痕与二次确认。</p>
          </div>
          <div class="panel">
            <table>
              <thead>
                <tr><th>动作</th><th>Key</th><th>风险</th><th>说明</th></tr>
              </thead>
              <tbody>${renderAudit(audit.actions)}</tbody>
            </table>
          </div>
        </section>
      </section>
    </main>
  `;
}
