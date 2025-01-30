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
                          mkdir -p $HOME/bin
                          mv kubectl $HOME/bin/
                          echo 'export PATH=$HOME/bin:$PATH' >> $HOME/.bashrc
                        '''
                        // Ensure kubectl path is set for the session
                        sh 'export PATH=$HOME/bin:$PATH && kubectl version --client'

                        // Configure kubeconfig for EKS
                        sh "mkdir -p /tmp/.kube"
                        sh "aws eks update-kubeconfig --name your-cluster-name --region ${AWS_REGION} --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ROLE_ARN_ECR}"
                        // sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME} --kubeconfig ${KUBECONFIG}"

                        // Deploy application
                        sh "$HOME/bin/kubectl apply -f nginx-deployment.yaml --kubeconfig ${KUBECONFIG}"
                        sh "$HOME/bin/kubectl rollout status deployment/${APP_NAME} --kubeconfig ${KUBECONFIG}"


                        // sh "kubectl apply -f nginx-deployment.yaml --kubeconfig ${KUBECONFIG}"
                        // sh "kubectl rollout status deployment/${APP_NAME} --kubeconfig ${KUBECONFIG}"
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
