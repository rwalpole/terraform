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

  name = "GitHubOIDCRole"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects = [
    # You can prepend with `repo:` but it is not required
    "repo:nationalarchives/ctd-omega-editorial-frontend:*"
  ]

  policies = {
    #additional = aws_iam_policy.github_ctd_omega_editorial_frontend.arn
    S3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  #tags = local.tags
}

#data "tls_certificate" "github_thumbprint" {
#  certificates =[{
#    sha1_fingerprint = "6938fd4d98bab03faadb97b34396831e3780aea1"
#  }]
#}

#module "iam_github_oidc_provider" {
#  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
#}

#
#resource "aws_iam_role" "ffdsfs" {
#  name = "dfsfsdf"
#
#}
#
#resource "aws_iam_policy" "github_ctd_omega_editorial_frontend" {
#  name = "github_ctd_omega_editorial_frontend"
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#  	{
# 		"Effect": "Allow",
#		"Principal": {
#			"Federated": "arn:aws:iam::495195014394:oidc-provider/token.actions.githubusercontent.com"
#		},
#		"Action": "sts:AssumeRoleWithWebIdentity",
#		"Condition": {
#			"StringLike": {
#				"token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
#				"token.actions.githubusercontent.com:sub": "repo:nationalarchives/ctd-omega-editorial-frontend:*"
#			}
#		}
#	}
# ]
#}
#EOF
#}
#
#
#resource "aws_iam_role_policy_attachment" "CodeDeployRolePolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
#  role       = aws_iam_role.CodeDeployServiceRole2.name
#}