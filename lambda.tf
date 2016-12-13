resource "aws_iam_role" "maintenance" {
  name = "${var.cluster_name}_maintenance"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "maintenance" {
  name = "${var.cluster_name}_maintenance"
  role = "${aws_iam_role.maintenance.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Action": [
				"autoscaling:CompleteLifecycleAction",
				"ec2:DescribeInstances",
				"elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
				"elasticloadbalancing:DescribeLoadBalancers",
				"ec2:CreateNetworkInterface",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DeleteNetworkInterface"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "maintenance" {
  filename      = "${path.module}/src/build/lambda-mesos_maintenance.zip"
  function_name = "${var.cluster_name}_mesos_maintenance"
  role          = "${aws_iam_role.maintenance.arn}"
  handler       = "${var.mesos_maintenance_handler}"
  runtime       = "python2.7"
  timeout       = 60
  memory_size   = 128

  depends_on = ["null_resource.build"]

  vpc_config {
    subnet_ids         = ["${split(",",var.subnets)}"]
    security_group_ids = ["${var.sg}"]
  }
}

resource "aws_lambda_permission" "maintenance" {
  statement_id  = "${var.cluster_name}_maintenance"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.maintenance.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.maintenance.arn}"
}

resource "aws_sns_topic" "maintenance" {
  name = "${var.cluster_name}_maintenance"
}

resource "aws_sns_topic_subscription" "maintenance" {
  topic_arn = "${aws_sns_topic.maintenance.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.maintenance.arn}"
}
