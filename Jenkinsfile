pipeline {
    agent any
    
    environment {
        ECR_REPO = "010438494949.dkr.ecr.us-east-1.amazonaws.com/nginx-app"
        AWS_ROLE_ARN_ECR = 'arn:aws:iam::010438494949:role/jenkins-role-ecr'
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "nginx-cluster"
        APP_NAME = "nginx-app"
        IMAGE_TAG = "latest"
        IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
        AWS_ACCOUNT_ID = "010438494949"
        KUBECONFIG = '/tmp/.kube/config'
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
        
        stage('Install Trivy') {
            steps {
                script {
                    sh 'curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-64bit.deb -o trivy.deb'
                    sh 'dpkg -i trivy.deb || true'
                    sh 'rm trivy.deb'
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
        
        stage('Login to ECR') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}") {
                        echo "Logged into AWS ECR with assumed role"
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    }
                }
            }
        }
        
        stage('Push Image to ECR') {
            steps {
                script {
                    echo "Pushing image to ECR: ${IMAGE_NAME}"
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}") {
                        sh "docker push ${IMAGE_NAME}"
                    }
                }
            }
        }
        
        stage('Install kubectl') {
            steps {
                script {
                    sh '''
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mkdir -p /tmp/.kube
                    '''
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}") {
                        // Set up kubeconfig
                        sh """
                            ./kubectl version --client
                            aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}
                            
                            # Deploy using kubectl
                            ./kubectl --kubeconfig=${KUBECONFIG} apply -f nginx-deployment.yaml
                            
                            # Verify deployment
                            ./kubectl --kubeconfig=${KUBECONFIG} get deployments -l app=${APP_NAME}
                            ./kubectl --kubeconfig=${KUBECONFIG} get services -l app=${APP_NAME}
                        """
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