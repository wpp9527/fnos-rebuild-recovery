<template>
  <div class="audit-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>审计日志</span>
          <div class="filter-box">
            <el-input v-model="filterAction" placeholder="操作类型" clearable style="width: 150px; margin-right: 10px" />
            <el-input-number v-model="filterOperator" placeholder="操作者ID" :min="0" style="width: 150px; margin-right: 10px" />
            <el-button type="primary" @click="loadLogs" :loading="loading">查询</el-button>
          </div>
        </div>
      </template>

      <el-table :data="logs" v-loading="loading" style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="operator_id" label="操作者" width="100" />
        <el-table-column prop="action" label="操作" width="140">
          <template #default="{ row }">
            <el-tag :type="getActionType(row.action)">{{ getActionLabel(row.action) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="target" label="目标" width="150" />
        <el-table-column prop="detail" label="详情" show-overflow-tooltip />
        <el-table-column prop="ip_address" label="IP" width="140" />
        <el-table-column prop="created_at" label="时间" width="180" />
      </el-table>

      <el-pagination
        v-model:current-page="currentPage"
        :page-size="50"
        :total="total"
        layout="total, prev, pager, next"
        @current-change="loadLogs"
        style="margin-top: 16px; justify-content: flex-end"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'

const logs = ref([])
const loading = ref(false)
const currentPage = ref(1)
const total = ref(0)

const filterAction = ref('')
const filterOperator = ref(0)

const actionLabels = {
  send_mail: '发送邮件',
  send_item: '发送物品',
  send_gold: '充值金币',
  send_cera: '充值点券',
  set_level: '设置等级',
  reset_fatigue: '重置疲劳',
  ban_account: '封号',
  unban_account: '解封',
  start_activity: '启动活动',
  stop_activity: '关闭活动',
  start_service: '启动服务',
  stop_service: '停止服务',
  exec_command: '执行命令'
}

const actionTypes = {
  send_mail: 'primary',
  send_item: 'primary',
  send_gold: 'success',
  send_cera: 'success',
  set_level: 'warning',
  reset_fatigue: 'warning',
  ban_account: 'danger',
  unban_account: 'success',
  start_activity: 'success',
  stop_activity: 'danger',
  start_service: 'success',
  stop_service: 'danger',
  exec_command: 'info'
}

const getActionLabel = (action) => actionLabels[action] || action
const getActionType = (action) => actionTypes[action] || 'info'

const loadLogs = async () => {
  loading.value = true
  try {
    const params = {
      limit: 50
    }
    if (filterAction.value) params.action = filterAction.value
    if (filterOperator.value > 0) params.operator_id = filterOperator.value

    const response = await api.get('/audit/logs', { params })
    logs.value = response.data || []
    total.value = logs.value.length
  } catch (error) {
    ElMessage.error('获取审计日志失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadLogs()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-box {
  display: flex;
  align-items: center;
}
</style>
