<template>
  <div class="characters-page">
    <a-card :bordered="false">
      <a-form layout="inline" :model="searchForm">
        <a-form-item label="账号">
          <a-input v-model="searchForm.account" placeholder="所属账号" allow-clear />
        </a-form-item>
        <a-form-item label="角色名">
          <a-input v-model="searchForm.name" placeholder="角色名称" allow-clear />
        </a-form-item>
        <a-form-item label="职业">
          <a-select v-model="searchForm.job" placeholder="选择职业" style="width: 150px" allow-clear>
            <a-option value="">全部</a-option>
            <a-option :value="0">鬼剑士</a-option>
            <a-option :value="1">格斗家</a-option>
            <a-option :value="2">神枪手</a-option>
            <a-option :value="3">魔法师</a-option>
            <a-option :value="4">圣职者</a-option>
            <a-option :value="5">暗夜使者</a-option>
            <a-option :value="6">魔枪士</a-option>
            <a-option :value="7">枪剑士</a-option>
            <a-option :value="8">弓箭手</a-option>
          </a-select>
        </a-form-item>
        <a-form-item label="等级">
          <a-input-number v-model="searchForm.minLev" :min="1" :max="86" placeholder="最低" style="width: 100px" />
          <span style="margin: 0 8px">-</span>
          <a-input-number v-model="searchForm.maxLev" :min="1" :max="86" placeholder="最高" style="width: 100px" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" @click="search(true)">查询</a-button>
        </a-form-item>
      </a-form>
    </a-card>

    <a-table
      :data="characters"
      :loading="loading"
      :pagination="false"
      style="margin-top: 16px"
    >
      <template #columns>
        <a-table-column title="ID" data-index="c_no" :width="80" />
        <a-table-column title="昵称" data-index="c_name" />
        <a-table-column title="账号ID" data-index="uid" :width="80" />
        <a-table-column title="等级" data-index="c_level" :width="70" />
        <a-table-column title="职业" :width="120">
          <template #cell="{ record }">
            <a-tag :color="getJobColor(record.c_job)">{{ getJobName(record.c_job, record.sex) }}</a-tag>
          </template>
        </a-table-column>
        <a-table-column title="HP" data-index="max_hp" :width="80" />
        <a-table-column title="MP" data-index="max_mp" :width="80" />
        <a-table-column title="物攻" data-index="phy_attack" :width="80" />
        <a-table-column title="魔攻" data-index="mag_attack" :width="80" />
        <a-table-column title="疲劳" data-index="c_fatigue" :width="70" />
        <a-table-column title="操作" :width="200">
          <template #cell="{ record }">
            <a-space>
              <a-button type="text" size="small" @click="viewDetail(record)">详情</a-button>
              <a-button type="text" size="small" status="success" @click="viewInventory(record)">背包</a-button>
              <a-button type="text" size="small" status="warning" @click="editCharacter(record)">编辑</a-button>
              <a-button type="text" size="small" status="danger" @click="sendMail(record)">邮件</a-button>
            </a-space>
          </template>
        </a-table-column>
      </template>
    </a-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
      <a-pagination
        :current="pageNum"
        :page-size="pageSize"
        :total="total"
        show-total
        show-jumper
        show-page-size
        :page-size-options="[10, 20, 50, 100]"
        @change="onPageChange"
        @page-size-change="onPageSizeChange"
      />
    </div>

    <!-- 角色详情弹窗 -->
    <a-modal v-model:visible="detailVisible" title="角色详情" :width="700" :footer="false">
      <a-descriptions :column="2" bordered size="small">
        <a-descriptions-item label="角色ID">{{ detail.c_no }}</a-descriptions-item>
        <a-descriptions-item label="角色名">{{ detail.c_name }}</a-descriptions-item>
        <a-descriptions-item label="等级">{{ detail.c_level }}</a-descriptions-item>
        <a-descriptions-item label="职业">{{ getJobName(detail.c_job, detail.sex) }}</a-descriptions-item>
        <a-descriptions-item label="转职类型">{{ detail.grow_type === 0 ? '未转职' : '已转职' }}</a-descriptions-item>
        <a-descriptions-item label="经验值">{{ detail.exp }}</a-descriptions-item>
        <a-descriptions-item label="HP">{{ detail.max_hp }}</a-descriptions-item>
        <a-descriptions-item label="MP">{{ detail.max_mp }}</a-descriptions-item>
        <a-descriptions-item label="物理攻击">{{ detail.phy_attack }}</a-descriptions-item>
        <a-descriptions-item label="物理防御">{{ detail.phy_defense }}</a-descriptions-item>
        <a-descriptions-item label="魔法攻击">{{ detail.mag_attack }}</a-descriptions-item>
        <a-descriptions-item label="魔法防御">{{ detail.mag_defense }}</a-descriptions-item>
        <a-descriptions-item label="移动速度">{{ detail.move_speed }}</a-descriptions-item>
        <a-descriptions-item label="攻击速度">{{ detail.attack_speed }}</a-descriptions-item>
        <a-descriptions-item label="施放速度">{{ detail.cast_speed }}</a-descriptions-item>
        <a-descriptions-item label="跳跃力">{{ detail.jump }}</a-descriptions-item>
        <a-descriptions-item label="硬直恢复">{{ detail.hit_recovery }}</a-descriptions-item>
        <a-descriptions-item label="疲劳值">{{ detail.c_fatigue }}</a-descriptions-item>
        <a-descriptions-item label="创建时间">{{ detail.create_time }}</a-descriptions-item>
        <a-descriptions-item label="最后登录">{{ detail.c_last_login }}</a-descriptions-item>
      </a-descriptions>
    </a-modal>

    <!-- 背包弹窗 -->
    <a-modal v-model:visible="inventoryVisible" title="角色背包" :width="900" :footer="false">
      <a-tabs v-model:active-key="inventoryTab">
        <a-tab-pane key="all" title="全部">
          <a-table :data="inventory" :loading="inventoryLoading" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="槽位" data-index="slot" :width="60" />
              <a-table-column title="物品ID" data-index="it_id" :width="120" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  {{ record.item_name || `物品#${record.it_id}` }}
                </template>
              </a-table-column>
              <a-table-column title="类型" :width="100">
                <template #cell="{ record }">
                  <a-tag :color="getItemTypeColor(record.it_id)">{{ getItemTypeName(record.it_id) }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
              <a-table-column title="强化" data-index="enhance" :width="60" />
              <a-table-column title="品质" :width="80">
                <template #cell="{ record }">
                  <a-tag :color="getRarityColor(record.rarity)">{{ getRarityName(record.rarity) }}</a-tag>
                </template>
              </a-table-column>
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="equip" title="装备">
          <a-table :data="inventoryEquip" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="槽位" data-index="slot" :width="60" />
              <a-table-column title="物品ID" data-index="it_id" :width="120" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  {{ record.item_name || `物品#${record.it_id}` }}
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
              <a-table-column title="强化" data-index="enhance" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="consumable" title="消耗品">
          <a-table :data="inventoryConsumable" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="槽位" data-index="slot" :width="60" />
              <a-table-column title="物品ID" data-index="it_id" :width="120" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  {{ record.item_name || `物品#${record.it_id}` }}
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="material" title="材料">
          <a-table :data="inventoryMaterial" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="槽位" data-index="slot" :width="60" />
              <a-table-column title="物品ID" data-index="it_id" :width="120" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  {{ record.item_name || `物品#${record.it_id}` }}
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="quest" title="任务">
          <a-table :data="inventoryQuest" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="槽位" data-index="slot" :width="60" />
              <a-table-column title="物品ID" data-index="it_id" :width="120" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  {{ record.item_name || `物品#${record.it_id}` }}
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
      </a-tabs>
    </a-modal>

    <!-- 编辑角色弹窗 -->
    <a-modal v-model:visible="editVisible" title="编辑角色" :width="600" @ok="confirmEdit">
      <a-form :model="editForm" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="角色名"><a-input v-model="editForm.c_name" disabled /></a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="职业"><a-input :model-value="getJobName(editForm.c_job, editForm.sex)" disabled /></a-form-item>
          </a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="等级"><a-input-number v-model="editForm.c_level" :min="1" :max="86" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="HP"><a-input-number v-model="editForm.max_hp" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="MP"><a-input-number v-model="editForm.max_mp" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="物攻"><a-input-number v-model="editForm.phy_attack" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="魔攻"><a-input-number v-model="editForm.mag_attack" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="疲劳"><a-input-number v-model="editForm.c_fatigue" :min="0" :max="156" style="width: 100%" /></a-form-item>
          </a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="物防"><a-input-number v-model="editForm.phy_defense" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="魔防"><a-input-number v-model="editForm.mag_defense" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="移动速度"><a-input-number v-model="editForm.move_speed" :min="0" style="width: 100%" /></a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- 发送邮件弹窗 -->
    <a-modal v-model:visible="mailVisible" title="发送邮件" @ok="confirmSendMail">
      <a-form :model="mailForm" layout="vertical">
        <a-form-item label="收件角色"><a-input v-model="mailForm.character_name" disabled /></a-form-item>
        <a-form-item label="标题"><a-input v-model="mailForm.title" placeholder="邮件标题" /></a-form-item>
        <a-form-item label="内容"><a-textarea v-model="mailForm.content" placeholder="邮件内容" /></a-form-item>
        <a-form-item label="金币"><a-input-number v-model="mailForm.gold" :min="0" style="width: 100%" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Message, Modal } from '@arco-design/web-vue'
