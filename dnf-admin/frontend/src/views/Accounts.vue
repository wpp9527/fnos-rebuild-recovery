<template>
  <div class="accounts-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>账号管理</span>
          <div class="search-box">
            <el-input
              v-model="searchQuery"
              placeholder="输入 UID 或用户名搜索"
              clearable
              @keyup.enter="handleSearch"
              style="width: 300px"
            >
              <template #append>
                <el-button :icon="Search" @click="handleSearch" />
              </template>
            </el-input>
          </div>
        </div>
      </template>

      <el-table :data="accounts" v-loading="loading" style="width: 100%">
        <el-table-column prop="uid" label="UID" width="100" />
        <el-table-column prop="uname" label="用户名" width="150" />
        <el-table-column prop="level" label="等级" width="80" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'">
              {{ row.status === 1 ? '正常' : '封禁' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="coin" label="金币" width="120" />
        <el-table-column prop="cera" label="点券" width="120" />
        <el-table-column prop="login_ip" label="登录IP" width="140" />
        <el-table-column prop="last_login" label="最后登录" width="180" />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button type="primary" link @click="viewCharacters(row.uid)">查看角色</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50]"
        :total="total"
        layout="total, sizes, prev, pager, next"
        @size-change="handleSearch"
        @current-change="handleSearch"
        style="margin-top: 16px; justify-content: flex-end"
      />
    </el-card>

    <!-- Character Dialog -->
    <el-dialog v-model="dialogVisible" title="账号角色" width="800px">
      <el-table :data="characters" v-loading="dialogLoading">
        <el-table-column prop="c_no" label="角色ID" width="100" />
        <el-table-column prop="c_name" label="角色名" width="150" />
        <el-table-column prop="c_level" label="等级" width="80" />
        <el-table-column prop="c_job" label="职业" width="100" />
        <el-table-column prop="c_fatigue" label="疲劳" width="80" />
        <el-table-column prop="c_server" label="服务器" width="80" />
        <el-table-column prop="c_last_login" label="最后登录" />
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import api from '../api'

const searchQuery = ref('')
const accounts = ref([])
const loading = ref(false)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

const dialogVisible = ref(false)
const dialogLoading = ref(false)
const characters = ref([])

const handleSearch = async () => {
  if (!searchQuery.value) return

  loading.value = true
  try {
    const response = await api.get('/accounts/search', {
      params: {
        q: searchQuery.value,
        page: currentPage.value,
        page_size: pageSize.value
      }
    })
    accounts.value = response.data.data || []
    total.value = response.data.total || 0
  } catch (error) {
    ElMessage.error('搜索失败: ' + (error.response?.data?.error || error.message))
  } finally {
    loading.value = false
  }
}

const viewCharacters = async (uid) => {
  dialogVisible.value = true
  dialogLoading.value = true
  try {
    const response = await api.get(`/accounts/${uid}/characters`)
    characters.value = response.data || []
  } catch (error) {
    ElMessage.error('获取角色失败')
  } finally {
    dialogLoading.value = false
  }
}

onMounted(() => {
  handleSearch()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
