resource "aws_launch_configuration" "aws_asg_launch" {
  name            = "${var.name}-asg-launch"
  image_id        = "ami-0ea4d4b8dc1e46212"
  instance_type   = var.instance_type
  security_groups = [var.SSH_SG_ID, var.HTTP_HTTPS_SG_ID]
  key_name        = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum -y update
    yum -y install httpd.x86_64
    systemctl start httpd.service
    systemctl enable httpd.service
    echo "DB Endpoint: ${data.terraform_remote_state.rds_remote_data.outputs.rds_instance_address}" > /var/www/html/index.html
    echo "DB Port: ${data.terraform_remote_state.rds_remote_data.outputs.rds_instance_port}" >> /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "aws_asg" {
  name                 = "${var.name}-asg"
  launch_configuration = aws_launch_configuration.aws_asg_launch.name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_subnets
  target_group_arns    = var.target_group_arns
  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.name}-Terraform_Instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "${var.name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.aws_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "${var.name}-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.aws_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "${var.name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.aws_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.name}-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.aws_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in_policy.arn]
}
