# Grab some information about and from the current AWS account.
data "aws_caller_identity" "current" {}

data "aws_iam_policy" "demo_user_permissions_tfefdo" {
  name = "DemoUser"
}

locals {
  my_email = split("/", data.aws_caller_identity.current.arn)[2]
}

# Create the user to be used in tfefdo for s3 bucket access
resource "aws_iam_user" "tfefdo_user" {
  name                 = "demo-${local.my_email}-bsr"
  permissions_boundary = data.aws_iam_policy.demo_user_permissions_tfefdo.arn
  force_destroy        = true
}

resource "aws_iam_user_policy_attachment" "tfefdo_user" {
  user       = aws_iam_user.tfefdo_user.name
  policy_arn = data.aws_iam_policy.demo_user_permissions_tfefdo.arn
}

data "aws_iam_policy_document" "tfefdo_user_policy" {
  statement {
    sid = "InteractWithS3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
    ]
    resources = ["arn:aws:s3:::${var.object_storage_s3_bucket}/*"]
  }
  statement {
    actions = [
      "iam:DeleteAccessKey",
      "iam:GetUser",
      "iam:CreateAccessKey"
    ]
    resources = [aws_iam_user.tfefdo_user.arn]
  }
}

resource "aws_iam_policy" "tfefdo_user_policy" {
  name        = "demo-${local.my_email}-tfefdo-policy"
  path        = "/"
  description = "Managed policy for the tfefdo user"
  policy      = data.aws_iam_policy_document.tfefdo_user_policy.json
}


resource "aws_iam_user_policy_attachment" "tfefdo_user_policy" {
  user       = aws_iam_user.tfefdo_user.name
  policy_arn = aws_iam_policy.tfefdo_user_policy.arn
}

# Generate some secrets to pass in to the tfefdo configuration.
# WARNING: These secrets are not encrypted in the state file. Ensure that you do not commit your state file!
resource "aws_iam_access_key" "tfefdo_user" {
  user       = aws_iam_user.tfefdo_user.name
  depends_on = [aws_iam_user_policy_attachment.tfefdo_user]
}

# AWS is eventually-consistent when creating IAM Users. Introduce a wait
# before handing credentails off to tfefdo.
resource "time_sleep" "tfefdo_user_user_ready" {
  create_duration = "10s"

  depends_on = [aws_iam_access_key.tfefdo_user]
}
