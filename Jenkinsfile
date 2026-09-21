pipeline {
    agent any
    parameters {
        string(
            name: 'BRANCH',
            defaultValue: 'origin/main',
            description: '手动构建时选择要构建的分支 origin/xxx，Gitlab MR触发会自动覆盖此变量'
        )
    }
    environment {
        TARGET_BRANCH = sh(
            script: """
                if test -n "\${gitlabTargetBranch}"; then
                    echo "origin/\${gitlabTargetBranch}"
                else
                    echo "${params.BRANCH}"
                fi
            """,
            returnStdout: true
        ).trim()

        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        BRANCH_NAME = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
        BRANCH_NAME_SAFE = sh(script: """
            if test -n "\${gitlabTargetBranch}"; then
                echo "\${gitlabTargetBranch}" | tr / _ | tr "[:upper:]" "[:lower:]"
            else
                # params.BRANCH是 origin/test_msgs，去掉origin/
                echo "${params.BRANCH}" | sed 's#^origin/##' | tr / _ | tr "[:upper:]" "[:lower:]"
            fi
        """, returnStdout: true).trim()
        SONAR_TOKEN = credentials('jenkins-sonar')
        ANTHROPIC_BASE_URL = "http://146.56.245.198:4000"
        ANTHROPIC_MODEL = "MiniMax-M2.7"
        SCORE_THRESHOLD = 70
        ANTHROPIC_API_KEY = "dummy-key"
    }
    stages {
        stage('AI Code Review - MR Diff') {
            when {

                expression { env.gitlabTargetBranch != null && env.gitlabTargetBranch.trim() != '' }
            }
            steps {
                sh '''
                #!/bin/sh
                set -e

                # 拉取目标分支
                git fetch origin ${gitlabTargetBranch}
                # 获取MR对比diff，限制长度
                MR_DIFF=$(git diff origin/${gitlabTargetBranch}...HEAD | head -c 80000)

                SYSTEM_PROMPT=$(cat <<'EOF'
                你是资深ROS2 C++工业代码评审专家。
                分析下面git MR代码diff，输出严格JSON，禁止任何前言、解释、markdown。
                JSON结构固定：
                {
                "score": 0~100整数,
                "risk_level": "高/中/低",
                "problems": ["问题1","问题2"],
                "suggestions": ["建议1"]
                }
                评分重点检查：内存泄漏、裸指针、多线程竞态、ROS回调阻塞、资源未释放、魔法数字、硬编码、异常处理。
                EOF
                )

                USER_CONTENT=$(cat <<EOF
                下面是本次MR代码diff内容：
                ${MR_DIFF}
                EOF
                )

                RESP=$(curl -s --connect-timeout 10 "${ANTHROPIC_BASE_URL}/v1/messages" \
                -H "Content-Type: application/json" \
                -H "x-api-key: ${ANTHROPIC_API_KEY}" \
                -d '{
                "model": "'"${ANTHROPIC_MODEL}"'",
                "max_tokens": 1200,
                "system": "'"${SYSTEM_PROMPT}"'",
                "messages": [
                {"role":"user","content":"'"${USER_CONTENT}"'"}
                ]
                }')

                echo "==== Gateway Raw Response ===="
                echo "${RESP}"
                echo "${RESP}" > ai_code_review.json
                '''
                script {
                    def aiRaw = readJSON file: 'ai_code_review.json'
                    String llmOutput = aiRaw.content[0].text.trim()
                    echo "🤖 LLM原始输出文本：${llmOutput}"

                    def aiResult = new groovy.json.JsonSlurper().parseText(llmOutput)
                    int score = aiResult.score
                    def risk = aiResult.risk_level
                    def problems = aiResult.problems
                    def suggestions = aiResult.suggestions

                    echo "==================== AI代码评审结果 ===================="
                    echo "MR代码质量得分：${score}/100"
                    echo "风险等级：${risk}"
                    echo "问题列表：${problems}"
                    echo "优化建议：${suggestions}"
                    echo "========================================================"

                    if (score < env.SCORE_THRESHOLD.toInteger()) {
                        error "❌ AI代码评审不通过！得分${score}，阈值${env.SCORE_THRESHOLD}，流水线终止。"
                    }
                }
            }
        }

        stage('构建镜像并编译message产物') {
            steps {
                sh """
                #!/bin/bash
                set -e
                # 镜像命名：message-common + 安全分支名 + :latest
                IMAGE_NAME="message-common-${BRANCH_NAME_SAFE}:latest"
                
                docker build -f ci/Dockerfile_msgs -t \${IMAGE_NAME} .
                
                echo "✅ 镜像构建完成：\${IMAGE_NAME}"
                docker images | grep message-common
                """
            }
        }

        stage('SonarQube 代码扫描') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    sonar-scanner \
                        -Dsonar.projectKey=my-project \
                        -Dsonar.projectName=ROS2-Msg-Package \
                        -Dsonar.projectVersion=${GIT_COMMIT_SHORT} \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=build/**,install/**,Package/**,**/*.md,**/*.swp \
                        -Dsonar.host.url=http://10.233.88.16:9000 \
                        -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('本地镜像清理') {
            steps {
                sh """
                docker image prune -f
                """
            }
        }
    }
    post {
        always {
            
            sh 'docker rm -f msg_build_7 || true'
            archiveArtifacts artifacts: 'ai_code_review.json', fingerprint: true, allowEmptyArchive: true
        }
        success {
            echo "✅ 流水线全部执行成功！产物已经打包进镜像 message-with-msg-artifact:${GIT_COMMIT_SHORT}"
        }
        failure {
            echo "❌ 流水线执行失败，请查看AI代码评审结果"
        }
    }
}
