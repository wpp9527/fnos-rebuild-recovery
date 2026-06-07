<template>
  <div class="audit-page">
    <a-card :bordered="false">
      <a-form layout="inline" :model="filterForm">
        <a-form-item label="操作类型">
          <a-input v-model="filterForm.action" placeholder="操作类型" allow-clear style="width: 160px" />
        </a-form-item>
        <a-form-item label="操作者ID">
          <a-input-number v-model="filterForm.operator_id" placeholder="操作者ID" :min="0" style="width: 160px" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" :loading="loading" @click="loadLogs">查询</a-button>
        </a-form-item>
      </a-form>
    </a-card>

    <a-table style="margin-top: 12px" :data="logs" :loading="loading" :pagination="false" :scroll="{ y: windowHeight }" scrollbar>
      <template #empty>
        <div style="text-align: center; padding: 20px">暂无数据</div>
      </template>
      <template #columns>
        <a-table-column title="ID" data-index="id" :width="80" />
        <a-table-column title="操作者" data-index="operator_id" :width="100" />
        <a-table-column title="操作" :width="140">
          <template #cell="{ record }">
            <a-tag :color="getActionColor(record.action)">{{ getActionLabel(record.action) }}</a-tag>
          </template>
        </a-table-column>
        <a-table-column title="目标" data-index="target" :width="150" />
        <a-table-column title="详情" data-index="detail" :ellipsis="true" />
        <a-table-column title="IP" data-index="ip_address" :width="140" />
        <a-table-column title="时间" data-index="created_at" :width="180" />
      </template>
    </a-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 12px">
      <a-pagination
        :current="currentPage"
        :page-size="50"
        :total="total"
        show-total
        @change="onPageChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message } from '@arco-design/web-vue'
import api from '../api'

const logs = ref([])
const loading = ref(false)
const currentPage = ref(1)
const total = ref(0)
const windowHeight = ref(window.innerHeight - 280)

const filterForm = ref({ action: '', operator_id: 0 })

const actionLabels = {
  send_mail: '发送邮件', send_item: '发送物品', send_gold: '充值金币', send_cera: '充值点券',
  set_level: '设置等级', reset_fatigue: '重置疲劳', ban_account: '封号', unban_account: '解封',
  start_activity: '启动活动', stop_activity: '关闭活动', start_service: '启动服务', stop_service: '停止服务', exec_command: '执行命令'
}
const actionColors = {
  send_mail: 'blue', send_item: 'blue', send_gold: 'green', send_cera: 'green',
  set_level: 'orange', reset_fatigue: 'orange', ban_account: 'red', unban_account: 'green',
  start_activity: 'green', stop_activity: 'red', start_service: 'green', stop_service: 'red', exec_command: 'gray'
}

const getActionLabel = (a) => actionLabels[a] || a
const getActionColor = (a) => actionColors[a] || 'gray'

const loadLogs = async () => {
  loading.value = true
  try {
    const params = { limit: 50, page: currentPage.value }
    if (filterForm.value.action) params.action = filterForm.value.action
    if (filterForm.value.operator_id > 0) params.operator_id = filterForm.value.operator_id
    const res = await api.get('/audit/logs', { params })
    logs.value = res.data || []
    total.value = logs.value.length
  } catch {
    Message.error('获取审计日志失败')
  } finally {
    loading.value = false
  }
}

const onPageChange = (page) => { currentPage.value = page; loadLogs() }

onMounted(() => {
  window.addEventListener('resize', () => { windowHeight.value = window.innerHeight - 280 })
  loadLogs()
})
</script>

<style scoped>
.audit-page { padding: 0; }
</style>
