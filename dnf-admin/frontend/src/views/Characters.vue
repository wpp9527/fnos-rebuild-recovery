<template>
  <div class="characters-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>角色管理</span>
          <el-button type="primary" @click="showOnline">查看在线</el-button>
        </div>
      </template>

      <el-form :inline="true" @submit.prevent="handleSearch">
        <el-form-item label="角色ID">
          <el-input v-model="searchCNo" placeholder="输入角色ID" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="characters" v-loading="loading" style="width: 100%; margin-top: 16px">
        <el-table-column prop="c_no" label="角色ID" width="100" />
        <el-table-column prop="c_name" label="角色名" width="150" />
        <el-table-column prop="c_level" label="等级" width="80" />
        <el-table-column prop="c_job" label="职业" width="100" />
        <el-table-column prop="c_fatigue" label="疲劳" width="80" />
        <el-table-column prop="c_server" label="服务器" width="80" />
        <el-table-column prop="uid" label="UID" width="100" />
        <el-table-column prop="c_last_login" label="最后登录" />
        <el-table-column label="操作" width="100">
          <template #default="{ row }">
            <el-button type="primary" link @click="viewItems(row.c_no)">查看物品</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Items Dialog -->
    <el-dialog v-model="itemsDialogVisible" title="角色物品" width="900px">
      <el-table :data="characterItems" v-loading="itemsLoading">
        <el-table-column prop="slot_no" label="槽位" width="80" />
        <el-table-column prop="item_id" label="物品ID" width="100" />
        <el-table-column prop="item_name" label="物品名" width="200" />
        <el-table-column prop="count" label="数量" width="80" />
        <el-table-column prop="enhance" label="强化" width="80" />
        <el-table-column prop="rarity" label="稀有度" width="80" />
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'

const searchCNo = ref('')
const characters = ref([])
const loading = ref(false)

const itemsDialogVisible = ref(false)
const itemsLoading = ref(false)
const characterItems = ref([])

const handleSearch = async () => {
  if (!searchCNo.value) return

  loading.value = true
  try {
    const response = await api.get(`/characters/${searchCNo.value}`)
    if (response.data) {
      characters.value = [response.data]
    } else {
      characters.value = []
      ElMessage.info('未找到角色')
    }
  } catch (error) {
    ElMessage.error('查询失败: ' + (error.response?.data?.error || error.message))
    characters.value = []
  } finally {
    loading.value = false
  }
}

const showOnline = async () => {
  loading.value = true
  try {
    const response = await api.get('/characters/online')
    characters.value = response.data || []
  } catch (error) {
    ElMessage.error('获取在线角色失败')
  } finally {
    loading.value = false
  }
}

const viewItems = async (cNo) => {
  itemsDialogVisible.value = true
  itemsLoading.value = true
  try {
    const response = await api.get(`/characters/${cNo}/items`)
    characterItems.value = response.data || []
  } catch (error) {
    ElMessage.error('获取物品失败')
  } finally {
    itemsLoading.value = false
  }
}
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
