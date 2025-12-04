variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ASG"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

# ALB + TG + Listener
resource "aws_lb" "aman_tiwari_alb" {
  name               = "aman-tiwari-ALB"  
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.aman-tiwari-private-subnet1.id
  security_groups    = [aws_security_group.alb_sg.id]

  tags = { Name = "aman-tiwari-ALB" }
}

resource "aws_lb_target_group" "aman_tg" {
  name        = "aman-tiwari-target-group" 
  port        = 80
  protocol    = "HTTP"
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  target_type = "instance"

  health_check {
    path     = "/"
    protocol = "HTTP"
    interval = 30
  }

  tags = { Name = "aman-tiwari-target-group" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.aman_tiwari_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aman_tg.arn
  }
}


# AWS Launch Instance

resource "aws_launch_template" "aman_template" {
  name_prefix   = "aman-template"          
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "<h1>Served by ASG instance</h1>" > /var/www/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "aman-tiwari-asg-instance"
    }
  }
}


# Auto Scaling Group

resource "aws_autoscaling_group" "aman_autoscaling" {
  name                      = "aman-tiwari-autoscaling"  
  desired_capacity          = var.desired_capacity
  max_size                  = 3
  min_size                  = 1

  launch_template {
    id      = aws_launch_template.aman_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [
    aws_lb_target_group.aman_tg.arn
  ]

  health_check_type        = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "aman-tiwari-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb_listener.http]
}

