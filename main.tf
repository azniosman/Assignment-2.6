resource "aws_instance" "my_ec2" {
  ami           = "ami-0005e0cfe09cc9050" 
  instance_type = "t2.micro"
  subnet_id     = "subnet-0b64b42cb7c4e94e5"
  key_name      = "azni"

  iam_instance_profile = aws_iam_instance_profile.ec2_dynamodb_profile.name

  tags = {
    Name = "Azni_DynamoDB_Access_Instance"
  }
}

resource "aws_iam_role" "ec2_dynamodb_role" {
  name = "EC2DynamoDBAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      },
    ]
  })
}

resource "aws_iam_policy" "ec2_dynamodb_policy" {
  name        = "EC2DynamoDBAccessPolicy"
  description = "Policy to allow EC2 instance access to DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ],
        Effect   = "Allow",
        Resource = [
          aws_dynamodb_table.my_table.arn,
          "${aws_dynamodb_table.my_table.arn}/index/*" # If you have Global Secondary Indexes
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_dynamodb_policy_attachment" {
  role       = aws_iam_role.ec2_dynamodb_role.name
  policy_arn = aws_iam_policy.ec2_dynamodb_policy.arn
}

resource "aws_iam_instance_profile" "ec2_dynamodb_profile" {
  name = "EC2DynamoDBInstanceProfile"
  role = aws_iam_role.ec2_dynamodb_role.name
}

resource "aws_dynamodb_table" "my_table" {
  name           = "AzniSampleTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "title"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "title"
    type = "S"
  }

  tags = {
    Environment = "Dev"
  }
}

output "ec2_instance_id" {
  value = aws_instance.my_ec2.id
}

output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.my_table.arn
}
