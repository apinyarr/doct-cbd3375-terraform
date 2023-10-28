resource "aws_iam_policy" "data_ml_policy" {
  name        = "data_ml_policy"
  description = "data_ml_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:CopyObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::dataset-3375-2",
        "arn:aws:s3:::dataset-3375-2/*"
      ]
    }
  ]
}
EOF
}

# resource "aws_iam_role" "data_ml_role" {
#   name = "data-ml-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": [
#           "ec2.amazonaws.com"
#         ]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "terraform_ec2_iam_policy" {
#   role = "${aws_iam_role.data_ml_role.id}"
#   policy_arn = "${aws_iam_policy.data_ml_policy.arn}"
# }