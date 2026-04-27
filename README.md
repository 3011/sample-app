# 示例应用源代码目录
# 复制此目录内容到你的应用代码仓库

此目录包含一个完整的 CI/CD 示例，展示如何：

1. 构建 Docker 镜像
2. 推送到内部 Registry (10.10.0.1:30500)
3. 更新 Config 仓库中的 manifest
4. ArgoCD 自动同步部署

## 使用步骤

### 1. 创建应用代码仓库

```bash
# 在 GitHub 创建新仓库，如：https://github.com/3011/sample-app

# 克隆仓库
git clone https://github.com/3011/sample-app.git
cd sample-app

# 复制示例文件
cp -r /root/config-git/apps-src/sample-app/* .

# 提交
git add .
git commit -m "Initial app with CI pipeline"
git push origin main
```

### 2. 在 Jenkins 中创建 Pipeline Job

```bash
# 方法一：通过 UI
1. 登录 Jenkins: http://jenkins-0886cf5f.nip.io
2. New Item → 输入名称 "sample-app-build"
3. 选择 "Pipeline"
4. Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/3011/sample-app.git
   - Credentials: (选择 GitHub 凭证)
   - Branch: main
   - Script Path: Jenkinsfile
5. Save

# 方法二：通过 Job DSL（见 job-dsl.groovy）
```

### 3. 配置 GitHub Webhook（自动触发）

```bash
# 在应用代码仓库设置 Webhook
1. GitHub → Settings → Webhooks → Add webhook
2. Payload URL: http://jenkins-0886cf5f.nip.io/github-webhook/
3. Content type: application/json
4. 选择: Push events
5. Add webhook
```

### 4. 触发构建

```bash
# 手动触发
Jenkins UI → sample-app-build → Build Now

# 或自动触发（配置 webhook 后）
git push 到应用仓库 → Jenkins 自动构建
```

## 流程图

```
应用仓库                Jenkins                Config仓库           ArgoCD
   │                      │                       │                   │
   │ git push             │                       │                   │
   ├─────────────────────▶│                       │                   │
   │                      │ 构建镜像              │                   │
   │                      │ 推送到 Registry       │                   │
   │                      │                       │                   │
   │                      │ 更新 manifest         │                   │
   │                      ├──────────────────────▶│                   │
   │                      │                       │ git push          │
   │                      │                       ├──────────────────▶│
   │                      │                       │                   │ 自动同步
   │                      │                       │                   │ 部署到K8s
```

## 需要的凭证

| 凭证 ID | 类型 | 用途 |
|---------|------|------|
| `github-ssh-key` | SSH Private Key | 推送 manifest 到 config 仓库 |
| `github-token` | Username/Password | 拉取应用代码（私有仓库） |

## 自定义

修改 Jenkinsfile 中的环境变量：

```groovy
environment {
    REGISTRY = '10.10.0.1:30500'      // 你的 Registry 地址
    IMAGE_NAME = 'your-app-name'       // 你的镜像名称
    CONFIG_REPO = 'git@github.com:xxx/config.git'  // 你的 config 仓库
    MANIFEST_PATH = 'home-k3s/apps/your-app/deployment.yaml'
}
```