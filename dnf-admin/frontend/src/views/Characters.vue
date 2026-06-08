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

    <a-table :data="characters" :loading="loading" :pagination="false" style="margin-top: 16px">
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
              <a-button type="text" size="small" status="success" @click="viewEquipment(record)">装备</a-button>
              <a-button type="text" size="small" status="warning" @click="viewInventory(record)">背包</a-button>
              <a-button type="text" size="small" status="danger" @click="editCharacter(record)">编辑</a-button>
            </a-space>
          </template>
        </a-table-column>
      </template>
    </a-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
      <a-pagination :current="pageNum" :page-size="pageSize" :total="total" show-total show-jumper show-page-size
        :page-size-options="[10, 20, 50, 100]" @change="onPageChange" @page-size-change="onPageSizeChange" />
    </div>

    <!-- 角色详情弹窗 -->
    <a-modal v-model:visible="detailVisible" title="角色详情" :width="700" :footer="false">
      <a-descriptions :column="2" bordered size="small">
        <a-descriptions-item label="角色ID">{{ detail.c_no }}</a-descriptions-item>
        <a-descriptions-item label="角色名">{{ detail.c_name }}</a-descriptions-item>
        <a-descriptions-item label="等级">{{ detail.c_level }}</a-descriptions-item>
        <a-descriptions-item label="职业">{{ getJobName(detail.c_job, detail.sex) }}</a-descriptions-item>
        <a-descriptions-item label="HP">{{ detail.max_hp }}</a-descriptions-item>
        <a-descriptions-item label="MP">{{ detail.max_mp }}</a-descriptions-item>
        <a-descriptions-item label="物理攻击">{{ detail.phy_attack }}</a-descriptions-item>
        <a-descriptions-item label="物理防御">{{ detail.phy_defense }}</a-descriptions-item>
        <a-descriptions-item label="魔法攻击">{{ detail.mag_attack }}</a-descriptions-item>
        <a-descriptions-item label="魔法防御">{{ detail.mag_defense }}</a-descriptions-item>
        <a-descriptions-item label="疲劳值">{{ detail.c_fatigue }}</a-descriptions-item>
      </a-descriptions>
    </a-modal>

    <!-- 装备栏弹窗 -->
    <a-modal v-model:visible="equipmentVisible" title="装备栏" :width="900" :footer="false">
      <a-spin :loading="equipmentLoading" style="width: 100%">
        <a-table :data="equipment" :pagination="false" size="small">
          <template #columns>
            <a-table-column title="槽位" data-index="slot_name" :width="100" />
            <a-table-column title="装备名称" :width="200">
              <template #cell="{ record }">
                <span :style="{ color: getRarityColorHex(record.rarity), fontWeight: record.rarity >= 3 ? 'bold' : 'normal' }">
                  {{ record.item_name || (record.it_id ? '装备#' + record.it_id : '空') }}
                </span>
              </template>
            </a-table-column>
            <a-table-column title="品质" :width="80">
              <template #cell="{ record }">
                <a-tag v-if="record.it_id" :color="getRarityColor(record.rarity)">{{ getRarityName(record.rarity) }}</a-tag>
              </template>
            </a-table-column>
            <a-table-column title="等级" :width="60">
              <template #cell="{ record }">{{ record.level > 0 ? record.level : '-' }}</template>
            </a-table-column>
            <a-table-column title="强化" :width="60">
              <template #cell="{ record }">
                <span v-if="record.enhance > 0" style="color: #f5222d">+{{ record.enhance }}</span>
                <span v-else>-</span>
              </template>
            </a-table-column>
            <a-table-column title="属性" :min-width="250">
              <template #cell="{ record }">
                <span v-if="record.phy_attack" class="stat-tag atk">物攻+{{ record.phy_attack }}</span>
                <span v-if="record.mag_attack" class="stat-tag atk">魔攻+{{ record.mag_attack }}</span>
                <span v-if="record.phy_defense" class="stat-tag def">物防+{{ record.phy_defense }}</span>
                <span v-if="record.mag_defense" class="stat-tag def">魔防+{{ record.mag_defense }}</span>
                <span v-if="record.str" class="stat-tag stat">力量+{{ record.str }}</span>
                <span v-if="record.int" class="stat-tag stat">智力+{{ record.int }}</span>
                <span v-if="record.vit" class="stat-tag stat">体力+{{ record.vit }}</span>
                <span v-if="record.spr" class="stat-tag stat">精神+{{ record.spr }}</span>
                <span v-if="record.phy_crit" class="stat-tag crit">物暴+{{ record.phy_crit }}</span>
                <span v-if="record.mag_crit" class="stat-tag crit">魔暴+{{ record.mag_crit }}</span>
              </template>
            </a-table-column>
          </template>
        </a-table>
      </a-spin>
    </a-modal>

    <!-- 背包弹窗 -->
    <a-modal v-model:visible="inventoryVisible" title="角色背包" :width="900" :footer="false">
      <a-tabs v-model:active-key="inventoryTab">
        <a-tab-pane key="all" :title="'全部 (' + inventory.length + ')'">
          <a-table :data="inventory" :loading="inventoryLoading" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="物品ID" data-index="it_id" :width="80" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }">
                  <span :style="{ color: getRarityColorHex(record.rarity) }">{{ record.item_name || '物品#' + record.it_id }}</span>
                </template>
              </a-table-column>
              <a-table-column title="分类" :width="80">
                <template #cell="{ record }">
                  <a-tag :color="getCategoryColor(record.category)" size="small">{{ record.category || '其他' }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
              <a-table-column title="品质" :width="80">
                <template #cell="{ record }">
                  <a-tag v-if="record.rarity" :color="getRarityColor(record.rarity)" size="small">{{ getRarityName(record.rarity) }}</a-tag>
                </template>
              </a-table-column>
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="equip" :title="'装备 (' + inventoryEquip.length + ')'">
          <a-table :data="inventoryEquip" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="物品ID" data-index="it_id" :width="80" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }"><span :style="{ color: getRarityColorHex(record.rarity) }">{{ record.item_name }}</span></template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="consumable" :title="'消耗品 (' + inventoryConsumable.length + ')'">
          <a-table :data="inventoryConsumable" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="物品ID" data-index="it_id" :width="80" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }"><span :style="{ color: getRarityColorHex(record.rarity) }">{{ record.item_name }}</span></template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="material" :title="'材料 (' + inventoryMaterial.length + ')'">
          <a-table :data="inventoryMaterial" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="物品ID" data-index="it_id" :width="80" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }"><span :style="{ color: getRarityColorHex(record.rarity) }">{{ record.item_name }}</span></template>
              </a-table-column>
              <a-table-column title="数量" data-index="count" :width="60" />
            </template>
          </a-table>
        </a-tab-pane>
        <a-tab-pane key="quest" :title="'任务 (' + inventoryQuest.length + ')'">
          <a-table :data="inventoryQuest" :pagination="false" size="small" :scroll="{ y: 400 }">
            <template #columns>
              <a-table-column title="物品ID" data-index="it_id" :width="80" />
              <a-table-column title="物品名称" :width="200">
                <template #cell="{ record }"><span :style="{ color: getRarityColorHex(record.rarity) }">{{ record.item_name }}</span></template>
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
          <a-col :span="12"><a-form-item label="角色名"><a-input v-model="editForm.c_name" disabled /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="职业"><a-input :model-value="getJobName(editForm.c_job, editForm.sex)" disabled /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8"><a-form-item label="等级"><a-input-number v-model="editForm.c_level" :min="1" :max="86" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="HP"><a-input-number v-model="editForm.max_hp" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="MP"><a-input-number v-model="editForm.max_mp" :min="0" style="width: 100%" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8"><a-form-item label="物攻"><a-input-number v-model="editForm.phy_attack" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="魔攻"><a-input-number v-model="editForm.mag_attack" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="疲劳"><a-input-number v-model="editForm.c_fatigue" :min="0" :max="156" style="width: 100%" /></a-form-item></a-col>
        </a-row>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Message } from '@arco-design/web-vue'
