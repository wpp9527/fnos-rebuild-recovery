<template>
  <div class="postal-page">
    <a-row :gutter="16">
      <a-col :span="10">
        <a-card title="发送 GM 邮件" :bordered="false">
          <a-form :model="sendForm" layout="vertical">
            <a-form-item label="收件角色名" required>
              <a-input v-model="sendForm.charac_name" placeholder="输入角色名" />
            </a-form-item>
            <a-form-item label="标题" required>
              <a-input v-model="sendForm.title" placeholder="邮件标题" />
            </a-form-item>
            <a-form-item label="内容">
              <a-textarea v-model="sendForm.text" placeholder="邮件正文" :max-length="200" show-word-limit />
            </a-form-item>
            <a-form-item label="金币">
              <a-input-number v-model="sendForm.gold" :min="0" placeholder="附带金币" style="width:100%" />
            </a-form-item>
            <a-form-item>
              <a-button type="primary" @click="sendPostal" :loading="sending">发送邮件</a-button>
            </a-form-item>
          </a-form>
        </a-card>
      </a-col>
      <a-col :span="14">
        <a-card title="发送记录" :bordered="false">
          <a-form layout="inline" style="margin-bottom: 12px">
            <a-form-item label="角色编号">
              <a-input-number v-model="queryCharacNo" :min="0" placeholder="0=全部" style="width:120px" />
            </a-form-item>
            <a-form-item>
              <a-button type="primary" size="small" @click="loadHistory">查询</a-button>
            </a-form-item>
          </a-form>
          <a-table :data="history" :loading="historyLoading" :pagination="false" size="small">
            <template #columns>
              <a-table-column title="收件人" :width="120">
                <template #cell="{ record }">{{ decodeUnicode(record.recv_name) || '#' + record.recv_charac_no }}</template>
              </a-table-column>
              <a-table-column title="标题" :min-width="150">
                <template #cell="{ record }">{{ decodeUnicode(record.title) }}</template>
              </a-table-column>
              <a-table-column title="金币" data-index="gold" :width="80" />
              <a-table-column title="时间" :width="150">
                <template #cell="{ record }">{{ record.send_time || '-' }}</template>
              </a-table-column>
            </template>
          </a-table>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message } from '@arco-design/web-vue'
import api from '../api'

const sendForm = ref({ charac_name: '', title: '', text: '', gold: 0 })
const sending = ref(false)
const history = ref([])
const historyLoading = ref(false)
const queryCharacNo = ref(0)

const decodeUnicode = (str) => {
  if (!str) return str
  return str.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

const sendPostal = async () => {
  if (!sendForm.value.charac_name || !sendForm.value.title) {
    Message.warning('请填写收件人和标题')
    return
  }
  sending.value = true
  try {
    await api.post('/postal', sendForm.value)
    Message.success('邮件发送成功')
    sendForm.value = { charac_name: '', title: '', text: '', gold: 0 }
    loadHistory()
  } catch (e) {
    Message.error('发送失败: ' + (e.response?.data?.error || e.message))
  } finally { sending.value = false }
}

const loadHistory = async () => {
  historyLoading.value = true
  try {
    let url = '/postal/history?limit=50'
    if (queryCharacNo.value > 0) url += '&charac_no=' + queryCharacNo.value
    const res = await api.get(url)
    history.value = res.data || []
  } catch (e) {
    history.value = []
  } finally { historyLoading.value = false }
}

onMounted(() => { loadHistory() })
</script>

<style scoped>
.postal-page { padding: 16px; }
</style>
