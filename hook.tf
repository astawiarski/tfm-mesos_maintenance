resource "aws_iam_role" "maintenance_hook" {
  name = "${var.cluster_name}_maintenance_hook"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "maintenance_hook" {
  name = "${var.cluster_name}_maintenance_hook"
  role = "${aws_iam_role.maintenance_hook.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_autoscaling_lifecycle_hook" "maintenance_hook" {
  name                    = "${var.cluster_name}_maintenance_hook"
  autoscaling_group_name  = "${var.asg_agent_name}"
  default_result          = "CONTINUE"
  heartbeat_timeout       = 400
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_metadata   = "${var.mesos_master_endpoint}"
  notification_target_arn = "${aws_sns_topic.maintenance.arn}"
  role_arn                = "${aws_iam_role.maintenance_hook.arn}"
}
