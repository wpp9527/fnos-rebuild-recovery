<template>
  <div class="pvf-page">
    <a-card :bordered="false">
      <template #extra>
        <a-button type="outline" status="warning" :loading="reloadLoading" @click="reloadPVF">重新加载</a-button>
      </template>
      <a-tabs v-model:active-key="activeTab">
        <a-tab-pane key="items" title="物品搜索">
          <a-space style="margin-bottom: 16px">
            <a-input v-model="searchQuery" placeholder="输入物品名称或ID" allow-clear style="width: 300px" @keyup.enter="searchItems">
              <template #append><a-button @click="searchItems">搜索</a-button></template>
            </a-input>
            <a-select v-model="searchCategory" placeholder="分类筛选" style="width: 150px" allow-clear @change="searchItems">
              <a-option value="">全部</a-option>
              <a-option value="武器">武器</a-option>
              <a-option value="防具">防具</a-option>
              <a-option value="首饰">首饰</a-option>
              <a-option value="特殊装备">特殊装备</a-option>
              <a-option value="消耗品">消耗品</a-option>
              <a-option value="材料">材料</a-option>
              <a-option value="时装">时装</a-option>
              <a-option value="称号">称号</a-option>
              <a-option value="宠物">宠物</a-option>
            </a-select>
            <a-select v-model="searchRarity" placeholder="稀有度" style="width: 120px" allow-clear @change="searchItems">
              <a-option value="">全部</a-option>
              <a-option value="普通">普通</a-option>
              <a-option value="稀有">稀有</a-option>
              <a-option value="神器">神器</a-option>
              <a-option value="传说">传说</a-option>
              <a-option value="史诗">史诗</a-option>
            </a-select>
          </a-space>
          <a-table :data="items" :loading="loading" :pagination="false">
            <template #columns>
              <a-table-column title="ID" data-index="id" :width="80" />
              <a-table-column title="名称" data-index="name" :width="180" />
              <a-table-column title="分类" data-index="category" :width="100" />
              <a-table-column title="类型" data-index="type" :width="120" />
              <a-table-column title="等级" data-index="level" :width="80" />
              <a-table-column title="稀有度" data-index="rarity" :width="100">
                <template #cell="{ record }">
                  <a-tag :color="getRarityColor(record.rarity)">{{ record.rarity }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="操作" :width="120">
                <template #cell="{ record }">
                  <a-space>
                    <a-button type="text" size="small" @click="viewItemDetail(record)">详情</a-button>
                    <a-button type="text" size="small" @click="sendItem(record.id)">发送</a-button>
                  </a-space>
                </template>
              </a-table-column>
            </template>
          </a-table>
          <div style="display: flex; justify-content: flex-end; margin-top: 12px;">
            <a-pagination
              :current="itemPage"
              :page-size="itemPageSize"
              :total="itemTotal"
              show-total
              show-jumper
              @change="onItemPageChange"
            />
          </div>
        </a-tab-pane>

        <a-tab-pane key="equipments" title="装备搜索">
          <a-input v-model="searchQuery" placeholder="输入装备名称或ID" allow-clear style="width: 400px; margin-bottom: 16px" @keyup.enter="searchEquipments">
            <template #append><a-button @click="searchEquipments">搜索</a-button></template>
          </a-input>
          <a-table :data="equipments" :loading="loading" :pagination="false">
            <template #columns>
              <a-table-column title="ID" data-index="id" :width="100" />
              <a-table-column title="名称" data-index="name" :width="200" />
              <a-table-column title="类型" data-index="type" :width="120" />
              <a-table-column title="等级" data-index="level" :width="80" />
              <a-table-column title="稀有度" data-index="rarity" :width="100" />
              <a-table-column title="描述" data-index="description" :ellipsis="true" />
              <a-table-column title="操作" :width="100">
                <template #cell="{ record }">
                  <a-button type="text" size="small" @click="sendItem(record.id)">发送</a-button>
                </template>
              </a-table-column>
            </template>
          </a-table>
        </a-tab-pane>

        <a-tab-pane key="skills" title="技能搜索">
          <a-input v-model="searchQuery" placeholder="输入技能名称或ID" allow-clear style="width: 400px; margin-bottom: 16px" @keyup.enter="searchSkills">
            <template #append><a-button @click="searchSkills">搜索</a-button></template>
          </a-input>
          <a-table :data="skills" :loading="loading" :pagination="false">
            <template #columns>
              <a-table-column title="ID" data-index="id" :width="100" />
              <a-table-column title="名称" data-index="name" :width="200" />
              <a-table-column title="等级" data-index="level" :width="80" />
              <a-table-column title="职业" data-index="job" :width="80" />
              <a-table-column title="最高等级" data-index="max_level" :width="100" />
              <a-table-column title="冷却时间" data-index="cooldown" :width="100" />
              <a-table-column title="描述" data-index="description" :ellipsis="true" />
            </template>
          </a-table>
        </a-tab-pane>
      </a-tabs>

      <a-divider />
      <a-space :size="40">
        <div><span style="color: #86909c">总物品数：</span><span style="font-weight: 700; font-size: 18px">{{ stats.total_items || 0 }}</span></div>
        <div><span style="color: #86909c">武器：</span><span style="font-weight: 700; font-size: 18px">{{ stats.categories?.武器 || 0 }}</span></div>
        <div><span style="color: #86909c">防具：</span><span style="font-weight: 700; font-size: 18px">{{ stats.categories?.防具 || 0 }}</span></div>
        <div><span style="color: #86909c">首饰：</span><span style="font-weight: 700; font-size: 18px">{{ stats.categories?.首饰 || 0 }}</span></div>
        <div><span style="color: #86909c">消耗品：</span><span style="font-weight: 700; font-size: 18px">{{ stats.categories?.消耗品 || 0 }}</span></div>
      </a-space>
    </a-card>

    <a-modal v-model:visible="sendDialogVisible" title="发送物品" :mask-closable="false" @ok="confirmSendItem" @cancel="sendDialogVisible = false">
      <a-form :model="sendForm" layout="vertical">
        <a-form-item label="角色名"><a-input v-model="sendForm.character_name" placeholder="输入角色名" /></a-form-item>
        <a-form-item label="物品ID"><a-input-number v-model="sendForm.item_id" disabled /></a-form-item>
        <a-form-item label="数量"><a-input-number v-model="sendForm.count" :min="1" :max="9999" /></a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:visible="detailVisible" title="物品详情" :width="500" :footer="false">
      <a-descriptions :column="1" bordered>
        <a-descriptions-item label="ID">{{ itemDetail.id }}</a-descriptions-item>
        <a-descriptions-item label="名称">{{ itemDetail.name }}</a-descriptions-item>
        <a-descriptions-item label="分类">{{ itemDetail.category }}</a-descriptions-item>
        <a-descriptions-item label="类型">{{ itemDetail.type }}</a-descriptions-item>
        <a-descriptions-item label="等级">{{ itemDetail.level }}</a-descriptions-item>
        <a-descriptions-item label="稀有度">
          <a-tag :color="getRarityColor(itemDetail.rarity)">{{ itemDetail.rarity }}</a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="描述">
          <div style="white-space: pre-line;">{{ itemDetail.description || '暂无描述' }}</div>
        </a-descriptions-item>
      </a-descriptions>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { Message, Modal } from '@arco-design/web-vue'
import api from '../api'

const activeTab = ref('items')
const searchQuery = ref('')
const searchCategory = ref('')
const searchRarity = ref('')
const loading = ref(false)
const reloadLoading = ref(false)

// 分页
const itemPage = ref(1)
const itemPageSize = ref(20)
const itemTotal = ref(0)

const getRarityColor = (rarity) => {
  const colors = { '普通': 'gray', '稀有': 'blue', '神器': 'purple', '传说': 'orange', '史诗': 'red' }
  return colors[rarity] || 'gray'
}

const items = ref([])
const equipments = ref([])
const skills = ref([])
const stats = ref({ total_items: 0, total_equipments: 0, total_skills: 0 })

const sendDialogVisible = ref(false)
const sendLoading = ref(false)
const sendForm = reactive({ character_name: '', item_id: 0, count: 1 })
const detailVisible = ref(false)
const itemDetail = ref({})

const searchItems = async (resetPage = false) => {
  if (resetPage) itemPage.value = 1
  loading.value = true
  try {
    let url = `/pvf/items?q=${searchQuery.value || ''}&page=${itemPage.value}&page_size=${itemPageSize.value}`
    if (searchCategory.value) url += `&category=${searchCategory.value}`
    if (searchRarity.value) url += `&rarity=${searchRarity.value}`
    const res = await api.get(url)
    items.value = res.data.data || []
    itemTotal.value = res.data.total || 0
  } catch { Message.error('搜索失败') }
  finally { loading.value = false }
}

const onItemPageChange = (page) => {
  itemPage.value = page
  searchItems()
}

const searchEquipments = async () => {
  if (!searchQuery.value) return
  loading.value = true
  try { equipments.value = (await api.get('/pvf/equipments', { params: { q: searchQuery.value } })).data || [] }
  catch { Message.error('搜索失败') }
  finally { loading.value = false }
}

const searchSkills = async () => {
  if (!searchQuery.value) return
  loading.value = true
  try { skills.value = (await api.get('/pvf/skills', { params: { q: searchQuery.value } })).data || [] }
  catch { Message.error('搜索失败') }
  finally { loading.value = false }
}

const reloadPVF = async () => {
  reloadLoading.value = true
  try { await api.post('/pvf/reload'); Message.success('PVF 重新加载成功'); loadStats() }
  catch { Message.error('重新加载失败') }
  finally { reloadLoading.value = false }
}

const loadStats = async () => {
  try { stats.value = (await api.get('/pvf/stats')).data || {} } catch {}
}

const sendItem = (id) => { sendForm.item_id = id; sendForm.count = 1; sendDialogVisible.value = true }

const viewItemDetail = (record) => { itemDetail.value = record; detailVisible.value = true }

const confirmSendItem = async () => {
  if (!sendForm.character_name) { Message.warning('请输入角色名'); return }
  Modal.confirm({ title: '提示', content: '确认发送物品？', onOk: async () => {
    sendLoading.value = true
    try { await api.post('/gm/item', sendForm); Message.success('物品发送成功'); sendDialogVisible.value = false }
    catch (e) { Message.error('发送失败: ' + (e.response?.data?.error || e.message)) }
    finally { sendLoading.value = false }
  }})
}

onMounted(loadStats)
</script>

<style scoped>
.pvf-page { padding: 0; }
</style>
