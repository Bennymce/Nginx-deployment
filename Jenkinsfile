pipeline {
    agent any
    environment {
        ECR_REPO = "010438494949.dkr.ecr.us-east-1.amazonaws.com/nginx-app"
        AWS_ROLE_ARN_ECR = 'arn:aws:iam::010438494949:role/jenkins-role-ecr'  // IAM Role ARN for ECR
        AWS_ROLE_ARN_EKS = 'arn:aws:iam::010438494949:role/jenkins-role-eks'
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "nginx-cluster"
        APP_NAME = "nginx-app"
        IMAGE_TAG = "latest"
        IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
        AWS_ACCOUNT_ID = "010438494949"
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
                    // List files to ensure Dockerfile and index.html are present
                    sh 'ls -alh'
                    sh "docker build -t ${IMAGE_NAME} ."
                    
                    // Clean up existing container if it's running
                    sh "docker rm -f ${APP_NAME} || true"
                    
                    // Run the Docker container
                    sh "docker run -d --name ${APP_NAME} -p 8081:80 ${IMAGE_NAME}"
                }
            }
        }

        stage('Install Trivy') {
            steps {
                script {
                    // Install Trivy
                    sh 'curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-64bit.deb -o trivy.deb'
                    sh 'dpkg -i trivy.deb || true'
                    sh 'rm trivy.deb'  // Clean up
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Scan the Docker image with Trivy
                    sh "trivy image ${IMAGE_NAME}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    // Login to AWS ECR using the assumed IAM role for ECR
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}") {
                        echo "Logged into AWS ECR with assumed role"
                        // AWS CLI login to ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    }
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    // Push Docker image to ECR using Docker command
                    echo "Pushing image to ECR: ${IMAGE_NAME}"
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}") {
                        sh "docker push ${IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Deploy the app to EKS using kubectl
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_EKS}") {
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
                        sh "kubectl apply -f nginx-deployment.yaml"
                    }
                }
            }
        }
    }
    post {
        always {
            // Clean workspace after pipeline completion
            cleanWs()
        }
    }
}
