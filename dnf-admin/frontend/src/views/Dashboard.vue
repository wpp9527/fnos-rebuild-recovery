<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>在线玩家</span>
              <el-icon><User /></el-icon>
            </div>
          </template>
          <div class="stat-value">{{ stats.onlinePlayers }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>今日登录</span>
              <el-icon><UserFilled /></el-icon>
            </div>
          </template>
          <div class="stat-value">{{ stats.todayLogins }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>今日充值</span>
              <el-icon><Money /></el-icon>
            </div>
          </template>
          <div class="stat-value">{{ stats.todayRecharge }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>活跃活动</span>
              <el-icon><Calendar /></el-icon>
            </div>
          </template>
          <div class="stat-value">{{ stats.activeActivities }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px">
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>最近操作</span>
          </template>
          <el-table :data="recentLogs" style="width: 100%">
            <el-table-column prop="action" label="操作" width="120" />
            <el-table-column prop="target" label="目标" />
            <el-table-column prop="detail" label="详情" show-overflow-tooltip />
            <el-table-column prop="created_at" label="时间" width="180" />
          </el-table>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>在线角色</span>
          </template>
          <el-table :data="onlineCharacters" style="width: 100%">
            <el-table-column prop="c_name" label="角色名" />
            <el-table-column prop="c_level" label="等级" width="80" />
            <el-table-column prop="c_job" label="职业" width="80" />
            <el-table-column prop="c_server" label="服务器" width="80" />
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { User, UserFilled, Money, Calendar } from '@element-plus/icons-vue'

const stats = ref({
  onlinePlayers: 0,
  todayLogins: 0,
  todayRecharge: 0,
  activeActivities: 0
})

const recentLogs = ref([])
const onlineCharacters = ref([])

onMounted(async () => {
  try {
    const [logsRes, onlineRes] = await Promise.all([
      api.get('/audit/logs?limit=5'),
      api.get('/characters/online')
    ])
    recentLogs.value = logsRes.data || []
    onlineCharacters.value = onlineRes.data || []
    stats.value.onlinePlayers = onlineCharacters.value.length
  } catch (error) {
    console.error('Failed to load dashboard data:', error)
  }
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #409eff;
  text-align: center;
  padding: 20px 0;
}
</style>
