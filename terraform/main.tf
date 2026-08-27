provider "aws" {
  region = "us-east-1"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = "supersecretpassword123!"
  })
}

# IAM Role for Service Account (IRSA) for External Secrets Operator
resource "aws_iam_role" "eso_role" {
  name = "external-secrets-operator-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
        }
        Condition = {
          "StringEquals" = {
            "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub" : "system:serviceaccount:external-secrets:eso-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eso_policy" {
  name        = "external-secrets-policy"
  description = "Policy for External Secrets Operator to read Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_policy.arn
}
