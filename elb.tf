resource "aws_elb" "skill_check_elb" {
  name = "skill-check-elb"

  subnets = [
    "${aws_subnet.public_1a.id}",
  ]

  security_groups = [
    "${aws_security_group.internal.id}",
    "${aws_security_group.http.id}",
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Environment = "Development"
    Name        = "skill-check-elb"
    Role        = "ELB"
  }
}