resource "aws_iam_policy" "bq_omni" {
    name = "bq-omni-connection-policy"

    policy = <<-EOF
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "BucketLevelAccess",
                        "Effect": "Allow",
                        "Action": ["s3:ListBucket"],
                        "Resource": ["arn:aws:s3:::${aws_s3_bucket.bq_data.id}"]
                    },
                    {
                        "Sid": "ObjectLevelAccess",
                        "Effect": "Allow",
                        "Action": ["s3:GetObject"],
                        "Resource": [
                            "arn:aws:s3:::${aws_s3_bucket.bq_data.id}",
                            "arn:aws:s3:::${aws_s3_bucket.bq_data.id}/*"
                            ]
                    }
                ]
            }
            EOF
}


resource "aws_iam_role" "bq_omni" {
    name                 = "bq-omni-connection"
    max_session_duration = 43200

    assume_role_policy = <<-EOF
        {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Federated": "accounts.google.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                "accounts.google.com:sub": "${google_bigquery_connection.bq_omni.aws[0].access_role[0].identity}"
                }
            }
            }
        ]
        }
        EOF
}

resource "aws_iam_role_policy_attachment" "bq_omni" {
    role       = aws_iam_role.bq_omni.name
    policy_arn = aws_iam_policy.bq_omni.arn
}


