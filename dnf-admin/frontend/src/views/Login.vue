<template>
  <div class="login-page">
    <div class="login-box">
      <div class="login-box-header">
        <h1>DNF Admin</h1>
        <p>游戏管理后台</p>
      </div>
      <div class="login-box-body">
        <a-form layout="vertical" :model="form" @submit-success="handleLogin">
          <a-form-item field="username" :rules="[{ required: true, message: '请输入用户名' }]" hide-label>
            <a-input v-model="form.username" placeholder="请输入用户名" allow-clear size="large">
              <template #prefix><icon-user /></template>
            </a-input>
          </a-form-item>
          <a-form-item field="password" :rules="[{ required: true, message: '请输入密码' }]" hide-label>
            <a-input-password v-model="form.password" placeholder="请输入密码" allow-clear size="large" @keyup.enter="handleLogin">
              <template #prefix><icon-lock /></template>
            </a-input-password>
          </a-form-item>
          <a-form-item hide-label>
            <a-button type="primary" long size="large" :loading="loading" @click="handleLogin">
              登 录
            </a-button>
          </a-form-item>
        </a-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Message } from '@arco-design/web-vue'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)

const form = reactive({
  username: '',
  password: ''
})

const handleLogin = async () => {
  if (!form.username || !form.password) {
    Message.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    const success = await authStore.login(form.username, form.password)
    if (success) {
      Message.success('登录成功')
      router.push('/')
    } else {
      Message.error('用户名或密码错误')
    }
  } catch (error) {
    Message.error('登录失败: ' + (error.response?.data?.error || error.message))
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.login-box {
  width: 380px;
  padding: 40px;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
  backdrop-filter: blur(10px);
}
.login-box-header {
  text-align: center;
  margin-bottom: 30px;
}
.login-box-header h1 {
  margin: 0 0 8px 0;
  font-size: 32px;
  font-weight: 700;
  color: #1d2129;
}
.login-box-header p {
  margin: 0;
  color: #86909c;
  font-size: 14px;
}
</style>
