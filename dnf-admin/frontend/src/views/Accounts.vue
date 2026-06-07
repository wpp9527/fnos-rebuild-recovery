<template>
  <div class="account-manager">
    <a-card>
      <a-form layout="inline" :model="searchForm">
        <a-form-item label="账号">
          <a-input placeholder="搜索玩家账号" allow-clear v-model="searchForm.account" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" @click="search(true)">搜索</a-button>
        </a-form-item>
      </a-form>
    </a-card>

    <a-table
      scrollbar
      :scroll="{ y: windowHeight }"
      style="margin-top: 10px;"
      :data="pageResult.list"
      :loading="loading"
      :pagination="false"
    >
      <template #empty>
        <div style="text-align: center; padding: 20px;">暂无数据</div>
      </template>
      <template #columns>
        <a-table-column title="UID" data-index="uid" :width="80" />
        <a-table-column title="账号" data-index="uname" />
        <a-table-column title="等级" data-index="level" :width="80">
          <template #cell="{ record }">
            <a-tag :color="record.level > 0 ? 'green' : 'blue'">
              {{ record.level > 0 ? 'GM' : '玩家' }}
            </a-tag>
          </template>
        </a-table-column>
        <a-table-column title="点券" data-index="cera" :width="100">
          <template #cell="{ record }">
            {{ record.cera?.toLocaleString() || 0 }}
          </template>
        </a-table-column>
        <a-table-column title="代币券" data-index="cera_point" :width="100">
          <template #cell="{ record }">
            {{ record.cera_point?.toLocaleString() || 0 }}
          </template>
        </a-table-column>
        <a-table-column title="操作" :width="180">
          <template #cell="{ record }">
            <a-space>
              <a-button size="small" type="primary" @click="viewCharacters(record.uid, record.uname)">角色</a-button>
              <a-button size="small" status="success" @click="openRecharge(record.uid, record.uname)">充值</a-button>
            </a-space>
          </template>
        </a-table-column>
      </template>
    </a-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 12px;">
      <a-pagination
        :current="searchForm.pageNum"
        :page-size="searchForm.pageSize"
        :total="pageResult.totalSize"
        show-total
        show-jumper
        show-page-size
        :page-size-options="[10, 20, 50, 100]"
        @change="onPageChange"
        @page-size-change="onPageSizeChange"
      />
    </div>

    <!-- 角色列表弹窗 -->
    <a-modal v-model:visible="charDialog.visible" :title="`${charDialog.accountname} 的角色`" :width="900" :footer="false">
      <a-table :data="charDialog.characters" :loading="charDialog.loading" :pagination="false" size="small">
        <template #columns>
          <a-table-column title="ID" data-index="c_no" :width="80" />
          <a-table-column title="昵称" data-index="c_name" />
          <a-table-column title="等级" data-index="c_level" :width="80" />
          <a-table-column title="职业" data-index="c_job" :width="120">
            <template #cell="{ record }">{{ getJobName(record.c_job) }}</template>
          </a-table-column>
          <a-table-column title="疲劳" data-index="c_fatigue" :width="80" />
          <a-table-column title="最后登录" data-index="c_last_login" />
        </template>
      </a-table>
    </a-modal>

    <!-- 充值弹窗 -->
    <a-modal v-model:visible="rechargeOption.open" :title="`为 ${rechargeOption.accountname} 充值`" @ok="submitRecharge">
      <a-form :model="rechargeOption" layout="vertical">
        <a-form-item label="当前点券">
          <a-input :model-value="String(rechargeOption.thisCera)" disabled />
        </a-form-item>
        <a-form-item label="充值数额">
          <a-input-number v-model="rechargeOption.cera" :min="1" :max="9999999" style="width: 100%" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { onMounted, ref, reactive } from 'vue'
import { Message } from '@arco-design/web-vue'
import Request from '../api'

const loading = ref(false)
const searchForm = reactive({ account: '', pageNum: 1, pageSize: 20 })
const pageResult = ref({ page: 1, totalPageSize: 20, totalSize: 0, list: [] })
const windowHeight = ref(window.innerHeight - 300)

const charDialog = reactive({ visible: false, loading: false, accountname: '', characters: [] })
const rechargeOption = reactive({ uid: 0, accountname: '', open: false, cera: 0, thisCera: 0 })

const jobNames = {
  0: '鬼剑士', 1: '格斗家', 2: '神枪手', 3: '魔法师', 4: '圣职者',
  5: '暗夜使者', 6: '魔枪士', 7: '枪剑士', 8: '弓箭手',
  100: '剑魂', 101: '狂战士', 102: '阿修罗', 103: '鬼泣',
  200: '气功师', 201: '散打', 202: '街霸', 203: '柔道家',
  300: '漫游枪手', 301: '枪炮师', 302: '机械师', 303: '弹药专家',
  400: '元素师', 401: '召唤师', 402: '战斗法师', 403: '魔道学者',
  500: '圣骑士', 501: '蓝拳圣使', 502: '驱魔师', 503: '复仇者',
  600: '刺客', 601: '死灵术士', 602: '忍者', 603: '影舞者',
  700: '征战者', 701: '决战者', 702: '狩猎者', 703: '暗枪士',
  800: '特工', 801: '战线佣兵', 802: '杀手', 803: '专家'
}
const getJobName = (job) => jobNames[job] || `职业${job}`

const search = (resetPage = false) => {
  if (resetPage) searchForm.pageNum = 1
  loading.value = true
  let url = `/accounts/search?q=${searchForm.account}&page=${searchForm.pageNum}&page_size=${searchForm.pageSize}`
  Request.get(url).then(res => {
    pageResult.value.list = res.data.data || []
    pageResult.value.totalSize = res.data.total || 0
  }).catch(e => Message.error(e?.message || '查询失败')).finally(() => loading.value = false)
}

const onPageChange = (page) => { searchForm.pageNum = page; search(false) }
const onPageSizeChange = (pageSize) => { searchForm.pageSize = pageSize; search(true) }

const viewCharacters = async (uid, accountname) => {
  charDialog.visible = true
  charDialog.loading = true
  charDialog.accountname = accountname
  try {
    const res = await Request.get(`/accounts/${uid}/characters`)
    charDialog.characters = res.data || []
  } catch { charDialog.characters = [] }
  finally { charDialog.loading = false }
}

const openRecharge = async (uid, accountname) => {
  rechargeOption.uid = uid
  rechargeOption.accountname = accountname
  rechargeOption.cera = 0
  rechargeOption.thisCera = 0
  rechargeOption.open = true
  try {
    const res = await Request.get(`/account/${uid}`)
    rechargeOption.thisCera = Number(res.data?.cera ?? 0)
  } catch {}
}

const submitRecharge = async () => {
  if (!rechargeOption.uid || rechargeOption.cera <= 0) return
  try {
    await Request.post('/gm/cera', { character_name: rechargeOption.accountname, amount: rechargeOption.cera })
    Message.success('充值成功')
    rechargeOption.open = false
    search(false)
  } catch (e) { Message.error(e?.message || '充值失败') }
}

onMounted(() => {
  window.addEventListener('resize', () => { windowHeight.value = window.innerHeight - 300 })
  search()
})
</script>

<style scoped>
.account-manager { padding: 10px; }
</style>
