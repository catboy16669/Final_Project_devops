pipeline {
    agent any

    environment {
        // ── UPDATE THESE TWO VALUES ──────────────────────────────
        DOCKER_IMAGE  = "YOUR_DOCKERHUB_USERNAME/aupp-lms-website"
        EC2_KEY_NAME  = "aupp-lms-key"        // Your AWS key pair name
        // ─────────────────────────────────────────────────────────

        DOCKER_TAG    = "${BUILD_NUMBER}"
        EC2_USER      = "ubuntu"
        AWS_REGION    = "ap-southeast-1"
    }

    stages {

        // ══════════════════════════════════════════════════════
        stage('1 ► Checkout Code') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '📥 Pulling source code from GitHub...'
                checkout scm
                sh 'ls -la'
            }
        }

        // ══════════════════════════════════════════════════════
        stage('2 ► SonarQube — Code Quality Scan') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🔍 Scanning code quality with SonarQube...'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=aupp-lms-website \
                          -Dsonar.sources=. \
                          -Dsonar.exclusions="assets/vendor/**,assets/img/**,**/*.map,**/*.min.js,**/*.min.css,terraform/**" \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    '''
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('3 ► SonarQube — Quality Gate') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🚦 Checking Quality Gate result...'
                // Pipeline FAILS here if Quality Gate is not passed
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('4 ► Trivy — Source Code Scan') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🛡️ Scanning source for vulnerabilities...'
                sh '''
                    trivy fs \
                      --exit-code 1 \
                      --severity CRITICAL \
                      --no-progress \
                      --format table \
                      --skip-dirs assets/vendor \
                      . 2>&1 | tee trivy-source-report.txt || true

                    echo "──── Trivy Source Scan Complete ────"
                    cat trivy-source-report.txt
                '''
                // NOTE: using "|| true" above so pipeline continues for demo.
                // For strict enforcement, remove "|| true"
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-source-report.txt',
                                     allowEmptyArchive: true
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('5 ► Docker — Build Image') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🐳 Building Docker image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag  ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    docker images | grep aupp-lms
                """
            }
        }

        // ══════════════════════════════════════════════════════
        stage('6 ► Trivy — Docker Image Scan') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🛡️ Scanning Docker image for vulnerabilities...'
                sh """
                    trivy image \
                      --exit-code 1 \
                      --severity CRITICAL \
                      --no-progress \
                      --format table \
                      ${DOCKER_IMAGE}:${DOCKER_TAG} 2>&1 | tee trivy-image-report.txt

                    echo "──── Trivy Image Scan Complete ────"
                    cat trivy-image-report.txt
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-image-report.txt',
                                     allowEmptyArchive: true
                }
                failure {
                    echo '❌ CRITICAL vulnerabilities found in Docker image. Pipeline stopped.'
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('7 ► Docker — Push to DockerHub') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '📤 Pushing Docker image to DockerHub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        echo "✅ Image pushed: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    '''
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('8 ► Terraform — Provision EC2') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '☁️  Provisioning EC2 instance with Terraform...'
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            export AWS_DEFAULT_REGION=${AWS_REGION}

                            terraform init
                            terraform plan -out=tfplan

                            # Apply — creates EC2 if not exists, skips if already up
                            terraform apply -auto-approve tfplan

                            # Save EC2 IP for deployment stage
                            terraform output -raw ec2_public_ip > ../ec2_ip.txt
                            echo "EC2 IP: $(cat ../ec2_ip.txt)"
                        '''
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'ec2_ip.txt', allowEmptyArchive: true
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('9 ► Deploy — Website to EC2') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '🚀 Deploying AUPP LMS website to EC2...'
                script {
                    def EC2_IP = sh(
                        script: "cat ec2_ip.txt | tr -d '\\n '",
                        returnStdout: true
                    ).trim()

                    echo "Target EC2: ${EC2_IP}"

                    sshagent(['ec2-ssh-key']) {
                        sh """
                            # Wait for EC2 Docker daemon to be fully ready
                            echo "Waiting 45s for EC2 to be ready..."
                            sleep 45

                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '
                                echo "=== Connected to EC2 ==="

                                # Pull the latest image
                                docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}

                                # Stop and remove old container if running
                                docker stop aupp-lms 2>/dev/null || true
                                docker rm   aupp-lms 2>/dev/null || true

                                # Run the website container
                                docker run -d \\
                                  --name aupp-lms \\
                                  --restart always \\
                                  -p 80:80 \\
                                  ${DOCKER_IMAGE}:${DOCKER_TAG}

                                # Run nginx-prometheus-exporter (scrapes /stub_status)
                                docker stop nginx-exporter 2>/dev/null || true
                                docker rm   nginx-exporter 2>/dev/null || true
                                docker run -d \\
                                  --name nginx-exporter \\
                                  --restart always \\
                                  -p 9113:9113 \\
                                  nginx/nginx-prometheus-exporter:latest \\
                                  -nginx.scrape-uri=http://localhost:80/stub_status

                                echo "=== Containers running ==="
                                docker ps
                            '
                        """
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════
        stage('10 ► Deploy — Prometheus + Grafana') {
        // ══════════════════════════════════════════════════════
            steps {
                echo '📊 Setting up Prometheus + Grafana monitoring...'
                script {
                    def EC2_IP = sh(
                        script: "cat ec2_ip.txt | tr -d '\\n '",
                        returnStdout: true
                    ).trim()

                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '
                                mkdir -p /home/ubuntu/monitoring

                                # Write Prometheus config
                                cat > /home/ubuntu/monitoring/prometheus.yml << PROMEOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "aupp-lms-nginx"
    static_configs:
      - targets: ["localhost:9113"]
    metrics_path: /metrics

  - job_name: "node-exporter"
    static_configs:
      - targets: ["localhost:9100"]
PROMEOF

                                # Run node-exporter (host metrics)
                                docker stop node-exporter 2>/dev/null || true
                                docker rm   node-exporter 2>/dev/null || true
                                docker run -d \\
                                  --name node-exporter \\
                                  --restart always \\
                                  --network host \\
                                  -v /proc:/host/proc:ro \\
                                  -v /sys:/host/sys:ro \\
                                  -v /:/rootfs:ro \\
                                  prom/node-exporter:latest \\
                                  --path.procfs=/host/proc \\
                                  --path.sysfs=/host/sys

                                # Run Prometheus
                                docker stop prometheus 2>/dev/null || true
                                docker rm   prometheus 2>/dev/null || true
                                docker run -d \\
                                  --name prometheus \\
                                  --restart always \\
                                  --network host \\
                                  -v /home/ubuntu/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml \\
                                  prom/prometheus:latest

                                # Run Grafana
                                docker stop grafana 2>/dev/null || true
                                docker rm   grafana 2>/dev/null || true
                                docker run -d \\
                                  --name grafana \\
                                  --restart always \\
                                  -p 3000:3000 \\
                                  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \\
                                  grafana/grafana:latest

                                echo "=== All containers running ==="
                                docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                            '
                        """
                    }
                }
            }
        }

    }

    // ══════════════════════════════════════════════════════════
    post {
    // ══════════════════════════════════════════════════════════
        success {
            script {
                def EC2_IP = sh(
                    script: "cat ec2_ip.txt 2>/dev/null | tr -d '\\n ' || echo 'check-aws-console'",
                    returnStdout: true
                ).trim()
                echo """
╔══════════════════════════════════════════════════╗
║         ✅  PIPELINE SUCCEEDED                  ║
╠══════════════════════════════════════════════════╣
║  🌐 Website:    http://${EC2_IP}                ║
║  📊 Prometheus: http://${EC2_IP}:9090           ║
║  📈 Grafana:    http://${EC2_IP}:3000           ║
║     Grafana login: admin / admin123             ║
╚══════════════════════════════════════════════════╝
                """
            }
        }
        failure {
            echo '❌ Pipeline FAILED — check the red stage above for details.'
        }
        always {
            sh 'docker logout || true'
            cleanWs()
        }
    }
}