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

resource "aws_instance" "frontend_server" {
  ami           = "ami-084e8c05825742534"
  instance_type = "t2.micro"

  tags = {
    Name = "editorial_web"
  }
}

### IAM config ###
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

/*
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role..role.name
}
*/

resource "aws_iam_role" "code_deploy_ec2_instance_profile" {
  name = "code_deploy_ec2_instance_profile"
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

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployServiceRole2.name
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

resource "aws_codedeploy_deployment_group" "CtdOmegaServicesPrototype-DepGrp2" {
  app_name               = aws_codedeploy_app.CtdOmegaEditorialFrontend.name
  deployment_group_name  = "CtdOmegaServicesPrototype-DepGrp2"
  service_role_arn       = aws_iam_role.CodeDeployServiceRole2.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "CodeDeployDemo2"
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

