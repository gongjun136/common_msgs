pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    parameters {
        gitParameter(
            name: 'REF_NAME',
            type: 'PT_BRANCH_TAG',
            branchFilter: 'origin/(.*)',
            defaultValue: 'release/v1.0.0',
            description: '选择要构建的分支或标签',
            quickFilterEnabled: true,
            sortMode: 'DESCENDING_SMART'
        )
        booleanParam(
            name: 'CLEAN_BUILD',
            defaultValue: false,
            description: '勾选则全量清理后重新编译（默认增量编译）'
        )
    }

    environment {
        PROJECT_NAME = 'message-common'
        BASE_IMAGE   = 'wheel_loader_release:latest'
        WS_DIR       = '/home/sany/work/wheel_loader'
        SAFE_REF     = "${params.REF_NAME}".replaceAll('/', '_')
        IMAGE_NAME   = "message-common-${SAFE_REF}:latest"
        SONAR_TOKEN  = credentials('jenkins-sonar')
        // AI 代码审查配置
        ANTHROPIC_BASE_URL = "https://tokenhub.tencentmaas.com"
        ANTHROPIC_MODEL    = "glm-5.2"
        SCORE_THRESHOLD    = 70
        ANTHROPIC_API_KEY  = credentials('sany-api-key')
    }

    stages {

        stage('Prepare') {
            steps {
                echo "==== 1. 拉取代码 (${PROJECT_NAME}, 分支: ${params.REF_NAME}) ===="
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${params.REF_NAME}"]],
                    extensions: scm.extensions + [[
                        $class: 'SubmoduleOption',
                        recursiveSubmodules: true,
                        parentCredentials: true,
                        trackingSubmodules: false
                    ]],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])

                sh '''
                    set -e
                    echo "当前 commit: $(git rev-parse HEAD)"
                    if [ ! -f "/var/lib/jenkins/workspace/setting.sh" ]; then
                        echo "[ERROR] 未找到 setting.sh"
                        exit 1
                    fi
                    echo "setting.sh 校验通过"
                '''
            }
        }

        stage('AI Code Review - MR Diff') {
            when {
                expression {
                    (env.gitlabTargetBranch != null && env.gitlabTargetBranch.trim() != '') ||
                    (env.BRANCH_NAME != null && env.BRANCH_NAME != 'main' && env.BRANCH_NAME != 'release/v1.0.0')
                }
            }
            steps {
                sh '''
                #!/bin/bash
                set -e
                set -o pipefail

                rm -f mr.diff ai_code_review.json

                # 确定目标分支
                if [ -n "$gitlabTargetBranch" ]; then
                    TARGET_BRANCH="$gitlabTargetBranch"
                else
                    TARGET_BRANCH="main"
                fi

                echo "==== TARGET_BRANCH: $TARGET_BRANCH ===="
                echo "==== 本次变更文件列表 ===="
                git diff origin/$TARGET_BRANCH...HEAD --name-only

                # 过滤diff：保留 .msg .idl .cpp .h .hpp .c 源码文件
                git diff origin/$TARGET_BRANCH...HEAD \
                    -- '*.msg' '*.idl' '*.cpp' '*.h' '*.hpp' '*.c' \
                    --exclude=build/** \
                    --exclude=install/** \
                    --exclude=Package/** \
                    --exclude=ci/** \
                    --exclude='*.md' \
                    --exclude='*.yaml' \
                    --exclude='*.yml' \
                    --exclude='*.json' \
                | head -c 80000 > mr.diff

                echo "==== 过滤后diff文件大小 ===="
                ls -lh mr.diff

                if [ ! -s mr.diff ]; then
                    echo ">>> 过滤后无源码变更，跳过AI代码评审"
                    echo '{"empty_diff":true}' > ai_code_review.json
                    exit 0
                fi

                echo "======= 送入AI评审diff预览 ======="
                cat mr.diff

                SYSTEM_PROMPT='你是资深ROS2 C++工业代码评审专家。
                分析下面git MR代码diff，输出严格JSON，禁止任何前言、解释、markdown。
                JSON结构固定：
                {
                "score": 0~100整数,
                "risk_level": "高/中/低",
                "problems": ["问题1","问题2"],
                "suggestions": ["建议1"]
                }
                评分重点检查：消息定义规范性、IDL一致性、命名规范、字段类型合理性、版本兼容性、是否有未使用的消息定义。
                直接输出JSON，禁止包含标签、思考过程、markdown代码块或任何解释文字。'

                RESP=$(jq -n \
                --arg sys_prompt "$SYSTEM_PROMPT" \
                --arg user_content "$(cat mr.diff)" \
                --arg model "$ANTHROPIC_MODEL" \
                '{
                    "model": $model,
                    "max_tokens": 2048,
                    "system": $sys_prompt,
                    "messages": [{"role":"user","content":$user_content}]
                }' | curl -s --connect-timeout 10 "$ANTHROPIC_BASE_URL/v1/messages" \
                -H "Content-Type: application/json" \
                -H "x-api-key: $ANTHROPIC_API_KEY" \
                -d @-)

                echo "==== Gateway Raw Response ===="
                echo "$RESP"
                echo "$RESP" > ai_code_review.json
                '''

                script {
                    try {
                        echo "打印ai_code_review.json原始内容:"
                        sh 'cat ai_code_review.json'

                        def aiRaw = readJSON file: 'ai_code_review.json'
                        if (aiRaw.empty_diff == true) {
                            echo "✅ 本次无源码变更，跳过AI评审分数校验"
                            return
                        }
                        if (aiRaw.error) {
                            error "网关返回错误: ${aiRaw.error.message}"
                        }
                        String llmOutput = aiRaw.content[0].text.trim()
                        echo "🤖 LLM原始输出文本：${llmOutput}"

                        llmOutput = llmOutput.replaceAll(/(?s).*?<\/think>\s*/, '')

                        int start = llmOutput.indexOf('{')
                        int end = llmOutput.lastIndexOf('}')
                        if (start < 0 || end < 0 || end <= start) {
                            error "未能在LLM输出中定位到JSON对象，原始输出见上"
                        }
                        String jsonStr = llmOutput.substring(start, end + 1)

                        def aiResult = new groovy.json.JsonSlurper().parseText(jsonStr)
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
                            error "❌ AI代码评审不通过！得分${score}，阈值${env.SCORE_THRESHOLD}"
                        }
                    } catch(Exception e) {
                        echo "!!!AI评审脚本捕获异常: ${e.getMessage()}"
                        error "AI代码评审处理失败，原始响应查看上面日志"
                    }
                }
            }
        }

        stage('Build in Docker') {
            steps {
                echo "==== 3. Docker 容器内编译 (${PROJECT_NAME}) ===="
                script {
                    docker.image("${BASE_IMAGE}").inside(
                        "-u root " +
                        "--cpus=14 " +
                        "--memory=16g " +
                        "-v ${WORKSPACE}:/home/sany/work/wheel_loader/src/common/message " +
                        "-v ${WORKSPACE}/build/${SAFE_REF}:/home/sany/work/wheel_loader/build " +
                        "-v ${WORKSPACE}/install/${SAFE_REF}:/home/sany/work/wheel_loader/install " +
                        "-v ${WORKSPACE}/log/${SAFE_REF}:/home/sany/work/wheel_loader/log " +
                        "-v ${WORKSPACE}/publish:/home/sany/work/wheel_loader/publish " +
                        "-v /var/lib/jenkins/workspace/setting.sh:/home/sany/work/wheel_loader/setting.sh:ro " +
                        "-e DEBIAN_FRONTEND=noninteractive"
                    ) {
                        sh(script: '''
                        #!/bin/bash
                        set -e
                        WS=/home/sany/work/wheel_loader
                        SETTING_SH=$WS/setting.sh

                        cd $WS
                        chown $(id -u):$(id -g) $WS

                        if [ "${CLEAN_BUILD}" = "true" ]; then
                            echo "########## [3.1] 全量清理 ##########"
                            bash "$SETTING_SH" clean
                        else
                            echo "########## [3.1] 增量编译模式 ##########"
                        fi

                        echo "########## [3.2] load env ##########"
                        bash "$SETTING_SH" load env

                        echo "########## [3.3] compile message ##########"
                        bash "$SETTING_SH" compile message
                        rename_msgs.sh

                        echo "########## [3.4] 验证 install 目录 ##########"
                        ls -la install/
                        echo "包数量: $(ls install/ | wc -l)"
                        ''', shell: '/bin/bash')

                        sh(script: '''
                        #!/bin/bash
                        set -e
                        WS=/home/sany/work/wheel_loader
                        cd $WS
                        TAG="${SAFE_REF}"
                        PUBLISH_DIR="$WS/publish/${TAG}"

                        echo "########## [3.5] 打包发布产物 ##########"
                        mkdir -p "$PUBLISH_DIR"

                        tar -czf "$PUBLISH_DIR/message-common_${TAG}_install.tar.gz" install
                        echo "发布包: $PUBLISH_DIR/message-common_${TAG}_install.tar.gz"
                        echo "大小: $(du -sh $PUBLISH_DIR/message-common_${TAG}_install.tar.gz)"

                        if [ -d "log" ]; then
                            tar -czf "$PUBLISH_DIR/message-common_${TAG}_log.tar.gz" log
                            echo "审计日志: $PUBLISH_DIR/message-common_${TAG}_log.tar.gz"
                        fi

                        chmod 755 "$PUBLISH_DIR"
                        ''', shell: '/bin/bash')
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "==== 4. 构建 Docker 镜像 (${IMAGE_NAME}) ===="
                sh '''
                    set -e
                    TAG="${SAFE_REF}"
                    INSTALL_TARBALL="${WORKSPACE}/publish/${TAG}/message-common_${TAG}_install.tar.gz"

                    TMP_DIR=$(mktemp -d)
                    cp "$INSTALL_TARBALL" "$TMP_DIR/install.tar.gz"

                    cat > "$TMP_DIR/Dockerfile" <<EOF
                    FROM ${BASE_IMAGE}

                    RUN mkdir -p /opt/ros/message-common
                    COPY install.tar.gz /tmp/
                    RUN tar -xzf /tmp/install.tar.gz -C /opt/ros/message-common/ \\
                        && rm /tmp/install.tar.gz

                    ENV AMENT_PREFIX_PATH=/opt/ros/message-common/install:\\${AMENT_PREFIX_PATH}
                    ENV LD_LIBRARY_PATH=/opt/ros/message-common/install/lib:\\${LD_LIBRARY_PATH}

                    LABEL project="message-common" \\
                        branch="${TAG}" \\
                        description="Pre-built ROS2 message packages for wheel_loader"
                    EOF

                    cd "$TMP_DIR"
                    docker build -t "${IMAGE_NAME}" .

                    echo "镜像构建完成: ${IMAGE_NAME}"
                    docker images | grep message-common

                    cd /
                    rm -rf "$TMP_DIR"
                '''
            }
        }

        stage('导出产物到宿主机') {
            steps {
                echo "==== 从镜像导出产物到 /home/sany/wheel_loader/message-common/ ===="
                sh '''
                    set -e
                    TAG="${SAFE_REF}"
                    IMAGE="message-common-${TAG}:latest"
                    DST_DIR="/home/sany/wheel_loader/message-common/${TAG}"

                    mkdir -p "$DST_DIR"

                    # 从镜像里把 install 目录拷出来
                    # 先创建一个临时容器
                    docker create --name tmp_export_$$ "$IMAGE"
                    # 拷贝产物
                    docker cp tmp_export_$$:/home/sany/work/Package/Common/message/install "$DST_DIR/"
                    # 删除临时容器
                    docker rm tmp_export_$$

                    echo "产物已导出到: $DST_DIR/"
                    ls -lh "$DST_DIR/install/" | head -20
                    echo "总大小: $(du -sh $DST_DIR/install/)"
                '''
            }
        }

        stage('SonarQube 代码扫描') {
            steps {
                echo "==== 5. SonarQube 代码扫描 ===="
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=message-common \
                            -Dsonar.projectName=message-common \
                            -Dsonar.projectVersion=${SAFE_REF} \
                            -Dsonar.sources=. \
                            -Dsonar.language=cxx \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.cxx.file.suffixes=.cpp,.cc,.cxx,.h,.hpp \
                            -Dsonar.qualityprofile="ROS2-CXX-Custom" \
                            -Dsonar.exclusions=build/**,install/**,log/**,publish/**,**/*.tar.gz,**/*.md,**/*.swp,**/thirdparty/**,.git/** \
                            -Dsonar.host.url=http://10.233.88.16:9000 \
                            -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "==== 6. 归档产物 + 复制到宿主机 /home/sany/wheel_loader/message-common/ ===="
                sh '''
                    set -e
                    SRC_DIR="${WORKSPACE}/publish/${SAFE_REF}"
                    DST_DIR="/home/sany/wheel_loader/message-common/${SAFE_REF}"

                    mkdir -p "$DST_DIR"
                    cp "$SRC_DIR"/*.tar.gz "$DST_DIR/"
                    echo "已复制到宿主机: $DST_DIR/"
                    ls -lh "$DST_DIR/"
                '''
                archiveArtifacts artifacts: "publish/${SAFE_REF}/*.tar.gz", fingerprint: true
            }
        }
    }

    post {
        success {
            echo "==== 编译成功 (${PROJECT_NAME}, ${params.REF_NAME}) ===="
            echo "==== 镜像已构建: ${IMAGE_NAME} ===="
        }
        failure { echo "==== 编译失败 (${PROJECT_NAME}, ${params.REF_NAME}) ====" }
    }
}
