<template>
  <div class="dashboard">
    <a-row :gutter="16">
      <a-col :span="6">
        <a-card class="stat-card" :bordered="false">
          <div class="stat-content">
            <div class="stat-icon" style="background: #e8f3ff; color: #165DFF">
              <icon-user />
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.total_accounts }}</div>
              <div class="stat-label">总账号数</div>
            </div>
          </div>
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card" :bordered="false">
          <div class="stat-content">
            <div class="stat-icon" style="background: #e8ffea; color: #00b42a">
              <icon-user-group />
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.total_characters }}</div>
              <div class="stat-label">总角色数</div>
            </div>
          </div>
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card" :bordered="false">
          <div class="stat-content">
            <div class="stat-icon" style="background: #fff7e8; color: #ff7d00">
              <icon-wallet />
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatGold(stats.total_gold) }}</div>
              <div class="stat-label">总金币</div>
            </div>
          </div>
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card class="stat-card" :bordered="false">
          <div class="stat-content">
            <div class="stat-icon" style="background: #f5e8ff; color: #722ed1">
              <icon-calendar />
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.total_guilds }}</div>
              <div class="stat-label">公会数量</div>
            </div>
          </div>
        </a-card>
      </a-col>
    </a-row>

    <a-row :gutter="16" style="margin-top: 16px">
      <a-col :span="12">
        <a-card title="最近操作" :bordered="false">
          <a-table :data="recentLogs" :pagination="false" :scroll="{ y: 300 }" size="small">
            <template #columns>
              <a-table-column title="操作" data-index="action" :width="120">
                <template #cell="{ record }">
                  <a-tag :color="getActionColor(record.action)">{{ record.action }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="目标" data-index="target" />
              <a-table-column title="详情" data-index="detail" :ellipsis="true" />
              <a-table-column title="时间" data-index="created_at" :width="180" />
            </template>
          </a-table>
        </a-card>
      </a-col>
      <a-col :span="12">
        <a-card title="最近登录" :bordered="false">
          <a-table :data="recentLogins" :pagination="false" :scroll="{ y: 300 }" size="small">
            <template #columns>
              <a-table-column title="账号ID" data-index="m_id" />
              <a-table-column title="状态" :width="100">
                <template #cell>
                  <a-tag color="green">在线</a-tag>
                </template>
              </a-table-column>
            </template>
          </a-table>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'

const stats = ref({
  total_accounts: 0,
  total_characters: 0,
  total_guilds: 0,
  total_gold: 0,
  recent_logins: []
})

const recentLogs = ref([])
const recentLogins = ref([])

const formatGold = (gold) => {
  if (gold >= 100000000) return (gold / 100000000).toFixed(1) + '亿'
  if (gold >= 10000) return (gold / 10000).toFixed(1) + '万'
  return gold.toString()
}

const getActionColor = (action) => {
  const colors = {
    'send_mail': 'blue',
    'send_gold': 'orange',
    'send_cera': 'purple',
    'set_level': 'green',
    'reset_fatigue': 'cyan',
    'ban_account': 'red',
    'unban_account': 'lime'
  }
  return colors[action] || 'gray'
}

onMounted(async () => {
  try {
    const [statsRes, logsRes] = await Promise.all([
      api.get('/dashboard/stats'),
      api.get('/audit/logs?limit=10')
    ])
    stats.value = statsRes.data
    recentLogs.value = logsRes.data || []
    recentLogins.value = statsRes.data.recent_logins || []
  } catch (error) {
    console.error('Failed to load dashboard data:', error)
  }
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}
.stat-card {
  border-radius: 8px;
}
.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}
.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}
.stat-info {
  flex: 1;
}
.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #1d2129;
  line-height: 1.2;
}
.stat-label {
  font-size: 13px;
  color: #86909c;
  margin-top: 2px;
}
</style>
