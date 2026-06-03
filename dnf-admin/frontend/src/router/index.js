import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('../views/Layout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue')
      },
      {
        path: 'accounts',
        name: 'Accounts',
        component: () => import('../views/Accounts.vue')
      },
      {
        path: 'characters',
        name: 'Characters',
        component: () => import('../views/Characters.vue')
      },
      {
        path: 'gm',
        name: 'GM',
        component: () => import('../views/GM.vue')
      },
      {
        path: 'pvf',
        name: 'PVF',
        component: () => import('../views/PVF.vue')
      },
      {
        path: 'activities',
        name: 'Activities',
        component: () => import('../views/Activities.vue')
      },
      {
        path: 'pve',
        name: 'PVE',
        component: () => import('../views/PVE.vue')
      },
      {
        path: 'audit',
        name: 'Audit',
        component: () => import('../views/Audit.vue')
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth !== false && !authStore.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
