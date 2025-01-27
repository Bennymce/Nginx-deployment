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