import api from '../api'

const characters = ref([])
const loading = ref(false)
const pageNum = ref(1)
const pageSize = ref(20)
const total = ref(0)
const searchForm = ref({ account: '', name: '', job: '', minLev: null, maxLev: null })

const detailVisible = ref(false)
const detail = ref({})
const equipmentVisible = ref(false)
const equipmentLoading = ref(false)
const equipment = ref([])
const inventoryVisible = ref(false)
const inventoryLoading = ref(false)
const inventory = ref([])
const inventoryTab = ref('all')
const editVisible = ref(false)
const editForm = ref({})

const decodeUnicode = (str) => {
  if (!str) return str
  return str.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

const inventoryEquip = computed(() => inventory.value.filter(i => i.category === '裝備'))
const inventoryConsumable = computed(() => inventory.value.filter(i => i.category === '消耗品'))
const inventoryMaterial = computed(() => inventory.value.filter(i => i.category === '材料'))
const inventoryQuest = computed(() => inventory.value.filter(i => i.category === '任務'))

const getJobName = (job, sex) => {
  const baseJobs = { 0: '鬼剑士', 2: '格斗家', 4: '神枪手', 6: '魔法师', 8: '圣职者', 10: '暗夜使者', 12: '魔枪士', 14: '枪剑士', 16: '弓箭手' }
  const isFemale = job % 2 === 1
  const baseIndex = Math.floor(job / 2) * 2
  return (baseJobs[baseIndex] || '职业' + job) + (isFemale ? '(女)' : '(男)')
}

const getJobColor = (job) => {
  const colors = { 0: 'red', 1: 'red', 2: 'orange', 3: 'orange', 4: 'blue', 5: 'blue', 6: 'purple', 7: 'purple', 8: 'gold', 9: 'gold', 10: 'cyan', 11: 'cyan', 12: 'magenta', 13: 'magenta', 14: 'lime', 15: 'lime', 16: 'pink', 17: 'pink' }
  return colors[job] || 'gray'
}

const getRarityColor = (rarity) => ({ 0: 'gray', 1: 'blue', 2: 'green', 3: 'orange', 4: 'red', 5: 'purple' })[rarity] || 'gray'
const getRarityColorHex = (rarity) => ({ 0: '#888', 1: '#1890ff', 2: '#52c41a', 3: '#fa8c16', 4: '#f5222d', 5: '#722ed1' })[rarity] || '#333'
const getRarityName = (rarity) => ({ 0: '普通', 1: '高级', 2: '稀有', 3: '神器', 4: '传说', 5: '史诗' })[rarity] || '品质' + rarity
const getCategoryColor = (category) => ({ '裝備': 'blue', '消耗品': 'green', '材料': 'orange', '副職業': 'cyan', '任務': 'purple' })[category] || 'gray'

const search = async (resetPage = false) => {
  if (resetPage) pageNum.value = 1
  loading.value = true
  try {
    let url = '/characters/search?page=' + pageNum.value + '&page_size=' + pageSize.value
    if (searchForm.value.name) url += '&q=' + searchForm.value.name
    if (searchForm.value.account) url += '&account=' + searchForm.value.account
    if (searchForm.value.job !== '' && searchForm.value.job !== undefined) url += '&job=' + searchForm.value.job
    if (searchForm.value.minLev) url += '&minLev=' + searchForm.value.minLev
    if (searchForm.value.maxLev) url += '&maxLevel=' + searchForm.value.maxLev
    const res = await api.get(url)
    characters.value = (res.data.data || []).map(c => ({ ...c, c_name: decodeUnicode(c.c_name) }))
    total.value = res.data.total || 0
  } catch (e) { Message.error('搜索失败: ' + (e.response?.data?.error || e.message)) }
  finally { loading.value = false }
}

const onPageChange = (page) => { pageNum.value = page; search() }
const onPageSizeChange = (size) => { pageSize.value = size; pageNum.value = 1; search() }
const viewDetail = (record) => { detail.value = record; detailVisible.value = true }

const viewEquipment = async (record) => {
  equipmentVisible.value = true
  equipmentLoading.value = true
  try {
    const res = await api.get('/characters/' + record.c_no + '/equipment')
    equipment.value = (res.data || []).map(item => ({ ...item, item_name: decodeUnicode(item.item_name), slot_name: decodeUnicode(item.slot_name) }))
  } catch (e) { console.error('Failed to load equipment:', e); equipment.value = [] }
  finally { equipmentLoading.value = false }
}

const viewInventory = async (record) => {
  inventoryVisible.value = true
  inventoryLoading.value = true
  inventoryTab.value = 'all'
  try {
    const res = await api.get('/characters/' + record.c_no + '/items')
    inventory.value = (res.data || []).map(item => ({ ...item, item_name: decodeUnicode(item.item_name) }))
  } catch (e) { console.error('Failed to load inventory:', e); inventory.value = [] }
  finally { inventoryLoading.value = false }
}

const editCharacter = (record) => { editForm.value = { ...record }; editVisible.value = true }

const confirmEdit = async () => {
  try {
    await api.put('/charac', { c_no: editForm.value.c_no, c_level: editForm.value.c_level, max_hp: editForm.value.max_hp, max_mp: editForm.value.max_mp, phy_attack: editForm.value.phy_attack, phy_defense: editForm.value.phy_defense, mag_attack: editForm.value.mag_attack, mag_defense: editForm.value.mag_defense, move_speed: editForm.value.move_speed, c_fatigue: editForm.value.c_fatigue })
    Message.success('角色更新成功')
    editVisible.value = false
    search()
  } catch (e) { Message.error('更新失败: ' + (e.response?.data?.error || e.message)) }
}

onMounted(() => { search() })
</script>

<style scoped>
.characters-page { padding: 16px; }
.stat-tag { display: inline-block; padding: 1px 6px; margin: 2px 4px 2px 0; border-radius: 3px; font-size: 12px; line-height: 18px; }
.stat-tag.atk { background: #fff1f0; color: #cf1322; }
.stat-tag.def { background: #f6ffed; color: #389e0d; }
.stat-tag.stat { background: #e6f7ff; color: #096dd9; }
.stat-tag.crit { background: #fff7e6; color: #d46b08; }
</style>
