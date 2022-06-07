resource "aws_s3_bucket" "mjmm_test_perms" {
  bucket = "mjmm-test-perms"
  tags = {
    "billingtag" = "Management"
  }
}

# create two roles, one for folder1 and one for folder2
resource "aws_iam_role" "folder1role" {
  name        = "folder1role"
  description = "test S3 access controls"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.username}"
          }
        }
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "folder2role" {
  name        = "folder2role"
  description = "test S3 access controls"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.username}"
          }
        }
      ]
      Version = "2012-10-17"
    }
  )
}

#
# Grants access to folder 1 but not to folder2
#
data "aws_iam_policy_document" "folder1policydoc" {
  # allow access to list all buckets
  /*
    statement {
    actions = [
        "s3:ListAllMyBuckets", 
        "s3:GetBucketLocation"
        ]
    effect  = "Allow"
    resources = [ "arn:aws:s3:::*" ]
  }
  */
  # allow specific access to see folder "folder1"
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.mjmm_test_perms.arn}"]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "folder1"]
    }
  }
  # allow specific access to list objects in folder1
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.mjmm_test_perms.arn}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["folder1/*"]
    }
  }
  # carry out operations on all objects in folder1
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.mjmm_test_perms.arn}/folder1/*",
    ]
  }
  # deny all access to folder2
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.mjmm_test_perms.arn}/folder2/*",
    ]
  }
}

resource "aws_iam_policy" "folder1policy" {
  name        = "folder1policy"
  policy      = data.aws_iam_policy_document.folder1policydoc.json
  description = "Access to folder1"
}

resource "aws_iam_role_policy_attachment" "folder1policyatt" {
  role       = aws_iam_role.folder1role.name
  policy_arn = aws_iam_policy.folder1policy.arn
}

#
# grants access to folder2 but denies access to folder1
#
data "aws_iam_policy_document" "folder2policydoc" {
  # allow access to list all buckets
  /*
    statement {
    actions = [
        "s3:ListAllMyBuckets", 
        "s3:GetBucketLocation"
        ]
    effect  = "Allow"
    resources = [ "arn:aws:s3:::*" ]
  }
  */
  # allow specific access to see folder folder2
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.mjmm_test_perms.arn}"]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "folder2"]
    }
  }
  # allow specific access to list objects in folder2
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.mjmm_test_perms.arn}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["folder2/*"]
    }
  }
  # carry out operations on all objects in folder2
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.mjmm_test_perms.arn}/folder2/*",
    ]
  }
  # deny all access to folder1
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.mjmm_test_perms.arn}/folder1/*",
    ]
  }
}

resource "aws_iam_policy" "folder2policy" {
  name        = "folder2policy"
  policy      = data.aws_iam_policy_document.folder2policydoc.json
  description = "Access to folder2"
}

resource "aws_iam_role_policy_attachment" "folder2policyatt" {
  role       = aws_iam_role.folder2role.name
  policy_arn = aws_iam_policy.folder2policy.arn
}
