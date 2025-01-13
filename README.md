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
