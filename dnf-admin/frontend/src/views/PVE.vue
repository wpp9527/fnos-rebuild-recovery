<template>
  <div class="pve-page">
    <a-card title="PVE 管理" :bordered="false">
      <template #extra>
        <a-button type="primary" :loading="statusLoading" @click="refreshStatus">刷新状态</a-button>
      </template>

      <!-- Server Status -->
      <a-descriptions v-if="serverStatus" :column="3" bordered>
        <a-descriptions-item label="主机名">{{ serverStatus.hostname }}</a-descriptions-item>
        <a-descriptions-item label="运行时间">{{ serverStatus.uptime }}</a-descriptions-item>
        <a-descriptions-item label="CPU">{{ serverStatus.cpu }}%</a-descriptions-item>
        <a-descriptions-item label="内存">{{ serverStatus.memory }}%</a-descriptions-item>
        <a-descriptions-item label="磁盘">{{ serverStatus.disk }}%</a-descriptions-item>
        <a-descriptions-item label="负载">{{ serverStatus.load_avg?.join(', ') }}</a-descriptions-item>
      </a-descriptions>

      <a-divider />

      <a-row :gutter="24">
        <a-col :span="12">
          <h4 style="margin-bottom: 12px">服务控制</h4>
          <a-form layout="inline">
            <a-form-item label="服务名"><a-input v-model="serviceName" placeholder="输入服务名" /></a-form-item>
            <a-form-item>
              <a-space>
                <a-button type="primary" status="success" :loading="serviceLoading" @click="startService">启动</a-button>
                <a-button type="primary" status="danger" :loading="serviceLoading" @click="stopService">停止</a-button>
              </a-space>
            </a-form-item>
          </a-form>
        </a-col>
        <a-col :span="12">
          <h4 style="margin-bottom: 12px">执行命令</h4>
          <a-form layout="inline">
            <a-form-item><a-input v-model="execCommand" placeholder="输入命令" style="width: 300px" /></a-form-item>
            <a-form-item><a-button type="primary" :loading="execLoading" @click="executeCommand">执行</a-button></a-form-item>
          </a-form>
        </a-col>
      </a-row>

      <a-card v-if="commandOutput" title="命令输出" style="margin-top: 16px" :bordered="false">
        <pre style="background: #f7f8fa; padding: 16px; border-radius: 4px; overflow-x: auto; margin: 0">{{ commandOutput }}</pre>
      </a-card>
    </a-card>

    <!-- File Browser -->
    <a-card title="文件浏览器" :bordered="false" style="margin-top: 16px">
      <template #extra>
        <a-input v-model="currentPath" placeholder="路径" style="width: 300px" @keyup.enter="loadFiles">
          <template #append><a-button @click="loadFiles">查看</a-button></template>
        </a-input>
      </template>
      <a-table :data="files" :loading="filesLoading" :pagination="false">
        <template #columns>
          <a-table-column title="名称" data-index="name" />
          <a-table-column title="类型" :width="100">
            <template #cell="{ record }">
              <a-tag :color="record.type === 'directory' ? 'orange' : 'gray'">{{ record.type === 'directory' ? '目录' : '文件' }}</a-tag>
            </template>
          </a-table-column>
          <a-table-column title="大小" data-index="size" :width="120" />
          <a-table-column title="修改时间" data-index="modified" :width="180" />
        </template>
      </a-table>
    </a-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message, Modal } from '@arco-design/web-vue'
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
  try { serverStatus.value = (await api.get('/pve/status')).data }
  catch { Message.error('获取状态失败') }
  finally { statusLoading.value = false }
}

const startService = async () => {
  if (!serviceName.value) { Message.warning('请输入服务名'); return }
  Modal.confirm({ title: '提示', content: `确认启动服务 ${serviceName.value}？`, onOk: async () => {
    serviceLoading.value = true
    try { await api.post(`/pve/service/${serviceName.value}/start`); Message.success('服务已启动') }
    catch (e) { Message.error('启动失败: ' + (e.response?.data?.error || e.message)) }
    finally { serviceLoading.value = false }
  }})
}

const stopService = async () => {
  if (!serviceName.value) { Message.warning('请输入服务名'); return }
  Modal.confirm({ title: '提示', content: `确认停止服务 ${serviceName.value}？`, onOk: async () => {
    serviceLoading.value = true
    try { await api.post(`/pve/service/${serviceName.value}/stop`); Message.success('服务已停止') }
    catch (e) { Message.error('停止失败: ' + (e.response?.data?.error || e.message)) }
    finally { serviceLoading.value = false }
  }})
}

const executeCommand = async () => {
  if (!execCommand.value) { Message.warning('请输入命令'); return }
  Modal.confirm({ title: '提示', content: '确认执行命令？', onOk: async () => {
    execLoading.value = true
    try { const res = await api.post('/pve/exec', { command: execCommand.value }); commandOutput.value = res.data.output; Message.success('命令已执行') }
    catch (e) { Message.error('执行失败: ' + (e.response?.data?.error || e.message)) }
    finally { execLoading.value = false }
  }})
}

const loadFiles = async () => {
  filesLoading.value = true
  try { files.value = (await api.get('/pve/files', { params: { path: currentPath.value } })).data || [] }
  catch { Message.error('获取文件列表失败') }
  finally { filesLoading.value = false }
}

onMounted(() => { refreshStatus(); loadFiles() })
</script>
