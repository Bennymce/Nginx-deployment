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

        stage('Push Docker Image to ECR') {
            steps {
                withAWS(region: AWS_REGION, role: AWS_ROLE_ARN_ECR) {
                    script {
                        def ecrLogin = sh(
                            script: "aws ecr get-login-password --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        sh "echo '${ecrLogin}' | docker login --username AWS --password-stdin ${ECR_REPO}"
                        
                        sh "docker push ${IMAGE_NAME}"
                        
                        // Optional cleanup
                        sh "docker rmi ${IMAGE_NAME} || true"
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
