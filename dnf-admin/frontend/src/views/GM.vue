<template>
  <div class="gm-page">
    <a-card :bordered="false">
      <a-tabs v-model:active-key="activeTab" type="card">
        <!-- 发送邮件 -->
        <a-tab-pane key="mail" title="发送邮件">
          <a-form :model="mailForm" layout="vertical" style="max-width: 600px">
            <a-form-item label="角色名"><a-input v-model="mailForm.character_name" placeholder="输入角色名" /></a-form-item>
            <a-form-item label="标题"><a-input v-model="mailForm.title" placeholder="邮件标题" /></a-form-item>
            <a-form-item label="内容"><a-textarea v-model="mailForm.content" :auto-size="{ minRows: 3, maxRows: 6 }" placeholder="邮件内容" /></a-form-item>
            <a-form-item label="金币"><a-input-number v-model="mailForm.gold" :min="0" :max="999999999" /></a-form-item>
            <a-form-item label="物品">
              <div v-for="(item, index) in mailForm.items" :key="index" class="item-row">
                <a-input-number v-model="item.item_id" placeholder="物品ID" style="width: 150px" />
                <a-input-number v-model="item.count" :min="1" :max="9999" style="width: 120px; margin-left: 10px" />
                <a-button type="text" status="danger" size="small" @click="removeMailItem(index)" style="margin-left: 8px">删除</a-button>
              </div>
              <a-button type="text" @click="addMailItem">+ 添加物品</a-button>
            </a-form-item>
            <a-form-item>
              <a-button type="primary" :loading="mailLoading" @click="sendMail">发送邮件</a-button>
            </a-form-item>
          </a-form>
        </a-tab-pane>

        <!-- 发送物品 -->
        <a-tab-pane key="item" title="发送物品">
          <a-form :model="itemForm" layout="vertical" style="max-width: 600px">
            <a-form-item label="角色名"><a-input v-model="itemForm.character_name" placeholder="输入角色名" /></a-form-item>
            <a-form-item label="物品ID"><a-input-number v-model="itemForm.item_id" :min="1" /></a-form-item>
            <a-form-item label="数量"><a-input-number v-model="itemForm.count" :min="1" :max="9999" /></a-form-item>
            <a-form-item>
              <a-button type="primary" :loading="itemLoading" @click="sendItem">发送物品</a-button>
            </a-form-item>
          </a-form>
        </a-tab-pane>

        <!-- 货币操作 -->
        <a-tab-pane key="gold" title="货币操作">
          <a-form :model="goldForm" layout="vertical" style="max-width: 600px">
            <a-form-item label="角色名"><a-input v-model="goldForm.character_name" placeholder="输入角色名" /></a-form-item>
            <a-form-item label="类型">
              <a-radio-group v-model="goldForm.type">
                <a-radio value="gold">金币</a-radio>
                <a-radio value="cera">点券</a-radio>
              </a-radio-group>
            </a-form-item>
            <a-form-item label="数量"><a-input-number v-model="goldForm.amount" :min="1" :max="999999999" /></a-form-item>
            <a-form-item>
              <a-button type="primary" :loading="goldLoading" @click="sendGold">充值</a-button>
            </a-form-item>
          </a-form>
        </a-tab-pane>

        <!-- 角色操作 -->
        <a-tab-pane key="character" title="角色操作">
          <a-form :model="charForm" layout="vertical" style="max-width: 600px">
            <a-form-item label="角色名"><a-input v-model="charForm.character_name" placeholder="输入角色名" /></a-form-item>
            <a-form-item label="操作">
              <a-radio-group v-model="charForm.action">
                <a-radio value="level">设置等级</a-radio>
                <a-radio value="fatigue">重置疲劳</a-radio>
              </a-radio-group>
            </a-form-item>
            <a-form-item v-if="charForm.action === 'level'" label="等级"><a-input-number v-model="charForm.level" :min="1" :max="100" /></a-form-item>
            <a-form-item>
              <a-button type="primary" :loading="charLoading" @click="characterAction">执行</a-button>
            </a-form-item>
          </a-form>
        </a-tab-pane>

        <!-- 封号管理 -->
        <a-tab-pane key="ban" title="封号管理">
          <a-form :model="banForm" layout="vertical" style="max-width: 600px">
            <a-form-item label="UID"><a-input-number v-model="banForm.uid" :min="1" /></a-form-item>
            <a-form-item label="操作">
              <a-radio-group v-model="banForm.action">
                <a-radio value="ban">封号</a-radio>
                <a-radio value="unban">解封</a-radio>
              </a-radio-group>
            </a-form-item>
            <a-form-item v-if="banForm.action === 'ban'" label="原因"><a-input v-model="banForm.reason" placeholder="封号原因" /></a-form-item>
            <a-form-item v-if="banForm.action === 'ban'" label="天数"><a-input-number v-model="banForm.days" :min="1" :max="365" /></a-form-item>
            <a-form-item>
              <a-button type="primary" :loading="banLoading" @click="banAction">执行</a-button>
            </a-form-item>
          </a-form>
        </a-tab-pane>
      </a-tabs>
    </a-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { Message, Modal } from '@arco-design/web-vue'
