### EC2 Instance config ###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

################################################################################
# CodeDeploy EC2 Instance Profile
################################################################################
resource "aws_iam_role" "code_deploy_ec2_instance_profile_role" {
  name = "code_deploy_ec2_instance_profile_role"
  description = "Allows EC2 instances to call AWS services on your behalf."
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "code_deploy_ec2_profile" {
  name = "CodeDeployEC2Profile"
  role = aws_iam_role.code_deploy_ec2_instance_profile_role.name
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1i2MVPWhX0cBkSwcrWPP01yALw/yZH6n7Jobx7JQYS/UJOGKqz7GwW4uG3YZwRCIm4dQdmiOH6VqfQ/xVAE+ashPM+ZEpBWAyRe7JNyRMMUNXoGphqHr0IAUNMcP16U5W2gR5SYIQyLAoFDKuwiK1kpCvy/1HyzYY8U1I4g06hlqK+m7SCJF1lEsoDdpOfwrgVsv9DKApdWAeII8Vq2ZgNffKNp+v/G2F8a81ucPBBcVt6WOaqIeNw+f6TbiAMuAHx4CbtQrdDkePwziy0dC+dKzHVZ3NdmLbdCJPR6jku7DX/LGzDYdXZ0qdkQL8MkFFvJAhR0VRe1+mZour3Q1P"
}

################################################################################
# Editorial Web Frontend Server
################################################################################
resource "aws_launch_template" "install_code_deploy_agent" {
  user_data = filebase64("${path.module}/install-code-deploy-agent.sh")
}

resource "aws_instance" "frontend_server" {
  ami           = "ami-084e8c05825742534"
  launch_template {
    name = aws_launch_template.install_code_deploy_agent.name
  }
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.code_deploy_ec2_profile.name
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "EditorialWeb"
  }
}



################################################################################
# CodeDeploy Service Role
################################################################################
resource "aws_iam_role" "CodeDeployServiceRole2" {
  name        = "CodeDeployServiceRole2"
  description = "Allows CodeDeploy to call AWS services such as Auto Scaling on your behalf."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployServiceRole2.name
}

################################################################################
# CodeDeploy EC2 Permissions
################################################################################
resource "aws_iam_policy" "code_deploy_ec2_permissions" {
  name = "CodeDeployEC2Permissions"
  description = "Gives access to ctd-omega-frontend-deployment S3 bucket"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:Get*",
          "s3:List*"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::ctd-omega-frontend-deployment/*",
          "arn:aws:s3:::aws-codedeploy-eu-west-2/*"
        ]
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "code_deploy_ec2_attach" {
  role = aws_iam_role.code_deploy_ec2_instance_profile_role.name
  policy_arn = aws_iam_policy.code_deploy_ec2_permissions.arn
}

################################################################################
# Enable EC2 instance to use AWS Systems Manager for Code Deploy
################################################################################
resource "aws_iam_role_policy_attachment" "code_deploy_ssm_attach" {
  role       = aws_iam_role.code_deploy_ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}





/*
resource "aws_iam_role" "editorial_frontend_github_actions" {
  name = "editorial_frontend_github_actions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
*/

################################################################################
# CodeDeploy User
################################################################################
resource "aws_iam_user" "cd_user" {
  name = "cd_user"
  #path = "/system/"
  /*
  tags = {
    tag-key = "tag-value"
  }
  */
}

resource "aws_iam_policy" "CodeDeployAccess" {
  name = "CodeDeployAccess"
  #user = aws_iam_user.cd_user.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        #Sid = "CodeDeployAccessPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "codedeploy:*",
          "ec2:*",
          #"lambda:*",
          #"ecs:*",
          # There is probably a whole bunch here we don't need
          "elasticloadbalancing:*",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "s3:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid = "CodeDeployRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.CodeDeployServiceRole2.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "cd_role_policy" {
  name = "CodeDeployRole"
  role = aws_iam_role.CodeDeployServiceRole2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "CodeDeployAccessPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "codedeploy:*",
          "ec2:*",
          #"lambda:*",
          #"ecs:*",
          # There is probably a whole bunch here we don't need
          "elasticloadbalancing:*",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "s3:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid = "CodeDeployRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.CodeDeployServiceRole2.arn
      }
    ]
  })
}




### CodeDeploy Config ###

resource "aws_codedeploy_app" "CtdOmegaEditorialFrontend" {
  name = "CtdOmegaEditorialFrontend"
}

/*
resource "aws_sns_topic" "example" {
  name = "example-topic"
}
*/

resource "aws_codedeploy_deployment_group" "CtdOmegaEditorialFrontend-DepGrp" {
  app_name               = aws_codedeploy_app.CtdOmegaEditorialFrontend.name
  deployment_group_name  = "CtdOmegaEditorialFrontend-DepGrp"
  service_role_arn       = aws_iam_role.CodeDeployServiceRole2.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "EditorialWeb"
    }

  }

  /*
  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "example-trigger"
    trigger_target_arn = aws_sns_topic.example.arn
  }
  */

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }
}

### S3 Bucket config ###
resource "aws_s3_bucket" "ctd-omega-frontend-deployment" {
  bucket = "ctd-omega-frontend-deployment"

  /*
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
  */
}

resource "aws_s3_bucket_public_access_block" "web_deployment_public_access_block" {
  bucket = aws_s3_bucket.ctd-omega-frontend-deployment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# GitHub OIDC Provider
# Note: This is one per AWS account
################################################################################
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

################################################################################
# GitHub OIDC Role
################################################################################
module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = "iam_github_oidc"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects = [
    # You can prepend with `repo:` but it is not required
    "repo:nationalarchives/ctd-omega-editorial-frontend:*"
  ]

  policies = {
    additional = aws_iam_policy.CodeDeployAccess.arn
    S3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  #tags = local.tags
}

