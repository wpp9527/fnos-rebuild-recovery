<template>
  <div class="activities-page">
    <el-card>
      <template #header>
        <span>活动管理</span>
      </template>

      <el-table :data="activities" v-loading="loading" style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="活动名称" width="200" />
        <el-table-column prop="description" label="描述" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">
              {{ row.status === 1 ? '进行中' : '已关闭' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="start_time" label="开始时间" width="180" />
        <el-table-column prop="end_time" label="结束时间" width="180" />
        <el-table-column label="操作" width="160">
          <template #default="{ row }">
            <el-button v-if="row.status === 0" type="success" link @click="startActivity(row.id)">启动</el-button>
            <el-button v-if="row.status === 1" type="danger" link @click="stopActivity(row.id)">关闭</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Activity Logs -->
    <el-card style="margin-top: 20px">
      <template #header>
        <span>活动日志</span>
      </template>
      <el-table :data="activityLogs" v-loading="logsLoading" style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="activity_id" label="活动ID" width="100" />
        <el-table-column prop="action" label="操作" width="120" />
        <el-table-column prop="detail" label="详情" show-overflow-tooltip />
        <el-table-column prop="created_at" label="时间" width="180" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'

const activities = ref([])
const loading = ref(false)
const activityLogs = ref([])
const logsLoading = ref(false)

const loadActivities = async () => {
  loading.value = true
  try {
    const response = await api.get('/activities')
    activities.value = response.data || []
  } catch (error) {
    ElMessage.error('获取活动列表失败')
  } finally {
    loading.value = false
  }
}

const loadLogs = async () => {
  logsLoading.value = true
  try {
    const response = await api.get('/activities/logs', { params: { limit: 20 } })
    activityLogs.value = response.data || []
  } catch (error) {
    ElMessage.error('获取活动日志失败')
  } finally {
    logsLoading.value = false
  }
}

const startActivity = async (id) => {
  await ElMessageBox.confirm('确认启动活动？', '提示', { type: 'warning' })
  try {
    await api.post(`/activities/${id}/start`)
    ElMessage.success('活动已启动')
    loadActivities()
    loadLogs()
  } catch (error) {
    ElMessage.error('启动失败: ' + (error.response?.data?.error || error.message))
  }
}

const stopActivity = async (id) => {
  await ElMessageBox.confirm('确认关闭活动？', '提示', { type: 'warning' })
  try {
    await api.post(`/activities/${id}/stop`)
    ElMessage.success('活动已关闭')
    loadActivities()
    loadLogs()
  } catch (error) {
    ElMessage.error('关闭失败: ' + (error.response?.data?.error || error.message))
  }
}

onMounted(() => {
  loadActivities()
  loadLogs()
})
</script>