import api from '../api'

const activeTab = ref('mail')

const mailForm = reactive({ character_name: '', title: '', content: '', gold: 0, items: [] })
const mailLoading = ref(false)

const itemForm = reactive({ character_name: '', item_id: 0, count: 1 })
const itemLoading = ref(false)

const goldForm = reactive({ character_name: '', type: 'gold', amount: 0 })
const goldLoading = ref(false)

const charForm = reactive({ character_name: '', action: 'level', level: 1 })
const charLoading = ref(false)

const banForm = reactive({ uid: 0, action: 'ban', reason: '', days: 7 })
const banLoading = ref(false)

const addMailItem = () => mailForm.items.push({ item_id: 0, count: 1 })
const removeMailItem = (i) => mailForm.items.splice(i, 1)

const confirm = (msg) => new Promise((resolve) => {
  Modal.confirm({ title: '提示', content: msg, onOk: resolve })
})

const sendMail = async () => {
  await confirm('确认发送邮件？')
  mailLoading.value = true
  try {
    await api.post('/gm/mail', mailForm)
    Message.success('邮件发送成功')
    Object.assign(mailForm, { character_name: '', title: '', content: '', gold: 0, items: [] })
  } catch (e) { Message.error('发送失败: ' + (e.response?.data?.error || e.message)) }
  finally { mailLoading.value = false }
}

const sendItem = async () => {
  await confirm('确认发送物品？')
  itemLoading.value = true
  try {
    await api.post('/gm/item', itemForm)
    Message.success('物品发送成功')
  } catch (e) { Message.error('发送失败: ' + (e.response?.data?.error || e.message)) }
  finally { itemLoading.value = false }
}

const sendGold = async () => {
  await confirm('确认充值？')
  goldLoading.value = true
  try {
    const endpoint = goldForm.type === 'gold' ? '/gm/gold' : '/gm/cera'
    await api.post(endpoint, { character_name: goldForm.character_name, amount: goldForm.amount })
    Message.success('充值成功')
  } catch (e) { Message.error('充值失败: ' + (e.response?.data?.error || e.message)) }
  finally { goldLoading.value = false }
}

const characterAction = async () => {
  await confirm('确认执行操作？')
  charLoading.value = true
  try {
    if (charForm.action === 'level') {
      await api.post('/gm/character/level', { character_name: charForm.character_name, level: charForm.level })
    } else {
      await api.post('/gm/character/fatigue', { character_name: charForm.character_name })
    }
    Message.success('操作成功')
  } catch (e) { Message.error('操作失败: ' + (e.response?.data?.error || e.message)) }
  finally { charLoading.value = false }
}

const banAction = async () => {
  const label = banForm.action === 'ban' ? '封号' : '解封'
  await confirm(`确认${label}？`)
  banLoading.value = true
  try {
    if (banForm.action === 'ban') {
      await api.post('/gm/account/ban', banForm)
    } else {
      await api.post('/gm/account/unban', { uid: banForm.uid })
    }
    Message.success(`${label}成功`)
  } catch (e) { Message.error(`${label}失败: ` + (e.response?.data?.error || e.message)) }
  finally { banLoading.value = false }
}
</script>

<style scoped>
.gm-page { padding: 0; }
.item-row { display: flex; align-items: center; margin-bottom: 8px; }
</style>
