# Nginx-deployment
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:UpdateClusterConfig"
      ],
      "Resource": "arn:aws:eks:us-east-1:010438494949:cluster/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::010438494949:role/jenkins-serviceaccount.yaml"
    }
  ]
}


chmod +x git-commands.sh
./git-commands.sh


docker run -d \
  --name jenkins-docker \
  --network="host" \
  -p 8080:8080 -p 50000:50000 \
  -v /home/ubuntu/Nginx-deployment:/var/jenkins_home/workspace/jenkins-app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/jenkins_home:/var/jenkins_home \
  --group-add $(getent group docker | cut -d: -f3) \
  --user root \
  jenkins/jenkins:lts


docker logs jenkins-docker get jenkins password


withAWS(role: 'arn:aws:iam::<account-id>:role/<role-name>', roleSessionName: 'JenkinsSession') {
    sh 'aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com'
}


{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
"AWS": "arn:aws:iam::010438494949:role/jenkins-role-ecr"
},
"Action": "sts:AssumeRole"
}
]
}

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::010438494949:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0F8342397951D9E325F05344F8AC27A2"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/0F8342397951D9E325F05344F8AC27A2:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}


withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}", roleSessionName: 'jenkins-ecr-login') {
                        echo "Logged into AWS ECR with assumed role"
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"





docker run -d \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --memory="3g" --cpus="1.5" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /root/.aws:/root/.aws \
  -e AWS_REGION=us-east-1 \
  --name jenkins \
  custom-jenkins  


stage('Install Trivy') {
            steps {
                script {
                    sh '''
                        curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-64bit.deb -o trivy.deb
                        dpkg -i trivy.deb || true
                        rm trivy.deb
                    '''
                }
            }
        }

        // Uncomment this stage if Trivy scanning is required
        /*
        stage('Trivy Scan') {
            steps {
                script {
                    sh "trivy image ${IMAGE_NAME}"
                }
            }
        }
        */

        stage('Debug Info') {
            steps {
                sh '''
                    aws --version
                    java -version
                '''
            }
        }

        stage('Debug AWS') {
            steps {
                script {
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}", roleSessionName: 'jenkins-ecr-login') {
                        sh '''
                            aws sts get-caller-identity
                            aws ecr describe-repositories
                        '''
                    }
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh """
                aws ecr get-login-password --region us-east-1 | \
                docker login --username AWS --password-stdin \
                010438494949.dkr.ecr.us-east-1.amazonaws.com
            """
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    echo "Pushing image to ECR: ${IMAGE_NAME}"
                    withAWS(region: "${AWS_REGION}", role: "${AWS_ROLE_ARN_ECR}", roleSessionName: 'jenkins-ecr-push') {
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
                        sh '''
                            ./kubectl version --client
                            aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}

                            # Deploy using kubectl
                            ./kubectl --kubeconfig=${KUBECONFIG} apply -f nginx-deployment.yaml

                            # Verify deployment
                            ./kubectl --kubeconfig=${KUBECONFIG} get deployments -l app=${APP_NAME}
                            ./kubectl --kubeconfig=${KUBECONFIG} get services -l app=${APP_NAME}
                        '''
                    }
                }
            }
        }
    }                       


    ./git-commands.sh
    aws ec2 associate-iam-instance-profile --instance-id 54.227.193.90 --iam-instance-profile Name=arn:aws:iam::010438494949:instance-profile/jenkins-role-ecr

curl http://169.254.169.254/latest/meta-data/iam/security-credentials/jenkins-role-ecr
aws ec2 describe-instances --instance-ids 54.227.193.90  --query "Reservations[].Instances[].IamInstanceProfile"

