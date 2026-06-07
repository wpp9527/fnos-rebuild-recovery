const fallbackModules = {
  modules: [
    { key: 'auth', name: '认证与权限', status: 'in-progress' },
    { key: 'account', name: '账号查询', status: 'planned' },
    { key: 'character', name: '角色查询', status: 'planned' },
    { key: 'pvf', name: 'PVF 检索', status: 'planned' },
    { key: 'gm', name: 'GM 操作', status: 'planned' },
    { key: 'activity', name: '活动管理', status: 'in-progress' },
    { key: 'audit', name: '审计日志', status: 'in-progress' }
  ],
  permissions: [
    { key: 'auth', name: '认证与权限', access: 'manage' },
    { key: 'account', name: '账号查询', access: 'read' },
    { key: 'character', name: '角色查询', access: 'read' },
    { key: 'pvf', name: 'PVF 检索', access: 'read' },
    { key: 'gm', name: 'GM 操作', access: 'write' },
    { key: 'audit', name: '审计日志', access: 'read' }
  ]
};

const fallbackAudit = {
  actions: [
    { key: 'login', name: '管理员登录', risk_level: 'low', description: '记录登录行为与结果摘要' },
    { key: 'account.search', name: '账号查询', risk_level: 'low', description: '记录查询条件摘要' },
    { key: 'character.inspect', name: '角色查看', risk_level: 'low', description: '记录角色浏览行为' },
    { key: 'gm.mail.send', name: '发送邮件', risk_level: 'high', description: '高风险，必须审计' },
    { key: 'gm.item.grant', name: '发放物品', risk_level: 'high', description: '高风险，必须审计' }
  ]
};

const fallbackMe = {
  user: {
    username: 'admin',
    role: 'super_admin',
    scopes: ['auth:read', 'account:read', 'character:read', 'gm:write', 'audit:read']
  }
};

const fallbackActivities = {
  items: [
    { id: 'act-1', code: 'native-double-drop', name: '周末双倍掉率', type: 'drop-rate', source: 'native', status: 'active', start_at: '2026-05-04 00:00', end_at: '2026-05-05 23:59', description: '原生活动，服务端真实控制。' },
    { id: 'act-2', code: 'pvf-signin-may', name: '五月签到礼盒', type: 'signin', source: 'pvf_mapped', status: 'scheduled', start_at: '2026-05-06 00:00', end_at: '2026-05-31 23:59', description: '由 PVF 识别并映射的活动模板。' },
    { id: 'act-3', code: 'custom-festival-mail', name: '节日邮件福利', type: 'mail', source: 'custom', status: 'draft', start_at: '2026-05-10 00:00', end_at: '2026-05-12 23:59', description: '后台自定义邮件奖励活动。' }
  ]
};

const fallbackCalendar = {
  days: [
    { date: '2026-05-04', items: [fallbackActivities.items[0]] },
    { date: '2026-05-06', items: [fallbackActivities.items[1]] },
    { date: '2026-05-10', items: [fallbackActivities.items[2]] }
  ]
};

const fallbackNative = {
  items: [
    { code: 'native-double-drop', name: '周末双倍掉率', status: 'active', control_mode: 'native', description: '掉率提升类原生活动' },
    { code: 'native-online-gift', name: '在线时长奖励', status: 'disabled', control_mode: 'native', description: '在线奖励类原生活动' }
  ]
};

async function tryFetch(path, fallback, options) {
  try {
    const resp = await fetch(path, options);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return await resp.json();
  } catch (_) {
    return fallback;
  }
}

export async function loadDashboardData() {
  const [modules, audit, me, activities, calendar, nativeActivities] = await Promise.all([
    tryFetch('/api/v1/meta/modules', fallbackModules),
    tryFetch('/api/v1/meta/audit-actions', fallbackAudit),
    tryFetch('/api/v1/auth/me', fallbackMe),
    tryFetch('/api/v1/activities', fallbackActivities),
    tryFetch('/api/v1/activities/calendar', fallbackCalendar),
    tryFetch('/api/v1/activities/native', fallbackNative)
  ]);
  return { modules, audit, me, activities, calendar, nativeActivities };
}
