pipeline {
    agent any

    environment {
        ECR_REPO = "010438494949.dkr.ecr.us-east-1.amazonaws.com/nginx-app"
        AWS_ROLE_ARN_ECR = 'arn:aws:iam::010438494949:role/jenkins-role-ecr'
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
                    sh 'ls -alh'
                    sh "docker build -t ${IMAGE_NAME} ."
                    sh "docker rm -f ${APP_NAME} || true"
                    sh "docker run -d --name ${APP_NAME} -p 8081:80 ${IMAGE_NAME}"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withAWS(region: AWS_REGION, role: AWS_ROLE_ARN_ECR) {
                    script {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                        sh "docker push ${IMAGE_NAME}"
                        sh "docker rmi ${IMAGE_NAME} || true"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(region: AWS_REGION, role: AWS_ROLE_ARN_EKS) {
                    script {
                        // Install kubectl in Jenkins user space
                        sh '''
                          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                          chmod +x kubectl
                          mkdir -p /var/jenkins_home/bin
                          mv kubectl /var/jenkins_home/bin/
                        '''
                        
                        // Ensure kubectl path is set for the session
                        withEnv(["PATH+bin=/var/jenkins_home/bin"]) {
                            sh 'kubectl version --client'
                        }
                        
                        // Configure kubeconfig for EKS
                        sh "mkdir -p /tmp/.kube"
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} --kubeconfig /tmp/.kube/config"

                        // Deploy application
                        sh "kubectl apply -f nginx-deployment.yaml --kubeconfig /tmp/.kube/config"
                        sh "kubectl rollout status deployment/${APP_NAME} --kubeconfig /tmp/.kube/config"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            sh "rm -rf /tmp/.kube"
        }
    }
}