import api from '../api'

const characters = ref([])
const loading = ref(false)
const pageNum = ref(1)
const pageSize = ref(20)
const total = ref(0)

const searchForm = ref({
  account: '',
  name: '',
  job: '',
  minLev: null,
  maxLev: null
})

const detailVisible = ref(false)
const detail = ref({})
const inventoryVisible = ref(false)
const inventoryLoading = ref(false)
const inventory = ref([])
const inventoryTab = ref('all')
const editVisible = ref(false)
const editForm = ref({})
const mailVisible = ref(false)
const mailForm = ref({ character_name: '', title: '', content: '', gold: 0 })

// 物品分类函数
const getItemType = (itemId) => {
  if (itemId >= 10000000 && itemId < 20000000) return 'equip'
  if (itemId >= 20000000 && itemId < 30000000) return 'consumable'
  if (itemId >= 30000000 && itemId < 40000000) return 'material'
  if (itemId >= 40000000 && itemId < 50000000) return 'quest'
  return 'other'
}

const getItemTypeName = (itemId) => {
  const types = {
    'equip': '装备',
    'consumable': '消耗品',
    'material': '材料',
    'quest': '任务',
    'other': '其他'
  }
  return types[getItemType(itemId)] || '未知'
}

const getItemTypeColor = (itemId) => {
  const colors = {
    'equip': 'blue',
    'consumable': 'green',
    'material': 'orange',
    'quest': 'purple',
    'other': 'gray'
  }
  return colors[getItemType(itemId)] || 'gray'
}

