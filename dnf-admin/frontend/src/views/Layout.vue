<template>
  <div class="layout-page">
    <a-layout class="layout-container">
      <a-layout-sider :collapsed="collapsed" collapsible :trigger="null" theme="dark" class="layout-sider">
        <div class="logo">
          <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Ccircle cx='16' cy='16' r='14' fill='%23165DFF'/%3E%3Ctext x='16' y='22' font-size='16' fill='white' text-anchor='middle' font-weight='bold'%3ED%3C/text%3E%3C/svg%3E" alt="Logo" />
          <span v-if="!collapsed" class="logo-text">DNF Admin</span>
        </div>
        <a-menu
          :selected-keys="selectedKeys"
          theme="dark"
          @menu-item-click="handleMenuClick"
        >
          <a-menu-item key="/">
            <template #icon><icon-dashboard /></template>
            仪表盘
          </a-menu-item>
          <a-sub-menu key="player">
            <template #icon><icon-user /></template>
            <template #title>玩家管理</template>
            <a-menu-item key="/accounts">账号管理</a-menu-item>
            <a-menu-item key="/characters">角色管理</a-menu-item>
          </a-sub-menu>
          <a-menu-item key="/gm">
            <template #icon><icon-settings /></template>
            GM 工具
          </a-menu-item>
          <a-menu-item key="/postal">
            <template #icon><icon-email /></template>
            GM 邮件
          </a-menu-item>
          <a-menu-item key="/punish">
            <template #icon><icon-stop /></template>
            惩罚管理
          </a-menu-item>
          <a-menu-item key="/guilds">
            <template #icon><icon-user-group /></template>
            公会管理
          </a-menu-item>
          <a-menu-item key="/stats">
            <template #icon><icon-bar-chart /></template>
            数据统计
          </a-menu-item>
          <a-menu-item key="/pvf">
            <template #icon><icon-search /></template>
            PVF 搜索
          </a-menu-item>
          <a-menu-item key="/activities">
            <template #icon><icon-calendar /></template>
            活动管理
          </a-menu-item>
          <a-menu-item key="/pve">
            <template #icon><icon-monitor /></template>
            PVE 管理
          </a-menu-item>
          <a-menu-item key="/audit">
            <template #icon><icon-file /></template>
            审计日志
          </a-menu-item>
        </a-menu>
      </a-layout-sider>
      <a-layout class="layout-right">
        <a-layout-header class="layout-header">
          <div class="header-left">
            <div class="toggle-button" @click="collapsed = !collapsed">
              <icon-menu-fold v-if="collapsed" />
              <icon-menu-unfold v-else />
            </div>
            <a-breadcrumb style="margin-left: 16px">
              <a-breadcrumb-item>首页</a-breadcrumb-item>
              <a-breadcrumb-item v-if="currentRouteName">{{ currentRouteName }}</a-breadcrumb-item>
            </a-breadcrumb>
          </div>
          <div class="header-right">
            <a-select
              v-model="serverStore.currentServerId"
              placeholder="选择区服"
              style="width: 180px"
              @change="handleServerChange"
            >
              <a-option v-for="s in serverStore.servers" :key="s.id" :label="s.name" :value="s.id" />
            </a-select>
            <a-dropdown trigger="hover">
              <div class="user-info">
                <a-avatar :size="32" style="background-color: #165DFF">
                  {{ authStore.username?.[0]?.toUpperCase() || 'A' }}
                </a-avatar>
                <span class="username">{{ authStore.username || 'Admin' }}</span>
              </div>
              <template #content>
                <a-doption @click="handleLogout">
                  <icon-poweroff style="margin-right: 8px" />退出登录
                </a-doption>
              </template>
            </a-dropdown>
          </div>
        </a-layout-header>
        <a-layout-content class="layout-content">
          <a-scrollbar style="height: 100%">
            <router-view />
          </a-scrollbar>
        </a-layout-content>
      </a-layout>
    </a-layout>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useServerStore } from '../stores/server'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const serverStore = useServerStore()
const collapsed = ref(false)

const selectedKeys = computed(() => [route.path])

const routeNames = {
  '/': '仪表盘',
  '/accounts': '账号管理',
  '/characters': '角色管理',
  '/gm': 'GM 工具',
  '/pvf': 'PVF 搜索',
  '/activities': '活动管理',
  '/pve': 'PVE 管理',
  '/audit': '审计日志'
}
const currentRouteName = computed(() => routeNames[route.path] || '')

const handleMenuClick = (key) => {
  if (key.startsWith('/')) {
    router.push(key)
  }
}

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const handleServerChange = (id) => {
  serverStore.setCurrentServer(id)
}

onMounted(() => {
  serverStore.fetchServers()
})
</script>

<style scoped>
.layout-page {
  height: 100vh;
}
.layout-container {
  height: 100%;
}
.layout-sider {
  background: #1d2129;
}
.logo {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 64px;
  gap: 8px;
}
.logo img {
  width: 32px;
  height: 32px;
}
.logo-text {
  color: #fff;
  font-size: 18px;
  font-weight: 700;
  white-space: nowrap;
}
.layout-right {
  height: 100%;
}
.layout-header {
  background: #1d2129;
  padding: 0 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 55px;
}
.header-left {
  display: flex;
  align-items: center;
}
.toggle-button {
  font-size: 20px;
  cursor: pointer;
  color: #fff;
}
.toggle-button:hover {
  color: #165DFF;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}
.username {
  color: #fff;
  font-size: 14px;
}
.layout-content {
  background: #f2f3f5;
  padding: 16px;
}
</style>
