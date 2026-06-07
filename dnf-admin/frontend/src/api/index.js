import axios from 'axios'
import { useServerStore } from '../stores/server'

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    // 自动附带 server_id
    try {
      const serverStore = useServerStore()
      if (serverStore.currentServerId) {
        if (config.method === 'get' || config.method === 'delete') {
          config.params = { ...config.params, server_id: serverStore.currentServerId }
        } else if (config.data && typeof config.data === 'object') {
          config.data = { ...config.data, server_id: serverStore.currentServerId }
        }
      }
    } catch (_) { /* store 未就绪时忽略 */ }
    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
