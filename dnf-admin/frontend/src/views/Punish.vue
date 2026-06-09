<template>
  <div class="punish-page">
    <a-card :bordered="false">
      <template #title>
        <a-row justify="space-between" align="center">
          <span>惩罚管理</span>
          <a-button type="primary" size="small" @click="showAddModal">
            <template #icon><icon-plus /></template>
            添加惩罚
          </a-button>
        </a-row>
      </template>

      <a-table :data="punishList" :loading="loading" :pagination="false">
        <template #columns>
          <a-table-column title="记录ID" data-index="m_id" :width="80" />
          <a-table-column title="角色" :width="150">
            <template #cell="{ record }">{{ decodeUnicode(record.charac_name) || 'UID:' + record.uid }}</template>
          </a-table-column>
          <a-table-column title="惩罚类型" :width="100">
            <template #cell="{ record }">
              <a-tag :color="getPunishColor(record.punish_type)">{{ getPunishName(record.punish_type) }}</a-tag>
            </template>
          </a-table-column>
          <a-table-column title="原因" :min-width="200">
            <template #cell="{ record }">{{ decodeUnicode(record.reason) || '-' }}</template>
          </a-table-column>
          <a-table-column title="开始时间" :width="160">
            <template #cell="{ record }">{{ record.start_time || '-' }}</template>
          </a-table-column>
          <a-table-column title="结束时间" :width="160">
            <template #cell="{ record }">{{ record.end_time || '永久' }}</template>
          </a-table-column>
          <a-table-column title="操作" :width="100">
            <template #cell="{ record }">
              <a-popconfirm content="确认解除该惩罚?" @ok="removePunish(record.m_id)">
                <a-button type="text" size="small" status="danger">解除</a-button>
              </a-popconfirm>
            </template>
          </a-table-column>
        </template>
      </a-table>
    </a-card>

    <!-- 添加惩罚弹窗 -->
    <a-modal v-model:visible="addVisible" title="添加惩罚" @ok="confirmAdd">
      <a-form :model="addForm" layout="vertical">
        <a-form-item label="角色名" required>
          <a-input v-model="addForm.charac_name" placeholder="输入角色名" />
        </a-form-item>
        <a-form-item label="惩罚类型" required>
          <a-select v-model="addForm.punish_type">
            <a-option :value="1">封号</a-option>
            <a-option :value="2">禁言</a-option>
            <a-option :value="3">封IP</a-option>
            <a-option :value="11">临时封号</a-option>
          </a-select>
        </a-form-item>
        <a-form-item label="原因">
          <a-textarea v-model="addForm.reason" placeholder="惩罚原因" />
        </a-form-item>
        <a-form-item label="持续时间(小时)">
          <a-input-number v-model="addForm.hours" :min="0" placeholder="0=永久" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message } from '@arco-design/web-vue'
import api from '../api'

const punishList = ref([])
const loading = ref(false)
const addVisible = ref(false)
const addForm = ref({ charac_name: '', punish_type: 1, reason: '', hours: 0 })

const decodeUnicode = (str) => {
  if (!str) return str
  return str.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

const getPunishName = (type) => ({ 1: '封号', 2: '禁言', 3: '封IP', 11: '临时封号' })[type] || '未知'
const getPunishColor = (type) => ({ 1: 'red', 2: 'orange', 3: 'purple', 11: 'orangered' })[type] || 'gray'

const loadData = async () => {
  loading.value = true
  try {
    const res = await api.get('/punish')
    punishList.value = res.data || []
  } catch (e) {
    Message.error('加载失败: ' + (e.response?.data?.error || e.message))
  } finally { loading.value = false }
}

const showAddModal = () => {
  addForm.value = { charac_name: '', punish_type: 1, reason: '', hours: 0 }
  addVisible.value = true
}

const confirmAdd = async () => {
  if (!addForm.value.charac_name) {
    Message.warning('请输入角色名')
    return
  }
  try {
    await api.post('/punish', addForm.value)
    Message.success('惩罚添加成功')
    addVisible.value = false
    loadData()
  } catch (e) {
    Message.error('添加失败: ' + (e.response?.data?.error || e.message))
  }
}

const removePunish = async (mId) => {
  try {
    await api.delete('/punish/' + mId)
    Message.success('惩罚已解除')
    loadData()
  } catch (e) {
    Message.error('解除失败: ' + (e.response?.data?.error || e.message))
  }
}

onMounted(() => { loadData() })
</script>

<style scoped>
.punish-page { padding: 16px; }
</style>