// 计算属性：分类物品列表
const inventoryEquip = computed(() => inventory.value.filter(i => getItemType(i.it_id) === 'equip'))
const inventoryConsumable = computed(() => inventory.value.filter(i => getItemType(i.it_id) === 'consumable'))
const inventoryMaterial = computed(() => inventory.value.filter(i => getItemType(i.it_id) === 'material'))
const inventoryQuest = computed(() => inventory.value.filter(i => getItemType(i.it_id) === 'quest'))

// 完整职业映射 (job + sex 组合)
// job编号按性别交替: 0=鬼剑(男), 1=鬼剑(女), 2=格斗(男), 3=格斗(女), 4=神枪(男), 5=神枪(女)...
// sex: 0=男, 1=女
const getJobName = (job, sex) => {
  const baseJobs = {
    0: '鬼剑士', 2: '格斗家', 4: '神枪手', 6: '魔法师',
    8: '圣职者', 10: '暗夜使者', 12: '魔枪士', 14: '枪剑士', 16: '弓箭手'
  }
  // job 为奇数时是女性职业
  const isFemale = job % 2 === 1
  const baseIndex = Math.floor(job / 2) * 2
  const baseName = baseJobs[baseIndex] || `职业${job}`
  return baseName + (isFemale ? '(女)' : '(男)')
}

