<template>
  <div class="gm-page">
    <el-tabs v-model="activeTab" type="border-card">
      <!-- Mail Tab -->
      <el-tab-pane label="发送邮件" name="mail">
        <el-form :model="mailForm" label-width="100px" style="max-width: 600px">
          <el-form-item label="角色名">
            <el-input v-model="mailForm.character_name" placeholder="输入角色名" />
          </el-form-item>
          <el-form-item label="标题">
            <el-input v-model="mailForm.title" placeholder="邮件标题" />
          </el-form-item>
          <el-form-item label="内容">
            <el-input v-model="mailForm.content" type="textarea" :rows="4" placeholder="邮件内容" />
          </el-form-item>
          <el-form-item label="金币">
            <el-input-number v-model="mailForm.gold" :min="0" :max="999999999" />
          </el-form-item>
          <el-form-item label="物品">
            <div v-for="(item, index) in mailForm.items" :key="index" class="item-row">
              <el-input v-model.number="item.item_id" placeholder="物品ID" style="width: 150px" />
              <el-input-number v-model="item.count" :min="1" :max="9999" style="width: 150px; margin-left: 10px" />
              <el-button type="danger" :icon="Delete" circle size="small" @click="removeMailItem(index)" style="margin-left: 10px" />
            </div>
            <el-button type="primary" link @click="addMailItem">+ 添加物品</el-button>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="sendMail" :loading="mailLoading">发送邮件</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- Item Tab -->
      <el-tab-pane label="发送物品" name="item">
        <el-form :model="itemForm" label-width="100px" style="max-width: 600px">
          <el-form-item label="角色名">
            <el-input v-model="itemForm.character_name" placeholder="输入角色名" />
          </el-form-item>
          <el-form-item label="物品ID">
            <el-input-number v-model="itemForm.item_id" :min="1" />
          </el-form-item>
          <el-form-item label="数量">
            <el-input-number v-model="itemForm.count" :min="1" :max="9999" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="sendItem" :loading="itemLoading">发送物品</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- Gold Tab -->
      <el-tab-pane label="货币操作" name="gold">
        <el-form :model="goldForm" label-width="100px" style="max-width: 600px">
          <el-form-item label="角色名">
            <el-input v-model="goldForm.character_name" placeholder="输入角色名" />
          </el-form-item>
          <el-form-item label="类型">
            <el-radio-group v-model="goldForm.type">
              <el-radio value="gold">金币</el-radio>
              <el-radio value="cera">点券</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="数量">
            <el-input-number v-model="goldForm.amount" :min="1" :max="999999999" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="sendGold" :loading="goldLoading">充值</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- Character Tab -->
      <el-tab-pane label="角色操作" name="character">
        <el-form :model="charForm" label-width="100px" style="max-width: 600px">
          <el-form-item label="角色名">
            <el-input v-model="charForm.character_name" placeholder="输入角色名" />
          </el-form-item>
          <el-form-item label="操作">
            <el-radio-group v-model="charForm.action">
              <el-radio value="level">设置等级</el-radio>
              <el-radio value="fatigue">重置疲劳</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="等级" v-if="charForm.action === 'level'">
            <el-input-number v-model="charForm.level" :min="1" :max="100" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="characterAction" :loading="charLoading">执行</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- Ban Tab -->
      <el-tab-pane label="封号管理" name="ban">
        <el-form :model="banForm" label-width="100px" style="max-width: 600px">
          <el-form-item label="UID">
            <el-input-number v-model="banForm.uid" :min="1" />
          </el-form-item>
          <el-form-item label="操作">
            <el-radio-group v-model="banForm.action">
              <el-radio value="ban">封号</el-radio>
              <el-radio value="unban">解封</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="原因" v-if="banForm.action === 'ban'">
            <el-input v-model="banForm.reason" placeholder="封号原因" />
          </el-form-item>
          <el-form-item label="天数" v-if="banForm.action === 'ban'">
            <el-input-number v-model="banForm.days" :min="1" :max="365" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="banAction" :loading="banLoading">执行</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete } from '@element-plus/icons-vue'
