// Jenkins Pipeline - 示例应用构建流程
// 将此文件复制到你的应用代码仓库根目录

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    env:
    - name: HTTP_PROXY
      value: http://10.10.0.1:30800
    - name: HTTPS_PROXY
      value: http://10.10.0.1:30800
    - name: NO_PROXY
      value: localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc.cluster.local
  - name: docker
    image: docker:24-cli
    command: ['cat']
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://dind-test.dev.svc.cluster.local:2375
    - name: HTTP_PROXY
      value: http://10.10.0.1:30800
    - name: HTTPS_PROXY
      value: http://10.10.0.1:30800
    - name: NO_PROXY
      value: localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc.cluster.local
  - name: git
    image: alpine/git:latest
    command: ['cat']
    tty: true
    env:
    - name: HTTP_PROXY
      value: http://10.10.0.1:30800
    - name: HTTPS_PROXY
      value: http://10.10.0.1:30800
    - name: NO_PROXY
      value: localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc.cluster.local
'''
        }
    }

    environment {
        // 内部 Registry 地址
        REGISTRY = '10.10.0.1:30500'
        // 镜像名称
        IMAGE_NAME = 'sample-app'
        // Config 仓库地址（存放 K8s manifest）
        CONFIG_REPO = 'git@github.com:3011/config.git'
        // Config 仓库中 manifest 文件路径
        MANIFEST_PATH = 'home-k3s/apps/sample-app/sample-app.yaml'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Building commit: ${GIT_COMMIT}"'
            }
        }

        stage('Build Image') {
            steps {
                container('docker') {
                    sh '''
                        # 构建镜像
                        docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .

                        # 推送到内部 Registry
                        docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}

                        # 同时更新 latest 标签
                        docker tag ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:latest
                        docker push ${REGISTRY}/${IMAGE_NAME}:latest

                        echo "Image pushed: ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    '''
                }
            }
        }

        stage('Update Manifest') {
            steps {
                container('git') {
                    // 使用 SSH 密钥访问 config 仓库
                    withCredentials([sshUserPrivateKey(credentialsId: 'github-ssh-key',
                                                       keyFileVariable: 'SSH_KEY',
                                                       usernameVariable: 'GIT_USER')]) {
                        sh '''
                            # 配置 SSH 通过 HTTP 代理连接 GitHub
                            mkdir -p ~/.ssh
                            cat > ~/.ssh/config << EOF
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
    IdentityFile ${SSH_KEY}
    StrictHostKeyChecking no
    ProxyCommand nc -X connect -x 10.10.0.1:30800 %h %p
EOF
                            chmod 600 ~/.ssh/config

                            # 验证 SSH 连通性
                            ssh -T git@github.com 2>&1 || true

                            # 克隆 config 仓库
                            git clone ${CONFIG_REPO} /tmp/config-repo
                            cd /tmp/config-repo

                            # 更新镜像 Tag
                            # 格式: image: registry/image-name:tag
                            sed -i "s|image:.*${IMAGE_NAME}.*|image: ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}|g" ${MANIFEST_PATH}

                            # 显示变更
                            git diff

                            # 提交并推送
                            git config user.email "jenkins@ci.local"
                            git config user.name "Jenkins CI"
                            git add .
                            git commit -m "Update ${IMAGE_NAME} to build ${BUILD_NUMBER}" || echo "No changes to commit"
                            git push origin main

                            echo "Manifest updated! ArgoCD will auto-sync."
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ CI Pipeline completed!'
            echo 'ArgoCD will automatically sync and deploy the new version.'
        }
        failure {
            echo '❌ CI Pipeline failed!'
            echo 'Check the logs for details.'
        }
    }
}