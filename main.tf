provider "aws" {
  region  = "us-east-1"
}

# SageMaker Assume Role Policy
data "aws_iam_policy_document" "sm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

# SageMaker IAM role
resource "aws_iam_role" "sagemaker_domain_execution_role" {
  name = "aws-sagemaker-domain-execution-iam-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.sm_assume_role_policy.json
}

# Attach IAM Policy
resource "aws_iam_role_policy_attachment" "s3-fullaccess-role-policy-attach" {
  role       = "${aws_iam_role.sagemaker_domain_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-fullaccess-role-policy-attach" {
  role       = "${aws_iam_role.sagemaker_domain_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker-canvas-role-policy-attach" {
  role       = "${aws_iam_role.sagemaker_domain_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerCanvasFullAccess"
}

resource "aws_sagemaker_domain" "sagemaker-domain1" {
  domain_name = "sagemaker-user1"
  auth_mode   = "IAM"
  vpc_id = var.sm_vpc_id
  subnet_ids = var.sm_subnets
  default_user_settings {
    execution_role = aws_iam_role.sagemaker_domain_execution_role.arn
  }
  default_space_settings {
    execution_role = aws_iam_role.sagemaker_domain_execution_role.arn
  }
}

resource "aws_sagemaker_user_profile" "sagemaker-userprofile1" {
  domain_id         = aws_sagemaker_domain.sagemaker-domain1.id
  user_profile_name = "sagemaker-userprofile1"
  user_settings {
    execution_role = aws_iam_role.sagemaker_domain_execution_role.arn
  }
}

resource "aws_sagemaker_app" "sagemaker_pipeline" {
  domain_id         = aws_sagemaker_domain.sagemaker-domain1.id
  user_profile_name = aws_sagemaker_user_profile.sagemaker-userprofile1.user_profile_name
  app_name          = "agemaker-pipeline"
  app_type          = "JupyterServer"
}

# Make a change according to your VPC ID
variable "sm_vpc_id" {
  default = "vpc-0fbe8ef54702af251"
}

# Make a change according to your Subnet IDs
variable "sm_subnets" {
  default = ["subnet-031a2d38228a46f1c","subnet-0e6972b42d3b68bf6"]
}

# Make a change according to your Security Groups
variable "sm_sec_group" {
  default = "	sg-0800cafb84d80fcbc"
}
