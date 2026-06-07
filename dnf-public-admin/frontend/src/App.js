const modules = [
  { key: 'auth', name: '认证与权限', desc: '管理员登录、JWT、RBAC、菜单权限', status: 'in-progress' },
  { key: 'account', name: '账号查询', desc: '只读查询 d_taiwan.accounts，先与旧后台结果对齐', status: 'in-progress' },
  { key: 'character', name: '角色查询', desc: '只读查询 taiwan_cain / taiwan_cain_2nd 角色数据', status: 'in-progress' },
  { key: 'activity', name: '活动管理', desc: '活动开关、活动日历、原生活动同步；写操作等待审计闭环', status: 'in-progress' },
  { key: 'pvf', name: 'PVF 检索', desc: '按名称 / ID / 分类检索道具与关键字段', status: 'planned' },
  { key: 'gm', name: 'GM 操作', desc: '发邮件、发物品、货币发放、二次确认', status: 'planned' },
  { key: 'audit', name: '审计日志', desc: '登录留痕、操作留痕、结果摘要', status: 'in-progress' }
];

const baseline = [
  { label: '旧后台 dnf-console', value: '882' },
  { label: 'Supervisor', value: '2000' },
  { label: 'Game Login', value: '3000' },
  { label: '账号库', value: 'd_taiwan' },
  { label: '登录库', value: 'taiwan_login' },
  { label: '计费库', value: 'taiwan_billing' }
];

function renderModuleCards() {
  return modules.map((item) => `
    <article style="border:1px solid #ddd;border-radius:12px;padding:16px;background:#fff;">
      <div style="display:flex;justify-content:space-between;align-items:center;gap:12px;">
        <h3 style="margin:0;font-size:18px;">${item.name}</h3>
        <span style="font-size:12px;padding:4px 8px;border-radius:999px;background:#f3f4f6;">${item.status}</span>
      </div>
      <p style="margin:12px 0 0;color:#555;line-height:1.6;">${item.desc}</p>
    </article>
  `).join('');
}

function renderBaseline() {
  return baseline.map((item) => `
    <div style="padding:12px;border-radius:10px;background:#f9fafb;border:1px solid #e5e7eb;">
      <div style="font-size:12px;color:#6b7280;">${item.label}</div>
      <strong style="display:block;margin-top:4px;">${item.value}</strong>
    </div>
  `).join('');
}

export function renderApp() {
  return `
    <main style="font-family: Inter, Arial, sans-serif; padding: 24px; max-width: 1080px; margin: 0 auto; background:#f7f7fb; min-height:100vh;">
      <header style="margin-bottom:24px;">
        <h1 style="margin-bottom:8px;">DNF Public Admin</h1>
        <p style="margin:0;color:#555;line-height:1.7;">面向 DNF 运营与 GM 的新后台。当前按 104 / dnf-llnut 历史规划推进：旧后台端口和旧游戏库保持为事实来源，新后台先只读核验，再逐步开放受控写操作。</p>
      </header>

      <section style="margin-bottom:24px;padding:20px;border-radius:12px;background:#fff;border:1px solid #e5e7eb;">
        <h2 style="margin-top:0;">旧后台兼容基线</h2>
        <p style="color:#555;line-height:1.7;">新后台不得复制或迁移游戏数据形成第二套事实来源。账号、角色、计费、活动状态默认继续读取现有 llnut 数据库。</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;">
          ${renderBaseline()}
        </div>
      </section>

      <section style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px;">
        ${renderModuleCards()}
      </section>

      <section style="margin-top:28px;padding:20px;border-radius:12px;background:#fff;border:1px solid #e5e7eb;">
        <h2 style="margin-top:0;">当前交付内容</h2>
        <ul style="line-height:1.8;color:#444;">
          <li>Go 后端健康检查、模块元信息、认证/RBAC/审计骨架</li>
          <li>llnut 旧后台兼容基线和只读适配安全检查</li>
          <li>账号/角色只读接口雏形与活动管理中心骨架</li>
          <li>私有部署仓 compose / env / 运维脚本模板</li>
        </ul>
      </section>
    </main>
  `;
}
