



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