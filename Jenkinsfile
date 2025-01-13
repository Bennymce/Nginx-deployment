pipeline {
    agent any
    environment {
        ECR_REPO = "your-ecr-repo"
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "your-cluster-name"
        APP_NAME = "nginx-app"
        IMAGE_TAG = "latest"
        IMAGE_NAME = "${ECR_REPO}/${APP_NAME}:${IMAGE_TAG}"
        SONARQUBE = "sonar"
    }
    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/your-repository/nginx-app.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}")
                }
            }
        }
        stage('Trivy Scan') {
            steps {
                script {
                    sh "trivy image ${IMAGE_NAME}"
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv(SONARQUBE) {
                        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=${APP_NAME}"
                    }
                }
            }
        }
        stage('Login to ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-oidc-credentials', region: AWS_REGION) {
                        sh 'aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPO}'
                    }
                }
            }
        }
        stage('Push Image to ECR') {
            steps {
                script {
                    docker.push("${IMAGE_NAME}")
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                script {
                    kubectl apply -f k8s/deployment.yaml
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
