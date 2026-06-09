<template>
  <div class="guilds-page">
    <a-card :bordered="false">
      <a-row :gutter="16" style="margin-bottom: 16px">
        <a-col :span="6">
          <a-statistic title="公会总数" :value="stats.totalGuilds" />
        </a-col>
      </a-row>
    </a-card>

    <a-table :data="guilds" :loading="loading" :pagination="false" style="margin-top: 16px">
      <template #columns>
        <a-table-column title="公会ID" data-index="guild_id" :width="80" />
        <a-table-column title="公会名称" data-index="guild_name" :width="200">
          <template #cell="{ record }">
            <span style="font-weight: bold">{{ decodeUnicode(record.guild_name) }}</span>
          </template>
        </a-table-column>
        <a-table-column title="等级" data-index="level" :width="70">
          <template #cell="{ record }">
            <a-tag color="orange">Lv.{{ record.level }}</a-tag>
          </template>
        </a-table-column>
        <a-table-column title="成员数" data-index="member_count" :width="80" />
        <a-table-column title="会长" :width="150">
          <template #cell="{ record }">{{ decodeUnicode(record.master_name) || '-' }}</template>
        </a-table-column>
        <a-table-column title="操作" :width="120">
          <template #cell="{ record }">
            <a-button type="text" size="small" @click="viewMembers(record)">查看成员</a-button>
          </template>
        </a-table-column>
      </template>
    </a-table>

    <!-- 公会成员弹窗 -->
    <a-modal v-model:visible="membersVisible" :title="'公会成员 - ' + currentGuild" :width="700" :footer="false">
      <a-spin :loading="membersLoading" style="width: 100%">
        <a-table :data="members" :pagination="false" size="small">
          <template #columns>
            <a-table-column title="角色名" :width="150">
              <template #cell="{ record }">{{ decodeUnicode(record.charac_name) }}</template>
            </a-table-column>
            <a-table-column title="等级" data-index="level" :width="70" />
            <a-table-column title="职业" :width="120">
              <template #cell="{ record }">{{ getJobName(record.job) }}</template>
            </a-table-column>
            <a-table-column title="职位" :width="100">
              <template #cell="{ record }">
                <a-tag :color="record.position === 0 ? 'gold' : 'blue'">{{ record.position === 0 ? '会长' : '成员' }}</a-tag>
              </template>
            </a-table-column>
          </template>
        </a-table>
      </a-spin>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Message } from '@arco-design/web-vue'
import api from '../api'

const guilds = ref([])
const loading = ref(false)
const stats = ref({ totalGuilds: 0 })
const membersVisible = ref(false)
const membersLoading = ref(false)
const members = ref([])
const currentGuild = ref('')

const decodeUnicode = (str) => {
  if (!str) return str
  return str.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

const getJobName = (job) => {
  const baseJobs = { 0: '鬼剑士', 2: '格斗家', 4: '神枪手', 6: '魔法师', 8: '圣职者', 10: '暗夜使者', 12: '魔枪士', 14: '枪剑士', 16: '弓箭手' }
  const isFemale = job % 2 === 1
  const baseIndex = Math.floor(job / 2) * 2
  return (baseJobs[baseIndex] || '职业' + job) + (isFemale ? '(女)' : '(男)')
}

const loadData = async () => {
  loading.value = true
  try {
    const [guildRes, statRes] = await Promise.all([
      api.get('/guilds'),
      api.get('/stats/online')
    ])
    guilds.value = guildRes.data || []
    stats.value = { totalGuilds: statRes.data?.total_guilds || 0 }
  } catch (e) {
    Message.error('加载失败: ' + (e.response?.data?.error || e.message))
  } finally { loading.value = false }
}

const viewMembers = async (guild) => {
  membersVisible.value = true
  membersLoading.value = true
  currentGuild.value = decodeUnicode(guild.guild_name)
  try {
    const res = await api.get('/guilds/' + guild.guild_id + '/members')
    members.value = res.data || []
  } catch (e) {
    members.value = []
    Message.error('获取成员失败: ' + (e.response?.data?.error || e.message))
  } finally { membersLoading.value = false }
}

onMounted(() => { loadData() })
</script>

<style scoped>
.guilds-page { padding: 16px; }
</style>
