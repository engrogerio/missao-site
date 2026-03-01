
resource "aws_iam_user" "assumer" {
  name = var.iam_user_name
}

resource "aws_iam_policy" "s3_upload_policy" {
  name        = "S3UploadOnlyPolicy"
  description = "Allow PutObject on specific bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role" "s3_upload_role" {
  name = "S3UploadTempRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.assumer.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.s3_upload_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}

resource "aws_iam_user_policy" "allow_assume_role" {
  name = "AllowAssumeS3UploadRole"
  user = aws_iam_user.assumer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.s3_upload_role.arn
      }
    ]
  })
}