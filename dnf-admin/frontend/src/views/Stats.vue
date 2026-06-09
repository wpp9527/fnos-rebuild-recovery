<template>
  <div class="stats-page">
    <a-row :gutter="16" style="margin-bottom: 16px">
      <a-col :span="6">
        <a-card :bordered="false">
          <a-statistic title="总角色数" :value="onlineStat.total_chars" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card :bordered="false">
          <a-statistic title="在线角色" :value="onlineStat.online_chars" :value-style="{ color: '#00b42a' }" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card :bordered="false">
          <a-statistic title="公会总数" :value="onlineStat.total_guilds" />
        </a-card>
      </a-col>
      <a-col :span="6">
        <a-card :bordered="false">
          <a-statistic title="在线率" :value="onlineStat.total_chars ? ((onlineStat.online_chars / onlineStat.total_chars) * 100).toFixed(1) : 0" suffix="%" />
        </a-card>
      </a-col>
    </a-row>

    <a-row :gutter="16">
      <a-col :span="12">
        <a-card title="PVP 排行榜" :bordered="false">
          <a-table :data="pvpRankings" :loading="pvpLoading" :pagination="false" size="small">
            <template #columns>
              <a-table-column title="排名" :width="60">
                <template #cell="{ rowIndex }">
                  <a-tag :color="rowIndex < 3 ? 'gold' : 'blue'">{{ rowIndex + 1 }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="角色名" :width="150">
                <template #cell="{ record }">{{ decodeUnicode(record.charac_name) }}</template>
              </a-table-column>
              <a-table-column title="等级" data-index="c_level" :width="60" />
              <a-table-column title="PVP等级" :width="80">
                <template #cell="{ record }">
                  <a-tag color="orange">Grade {{ record.pvp_grade }}</a-tag>
                </template>
              </a-table-column>
              <a-table-column title="PVP积分" data-index="pvp_point" :width="80" />
              <a-table-column title="胜率" :width="80">
                <template #cell="{ record }">
                  <span :style="{ color: record.win_rate >= 50 ? '#00b42a' : '#f53f3f' }">{{ record.win_rate?.toFixed(1) || 0 }}%</span>
                </template>
              </a-table-column>
            </template>
          </a-table>
        </a-card>
      </a-col>
      <a-col :span="12">
        <a-card title="副本统计" :bordered="false">
          <a-table :data="dungeonStats" :loading="dungeonLoading" :pagination="false" size="small">
            <template #columns>
              <a-table-column title="副本名" :width="200">
                <template #cell="{ record }">{{ decodeUnicode(record.dungeon_name) || '副本#' + record.dungeon_id }}</template>
              </a-table-column>
              <a-table-column title="通关次数" data-index="clear_count" :width="100" />
              <a-table-column title="最高评分" data-index="best_score" :width="80" />
              <a-table-column title="平均时间" :width="100">
                <template #cell="{ record }">{{ record.avg_time ? record.avg_time.toFixed(1) + 's' : '-' }}</template>
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

const onlineStat = ref({ total_chars: 0, online_chars: 0, total_guilds: 0 })
const pvpRankings = ref([])
const pvpLoading = ref(false)
const dungeonStats = ref([])
const dungeonLoading = ref(false)

const decodeUnicode = (str) => {
  if (!str) return str
  return str.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

const loadData = async () => {
  // 在线统计
  try {
    const res = await api.get('/stats/online')
    onlineStat.value = res.data || {}
  } catch (e) { console.error('Failed to load online stat:', e) }

  // PVP 排行
  pvpLoading.value = true
  try {
    const res = await api.get('/stats/pvp?limit=20')
    pvpRankings.value = res.data || []
  } catch (e) { console.error('Failed to load PVP rankings:', e) }
  finally { pvpLoading.value = false }

  // 副本统计
  dungeonLoading.value = true
  try {
    const res = await api.get('/stats/dungeon')
    dungeonStats.value = res.data || []
  } catch (e) { console.error('Failed to load dungeon stats:', e) }
  finally { dungeonLoading.value = false }
}

onMounted(() => { loadData() })
</script>

<style scoped>
.stats-page { padding: 16px; }
</style>
