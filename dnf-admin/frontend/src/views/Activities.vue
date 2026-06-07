<template>
  <div class="activities-page">
    <a-card title="活动管理" :bordered="false">
      <template #extra>
        <a-space>
          <a-button type="outline" @click="loadActivities">刷新</a-button>
          <a-select v-model="pageSize" style="width: 120px" @change="loadActivities">
            <a-option :value="10">10条/页</a-option>
            <a-option :value="20">20条/页</a-option>
            <a-option :value="50">50条/页</a-option>
            <a-option :value="100">100条/页</a-option>
          </a-select>
        </a-space>
      </template>
      <a-table :data="activities" :loading="loading" :pagination="false" :scroll="{ y: 500 }">
        <template #columns>
          <a-table-column title="ID" data-index="id" :width="60" />
          <a-table-column title="事件代码" data-index="code" :width="200" />
          <a-table-column title="活动名称" data-index="name" :width="200" />
          <a-table-column title="类型" data-index="type" :width="100">
            <template #cell="{ record }">
              <a-tag :color="getTypeColor(record.type)">{{ getTypeName(record.type) }}</a-tag>
            </template>
          </a-table-column>
          <a-table-column title="状态" :width="100">
            <template #cell="{ record }">
              <a-tag :color="getStatusColor(record.status)">{{ getStatusName(record.status) }}</a-tag>
            </template>
          </a-table-column>
          <a-table-column title="应用类型" data-index="apply_type" :width="80" />
          <a-table-column title="描述" data-index="description" :ellipsis="true" />
          <a-table-column title="开关" :width="100">
            <template #cell="{ record }">
              <a-switch
                :model-value="record.status === 'active'"
                @change="(val) => toggleActivity(record.id, val)"
              />
            </template>
          </a-table-column>
        </template>
      </a-table>
      <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
        <a-pagination
          :current="pageNum"
          :page-size="pageSize"
          :total="total"
          show-total
          show-jumper
          @change="onPageChange"
        />
      </div>
    </a-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message, Modal } from '@arco-design/web-vue'
import api from '../api'

const activities = ref([])
const allActivities = ref([])
const loading = ref(false)
const pageNum = ref(1)
const pageSize = ref(20)
const total = ref(0)

const getTypeColor = (type) => {
  const colors = { 'fatigue': 'blue', 'exp': 'green', 'coin': 'orange', 'drop': 'purple', 'event': 'cyan' }
  return colors[type] || 'gray'
}

const getTypeName = (type) => {
  const names = { 'fatigue': '疲劳', 'exp': '经验', 'coin': '金币', 'drop': '掉率', 'event': '活动' }
  return names[type] || type
}

const getStatusColor = (status) => {
  const colors = { 'active': 'green', 'available': 'blue', 'stopped': 'red', 'scheduled': 'orange' }
  return colors[status] || 'gray'
}

const getStatusName = (status) => {
  const names = { 'active': '进行中', 'available': '可用', 'stopped': '已停止', 'scheduled': '计划中' }
  return names[status] || status
}

const loadActivities = async () => {
  loading.value = true
  try {
    const res = await api.get('/activities')
    allActivities.value = res.data || []
    total.value = allActivities.value.length
    // 客户端分页
    const start = (pageNum.value - 1) * pageSize.value
    activities.value = allActivities.value.slice(start, start + pageSize.value)
  } catch { Message.error('获取活动列表失败') }
  finally { loading.value = false }
}

const onPageChange = (page) => {
  pageNum.value = page
  const start = (page - 1) * pageSize.value
  activities.value = allActivities.value.slice(start, start + pageSize.value)
}

const toggleActivity = async (id, enabled) => {
  const action = enabled ? '启动' : '关闭'
  Modal.confirm({
    title: '提示',
    content: `确认${action}活动？`,
    onOk: async () => {
      try {
        if (enabled) {
          await api.post(`/activities/${id}/start`)
        } else {
          await api.post(`/activities/${id}/stop`)
        }
        Message.success(`活动已${action}`)
        loadActivities()
      } catch (e) { Message.error(`${action}失败: ` + (e.response?.data?.error || e.message)) }
    }
  })
}

onMounted(loadActivities)
</script>

<style scoped>
.activities-page { padding: 0; }
</style>
