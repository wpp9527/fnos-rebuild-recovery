<template>
  <div class="pve-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>PVE 管理</span>
          <el-button type="primary" @click="refreshStatus" :loading="statusLoading">刷新状态</el-button>
        </div>
      </template>

      <!-- Server Status -->
      <el-descriptions :column="3" border v-if="serverStatus">
        <el-descriptions-item label="主机名">{{ serverStatus.hostname }}</el-descriptions-item>
        <el-descriptions-item label="运行时间">{{ serverStatus.uptime }}</el-descriptions-item>
        <el-descriptions-item label="CPU">{{ serverStatus.cpu }}%</el-descriptions-item>
        <el-descriptions-item label="内存">{{ serverStatus.memory }}%</el-descriptions-item>
        <el-descriptions-item label="磁盘">{{ serverStatus.disk }}%</el-descriptions-item>
        <el-descriptions-item label="负载">{{ serverStatus.load_avg?.join(', ') }}</el-descriptions-item>
      </el-descriptions>

      <el-divider />

      <!-- Service Control -->
      <el-row :gutter="20">
        <el-col :span="12">
          <h4>服务控制</h4>
          <el-form :inline="true">
            <el-form-item label="服务名">
              <el-input v-model="serviceName" placeholder="输入服务名" />
            </el-form-item>
            <el-form-item>
              <el-button type="success" @click="startService" :loading="serviceLoading">启动</el-button>
              <el-button type="danger" @click="stopService" :loading="serviceLoading">停止</el-button>
            </el-form-item>
          </el-form>
        </el-col>
        <el-col :span="12">
          <h4>执行命令</h4>
          <el-form :inline="true">
            <el-form-item>
              <el-input v-model="execCommand" placeholder="输入命令" style="width: 300px" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="executeCommand" :loading="execLoading">执行</el-button>
            </el-form-item>
          </el-form>
        </el-col>
      </el-row>

      <!-- Command Output -->
      <el-card v-if="commandOutput" style="margin-top: 16px">
        <template #header>
          <span>命令输出</span>
        </template>
        <pre style="background: #f5f5f5; padding: 16px; border-radius: 4px; overflow-x: auto">{{ commandOutput }}</pre>
      </el-card>
    </el-card>

    <!-- File Browser -->
    <el-card style="margin-top: 20px">
      <template #header>
        <div class="card-header">
          <span>文件浏览器</span>
          <el-input v-model="currentPath" placeholder="路径" style="width: 300px" @keyup.enter="loadFiles">
            <template #append>
              <el-button @click="loadFiles">查看</el-button>
            </template>
          </el-input>
        </div>
      </template>
      <el-table :data="files" v-loading="filesLoading" style="width: 100%">
        <el-table-column prop="name" label="名称" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'directory' ? 'warning' : 'info'">
              {{ row.type === 'directory' ? '目录' : '文件' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="size" label="大小" width="120" />
        <el-table-column prop="modified" label="修改时间" width="180" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'

const serverStatus = ref(null)
const statusLoading = ref(false)

const serviceName = ref('')
const serviceLoading = ref(false)

const execCommand = ref('')
const execLoading = ref(false)
const commandOutput = ref('')

const currentPath = ref('/')
const files = ref([])
const filesLoading = ref(false)

const refreshStatus = async () => {
  statusLoading.value = true
  try {
    const response = await api.get('/pve/status')
    serverStatus.value = response.data
  } catch (error) {
    ElMessage.error('获取状态失败')
  } finally {
    statusLoading.value = false
  }
}

const startService = async () => {
  if (!serviceName.value) {
    ElMessage.warning('请输入服务名')
    return
  }
  await ElMessageBox.confirm(`确认启动服务 ${serviceName.value}？`, '提示', { type: 'warning' })
  serviceLoading.value = true
  try {
    await api.post(`/pve/service/${serviceName.value}/start`)
    ElMessage.success('服务已启动')
  } catch (error) {
    ElMessage.error('启动失败: ' + (error.response?.data?.error || error.message))
  } finally {
    serviceLoading.value = false
  }
}

const stopService = async () => {
  if (!serviceName.value) {
    ElMessage.warning('请输入服务名')
    return
  }
  await ElMessageBox.confirm(`确认停止服务 ${serviceName.value}？`, '提示', { type: 'warning' })
  serviceLoading.value = true
  try {
    await api.post(`/pve/service/${serviceName.value}/stop`)
    ElMessage.success('服务已停止')
  } catch (error) {
    ElMessage.error('停止失败: ' + (error.response?.data?.error || error.message))
  } finally {
    serviceLoading.value = false
  }
}

const executeCommand = async () => {
  if (!execCommand.value) {
    ElMessage.warning('请输入命令')
    return
  }
  await ElMessageBox.confirm('确认执行命令？', '提示', { type: 'warning' })
  execLoading.value = true
  try {
    const response = await api.post('/pve/exec', { command: execCommand.value })
    commandOutput.value = response.data.output
    ElMessage.success('命令已执行')
  } catch (error) {
    ElMessage.error('执行失败: ' + (error.response?.data?.error || error.message))
  } finally {
    execLoading.value = false
  }
}

const loadFiles = async () => {
  filesLoading.value = true
  try {
    const response = await api.get('/pve/files', { params: { path: currentPath.value } })
    files.value = response.data || []
  } catch (error) {
    ElMessage.error('获取文件列表失败')
  } finally {
    filesLoading.value = false
  }
}

onMounted(() => {
  refreshStatus()
  loadFiles()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