const getJobColor = (job) => {
  const colors = {
    0: 'red', 1: 'red',       // 鬼剑士
    2: 'orange', 3: 'orange', // 格斗家
    4: 'blue', 5: 'blue',     // 神枪手
    6: 'purple', 7: 'purple', // 魔法师
    8: 'gold', 9: 'gold',     // 圣职者
    10: 'cyan', 11: 'cyan',   // 暗夜使者
    12: 'magenta', 13: 'magenta', // 魔枪士
    14: 'lime', 15: 'lime',   // 枪剑士
    16: 'pink', 17: 'pink'    // 弓箭手
  }
  return colors[job] || 'gray'
}

const getRarityColor = (rarity) => {
  const colors = { 0: 'gray', 1: 'blue', 2: 'purple', 3: 'orange', 4: 'red' }
  return colors[rarity] || 'gray'
}

const getRarityName = (rarity) => {
  const names = { 0: '普通', 1: '稀有', 2: '神器', 3: '传说', 4: '史诗' }
  return names[rarity] || `品质${rarity}`
}

const search = async (resetPage = false) => {
  if (resetPage) pageNum.value = 1
  loading.value = true
  try {
    let url = `/characters/search?page=${pageNum.value}&page_size=${pageSize.value}`
    if (searchForm.value.name) url += `&q=${searchForm.value.name}`
    if (searchForm.value.account) url += `&account=${searchForm.value.account}`
    if (searchForm.value.job !== '' && searchForm.value.job !== undefined) url += `&job=${searchForm.value.job}`
    if (searchForm.value.minLev) url += `&minLev=${searchForm.value.minLev}`
    if (searchForm.value.maxLev) url += `&maxLevel=${searchForm.value.maxLev}`
    const res = await api.get(url)
    characters.value = res.data.data || []
    total.value = res.data.total || 0
  } catch (e) { Message.error('搜索失败: ' + (e.response?.data?.error || e.message)) }
  finally { loading.value = false }
}

const onPageChange = (page) => { pageNum.value = page; search() }
const onPageSizeChange = (size) => { pageSize.value = size; pageNum.value = 1; search() }

const viewDetail = (record) => { detail.value = record; detailVisible.value = true }

const viewInventory = async (record) => {
  inventoryVisible.value = true
  inventoryLoading.value = true
  try {
    const res = await api.get(`/characters/${record.c_no}/items`)
    inventory.value = res.data || []
  } catch { inventory.value = [] }
  finally { inventoryLoading.value = false }
}

const editCharacter = (record) => {
  editForm.value = { ...record }
  editVisible.value = true
}

const confirmEdit = async () => {
  try {
    await api.put(`/charac`, {
      c_no: editForm.value.c_no,
      c_level: editForm.value.c_level,
      max_hp: editForm.value.max_hp,
      max_mp: editForm.value.max_mp,
      phy_attack: editForm.value.phy_attack,
      phy_defense: editForm.value.phy_defense,
      mag_attack: editForm.value.mag_attack,
      mag_defense: editForm.value.mag_defense,
      move_speed: editForm.value.move_speed,
      c_fatigue: editForm.value.c_fatigue
    })
    Message.success('角色更新成功')
    editVisible.value = false
    search()
  } catch (e) { Message.error('更新失败: ' + (e.response?.data?.error || e.message)) }
}

const sendMail = (record) => {
  mailForm.value = { character_name: record.c_name, title: '', content: '', gold: 0 }
  mailVisible.value = true
}

const confirmSendMail = async () => {
  try {
    await api.post('/gm/mail', mailForm.value)
    Message.success('邮件发送成功')
    mailVisible.value = false
  } catch (e) { Message.error('发送失败: ' + (e.response?.data?.error || e.message)) }
}

onMounted(() => { search() })
</script>

<style scoped>
.characters-page { padding: 16px; }
</style>
