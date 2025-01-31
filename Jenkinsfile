pipeline {
    agent any

    environment {
        ECR_REPO = "010438494949.dkr.ecr.us-east-1.amazonaws.com/nginx-app"
        AWS_ROLE_ARN_ECR = "arn:aws:iam::010438494949:role/jenkins-role-ecr"
        AWS_ROLE_ARN_EKS = "arn:aws:iam::010438494949:role/jenkins-role-eks"
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "nginx-cluster"
        APP_NAME = "nginx-app"
        IMAGE_TAG = "latest"
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
                    def imageName = "${ECR_REPO}:${IMAGE_TAG}"
                    sh "docker build -t ${imageName} ."
                    sh "docker rm -f ${APP_NAME} || true"
                    sh "docker run -d --name ${APP_NAME} -p 8081:80 ${imageName}"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withAWS(region: AWS_REGION, role: AWS_ROLE_ARN_ECR) {
                    script {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                        def imageName = "${ECR_REPO}:${IMAGE_TAG}"
                        sh "docker push ${imageName}"
                        sh "docker rmi ${imageName} || true"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(region: AWS_REGION, role: AWS_ROLE_ARN_EKS) {
                    script {
                        sh '''
                          # Install kubectl if not present
                          if ! command -v kubectl &> /dev/null; then
                              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                              chmod +x kubectl
                              mkdir -p $HOME/bin
                              mv kubectl $HOME/bin/
                              export PATH=$HOME/bin:$PATH
                          fi
                        '''
                        
                        sh 'kubectl version --client'

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
