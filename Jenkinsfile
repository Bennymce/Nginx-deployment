pipeline {
    agent any
    environment {
        ECR_REPO = "nginx-app"
        AWS_ROLE_ARN_ECR = 'arn:aws:iam::010438494949:role/jenkins-role-ecr'  // IAM Role ARN for ECR
        AWS_ROLE_ARN_EKS = 'arn:aws:iam::010438494949:role/jenkins-role-eks'
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "nginx-cluster"
        APP_NAME = "nginx-app"
        IMAGE_TAG = "latest"
        IMAGE_NAME = "${ECR_REPO}/${APP_NAME}:${IMAGE_TAG}"
        SONARQUBE = "sonar"
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Bennymce/Nginx-deployment.git'
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
                    // Using the IAM role for AWS credentials to login to ECR
                    withAWS(region: AWS_REGION, roleArn: AWS_ROLE_ARN_ECR) {
                        sh 'aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPO}'
                    }
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    // Push the Docker image to ECR using the assumed IAM role for ECR access
                    withAWS(region: AWS_REGION, roleArn: AWS_ROLE_ARN_ECR) {
                        docker.push("${IMAGE_NAME}")
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Use kubectl with the assumed IAM role for EKS access
                    withAWS(region: AWS_REGION, roleArn: AWS_ROLE_ARN_EKS) {
                        sh 'aws eks update-kubeconfig --name ${CLUSTER_NAME}'
                        kubectl apply -f nginx-deployment.yaml
                    }
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
