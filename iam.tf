resource "aws_iam_role" "executionrole" {
  name = "${var.prefix}-executionrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Replaces the deprecated aws_iam_role.inline_policy block (removed support is
# planned for a future AWS provider major). Folding both statements into a single
# policy also fixes a latent bug: the previous inline_policy had two `Statement`
# keys in one object, so the logs statement was silently dropped.
resource "aws_iam_role_policy" "execution" {
  name = "${var.prefix}-execution-policy"
  role = aws_iam_role.executionrole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters"]
        Resource = [aws_ssm_parameter.tunneltoken.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.executionrole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
