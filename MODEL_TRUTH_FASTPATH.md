# MODEL TRUTH FASTPATH

当用户询问以下主题时：
- 现在配备了哪些模型
- 模型如何分配
- 主模型是什么
- 备用链是什么
- fallback 是什么
- provider 有哪些

必须优先读取以下真相文件再回答，不要先长篇推理：
- /opt/fnos-media/services/openclaw-governance/runtime/truth/current_model_inventory.md
- /opt/fnos-media/services/openclaw/home/.openclaw/openclaw.json

回答要求：
1. 直接给结论
2. 不输出思考过程
3. 不写“我来查看配置”
4. 控制在 8 行内
5. 先回答 primary，再回答 fallbacks，再回答 provider
