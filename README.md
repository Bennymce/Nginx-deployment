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
  -p 8080:8080 -p 50000:50000 \
  -v /home/ubuntu/Nginx-deployment:/var/jenkins_home/workspace/jenkins-app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/jenkins_home:/var/jenkins_home \
  --group-add $(getent group docker | cut -d: -f3) \
  --user root \
  jenkins/jenkins:lts


docker logs jenkins-docker get jenkins password
