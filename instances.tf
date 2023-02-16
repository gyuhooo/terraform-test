# Launch configuration
resource "aws_launch_configuration" "skill_check" {
  name_prefix                 = "skill-check-"
  image_id                    = "${var.ami}"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.skill-check-key.id}"
  security_groups             = ["${aws_security_group.internal.id}"]
  associate_public_ip_address = false

  user_data = "${base64encode(file("user-data.sh"))}"

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "skill_check" {
  name                      = "skill-check"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.skill_check.id}"
  vpc_zone_identifier       = ["${aws_subnet.private_1a.id}"]
  load_balancers            = ["${aws_elb.skill_check_elb.name}"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "skill-check-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Initialized"
    value               = "false"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "skill_check_scale_out" {
  name                   = "Instance-ScaleOut-CPU-High"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.skill_check.name}"
}

resource "aws_cloudwatch_metric_alarm" "skill_check_high" {
  alarm_name          = "skill-check-CPU-Utilization-High-30"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.skill_check.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.skill_check_scale_out.arn}"]
}

resource "aws_autoscaling_policy" "skill_check_scale_in" {
  name                   = "Instance-ScaleIn-CPU-Low"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.skill_check.name}"
}

resource "aws_cloudwatch_metric_alarm" "skill_check_low" {
  alarm_name          = "skill-check-CPU-Utilization-Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.1"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.skill_check.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.skill_check_scale_in.arn}"]
}