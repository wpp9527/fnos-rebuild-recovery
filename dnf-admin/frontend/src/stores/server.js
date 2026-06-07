import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api'

export const useServerStore = defineStore('server', () => {
  const servers = ref([])
  const currentServerId = ref(localStorage.getItem('current_server_id') || '')
  const loading = ref(false)

  const currentServer = computed(() =>
    servers.value.find(s => s.id === currentServerId.value) || null
  )

  async function fetchServers() {
    loading.value = true
    try {
      const res = await api.get('/servers')
      servers.value = res.data.servers || res.data || []
      // 如果当前没有选中或选中的不存在，自动选第一个
      if (servers.value.length > 0) {
        const exists = servers.value.some(s => s.id === currentServerId.value)
        if (!exists) {
          setCurrentServer(servers.value[0].id)
        }
      }
    } catch (e) {
      console.error('获取区服列表失败:', e)
    } finally {
      loading.value = false
    }
  }

  function setCurrentServer(id) {
    currentServerId.value = id
    localStorage.setItem('current_server_id', id)
  }

  // 给 API 请求用的 query 参数
  const serverParam = computed(() => {
    return currentServerId.value ? { server_id: currentServerId.value } : {}
  })

  return {
    servers,
    currentServerId,
    currentServer,
    loading,
    fetchServers,
    setCurrentServer,
    serverParam
  }
})
