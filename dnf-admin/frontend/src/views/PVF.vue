<template>
  <div class="pvf-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>PVF 搜索</span>
          <el-button type="warning" @click="reloadPVF" :loading="reloadLoading">重新加载</el-button>
        </div>
      </template>

      <el-tabs v-model="activeTab">
        <el-tab-pane label="物品搜索" name="items">
          <el-input v-model="searchQuery" placeholder="输入物品名称或ID" clearable @keyup.enter="searchItems" style="width: 400px; margin-bottom: 16px">
            <template #append>
              <el-button :icon="Search" @click="searchItems" />
            </template>
          </el-input>
          <el-table :data="items" v-loading="loading" style="width: 100%">
            <el-table-column prop="id" label="ID" width="100" />
            <el-table-column prop="name" label="名称" width="200" />
            <el-table-column prop="type" label="类型" width="120" />
            <el-table-column prop="rarity" label="稀有度" width="100" />
            <el-table-column prop="price" label="价格" width="120" />
            <el-table-column prop="description" label="描述" show-overflow-tooltip />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button type="primary" link @click="sendItem(row.id)">发送</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="装备搜索" name="equipments">
          <el-input v-model="searchQuery" placeholder="输入装备名称或ID" clearable @keyup.enter="searchEquipments" style="width: 400px; margin-bottom: 16px">
            <template #append>
              <el-button :icon="Search" @click="searchEquipments" />
            </template>
          </el-input>
          <el-table :data="equipments" v-loading="loading" style="width: 100%">
            <el-table-column prop="id" label="ID" width="100" />
            <el-table-column prop="name" label="名称" width="200" />
            <el-table-column prop="type" label="类型" width="120" />
            <el-table-column prop="level" label="等级" width="80" />
            <el-table-column prop="rarity" label="稀有度" width="100" />
            <el-table-column prop="description" label="描述" show-overflow-tooltip />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button type="primary" link @click="sendItem(row.id)">发送</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="技能搜索" name="skills">
          <el-input v-model="searchQuery" placeholder="输入技能名称或ID" clearable @keyup.enter="searchSkills" style="width: 400px; margin-bottom: 16px">
            <template #append>
              <el-button :icon="Search" @click="searchSkills" />
            </template>
          </el-input>
          <el-table :data="skills" v-loading="loading" style="width: 100%">
            <el-table-column prop="id" label="ID" width="100" />
            <el-table-column prop="name" label="名称" width="200" />
            <el-table-column prop="level" label="等级" width="80" />
            <el-table-column prop="job" label="职业" width="80" />
            <el-table-column prop="max_level" label="最高等级" width="100" />
            <el-table-column prop="cooldown" label="冷却时间" width="100" />
            <el-table-column prop="description" label="描述" show-overflow-tooltip />
          </el-table>
        </el-tab-pane>
      </el-tabs>

      <!-- Stats -->
      <el-divider />
      <el-descriptions :column="3" border>
        <el-descriptions-item label="总物品数">{{ stats.total_items }}</el-descriptions-item>
        <el-descriptions-item label="总装备数">{{ stats.total_equipments }}</el-descriptions-item>
        <el-descriptions-item label="总技能数">{{ stats.total_skills }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- Send Item Dialog -->
    <el-dialog v-model="sendDialogVisible" title="发送物品" width="400px">
      <el-form :model="sendForm" label-width="80px">
        <el-form-item label="角色名">
          <el-input v-model="sendForm.character_name" placeholder="输入角色名" />
        </el-form-item>
        <el-form-item label="物品ID">
          <el-input-number v-model="sendForm.item_id" :disabled="true" />
        </el-form-item>
        <el-form-item label="数量">
          <el-input-number v-model="sendForm.count" :min="1" :max="9999" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="sendDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmSendItem" :loading="sendLoading">确认</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'

const activeTab = ref('items')
const searchQuery = ref('')
const loading = ref(false)
const reloadLoading = ref(false)

const items = ref([])
const equipments = ref([])
const skills = ref([])
const stats = ref({ total_items: 0, total_equipments: 0, total_skills: 0 })

const sendDialogVisible = ref(false)
const sendLoading = ref(false)
const sendForm = reactive({
  character_name: '',
  item_id: 0,
  count: 1
})

const searchItems = async () => {
  if (!searchQuery.value) return
  loading.value = true
  try {
    const response = await api.get('/pvf/items', { params: { q: searchQuery.value } })
    items.value = response.data || []
  } catch (error) {
    ElMessage.error('搜索失败')
  } finally {
    loading.value = false
  }
}

const searchEquipments = async () => {
  if (!searchQuery.value) return
  loading.value = true
  try {
    const response = await api.get('/pvf/equipments', { params: { q: searchQuery.value } })
    equipments.value = response.data || []
  } catch (error) {
    ElMessage.error('搜索失败')
  } finally {
    loading.value = false
  }
}

const searchSkills = async () => {
  if (!searchQuery.value) return
  loading.value = true
  try {
    const response = await api.get('/pvf/skills', { params: { q: searchQuery.value } })
    skills.value = response.data || []
  } catch (error) {
    ElMessage.error('搜索失败')
  } finally {
    loading.value = false
  }
}

const reloadPVF = async () => {
  reloadLoading.value = true
  try {
    await api.post('/pvf/reload')
    ElMessage.success('PVF 重新加载成功')
    loadStats()
  } catch (error) {
    ElMessage.error('重新加载失败')
  } finally {
    reloadLoading.value = false
  }
}

const loadStats = async () => {
  try {
    const response = await api.get('/pvf/stats')
    stats.value = response.data || {}
  } catch (error) {
    console.error('Failed to load stats:', error)
  }
}

const sendItem = (itemId) => {
  sendForm.item_id = itemId
  sendForm.count = 1
  sendDialogVisible.value = true
}

const confirmSendItem = async () => {
  if (!sendForm.character_name) {
    ElMessage.warning('请输入角色名')
    return
  }

  await ElMessageBox.confirm('确认发送物品？', '提示', { type: 'warning' })
  sendLoading.value = true
  try {
    await api.post('/gm/item', sendForm)
    ElMessage.success('物品发送成功')
    sendDialogVisible.value = false
  } catch (error) {
    ElMessage.error('发送失败: ' + (error.response?.data?.error || error.message))
  } finally {
    sendLoading.value = false
  }
}

onMounted(() => {
  loadStats()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