import api from '../api'

const activeTab = ref('mail')

// Mail form
const mailForm = reactive({
  character_name: '',
  title: '',
  content: '',
  gold: 0,
  items: []
})
const mailLoading = ref(false)

// Item form
const itemForm = reactive({
  character_name: '',
  item_id: 0,
  count: 1
})
const itemLoading = ref(false)

// Gold form
const goldForm = reactive({
  character_name: '',
  type: 'gold',
  amount: 0
})
const goldLoading = ref(false)

// Character form
const charForm = reactive({
  character_name: '',
  action: 'level',
  level: 1
})
const charLoading = ref(false)

// Ban form
const banForm = reactive({
  uid: 0,
  action: 'ban',
  reason: '',
  days: 7
})
const banLoading = ref(false)

const addMailItem = () => {
  mailForm.items.push({ item_id: 0, count: 1 })
}

const removeMailItem = (index) => {
  mailForm.items.splice(index, 1)
}

const sendMail = async () => {
  await ElMessageBox.confirm('确认发送邮件？', '提示', { type: 'warning' })
  mailLoading.value = true
  try {
    await api.post('/gm/mail', mailForm)
    ElMessage.success('邮件发送成功')
    mailForm.character_name = ''
    mailForm.title = ''
    mailForm.content = ''
    mailForm.gold = 0
    mailForm.items = []
  } catch (error) {
    ElMessage.error('发送失败: ' + (error.response?.data?.error || error.message))
  } finally {
    mailLoading.value = false
  }
}

const sendItem = async () => {
  await ElMessageBox.confirm('确认发送物品？', '提示', { type: 'warning' })
  itemLoading.value = true
  try {
    await api.post('/gm/item', itemForm)
    ElMessage.success('物品发送成功')
  } catch (error) {
    ElMessage.error('发送失败: ' + (error.response?.data?.error || error.message))
  } finally {
    itemLoading.value = false
  }
}

const sendGold = async () => {
  await ElMessageBox.confirm('确认充值？', '提示', { type: 'warning' })
  goldLoading.value = true
  try {
    const endpoint = goldForm.type === 'gold' ? '/gm/gold' : '/gm/cera'
    await api.post(endpoint, { character_name: goldForm.character_name, amount: goldForm.amount })
    ElMessage.success('充值成功')
  } catch (error) {
    ElMessage.error('充值失败: ' + (error.response?.data?.error || error.message))
  } finally {
    goldLoading.value = false
  }
}

const characterAction = async () => {
  await ElMessageBox.confirm('确认执行操作？', '提示', { type: 'warning' })
  charLoading.value = true
  try {
    if (charForm.action === 'level') {
      await api.post('/gm/character/level', { character_name: charForm.character_name, level: charForm.level })
    } else {
      await api.post('/gm/character/fatigue', { character_name: charForm.character_name })
    }
    ElMessage.success('操作成功')
  } catch (error) {
    ElMessage.error('操作失败: ' + (error.response?.data?.error || error.message))
  } finally {
    charLoading.value = false
  }
}

const banAction = async () => {
  const action = banForm.action === 'ban' ? '封号' : '解封'
  await ElMessageBox.confirm(`确认${action}？`, '提示', { type: 'warning' })
  banLoading.value = true
  try {
    if (banForm.action === 'ban') {
      await api.post('/gm/account/ban', banForm)
    } else {
      await api.post('/gm/account/unban', { uid: banForm.uid })
    }
    ElMessage.success(`${action}成功`)
  } catch (error) {
    ElMessage.error(`${action}失败: ` + (error.response?.data?.error || error.message))
  } finally {
    banLoading.value = false
  }
}
</script>

<style scoped>
.item-row {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}
</style>
