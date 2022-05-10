data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20220426.0-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "3.14.0"

  name                  = "main-vpc"
  cidr                  = "10.0.0.0/16"

  azs                   = data.aws_availability_zones.available.names
  public_subnets        = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
  enable_dns_hostnames  = true
  enable_dns_support    = true

}

resource "aws_launch_configuration" "TestLC" {
  name_prefix = "Lab-Instance-"
  image_id = data.aws_ami.amazon-linux.id
  instance_type = "t2.nano"
  key_name = "CloudformationKeyPair"
  user_data = file("./user_data.sh")
  security_groups = [aws_security_group.TestInstanceSG.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "TestASG" {
  min_size = 1
  max_size = 3
  desired_capacity = 2
  launch_configuration = aws_launch_configuration.TestLC.name
  vpc_zone_identifier = module.vpc.public_subnets
}

resource "aws_lb_listener" "TestListener"{
  load_balancer_arn = aws_lb.TestLB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.TestTG.arn
  }
}

resource "aws_lb" "TestLB" {
  name              = "Lab-App-Load-Balancer"
  internal          = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.TestLoadBalanceSG.id]
  subnets           = module.vpc.public_subnets
}

resource "aws_lb_target_group" "TestTG" {
  name = "LabTargetGroup"
  port = "80"
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
}

resource "aws_autoscaling_attachment" "TestAutoScalingAttachment" {
  autoscaling_group_name = aws_autoscaling_group.TestASG.id
  lb_target_group_arn = aws_lb_target_group.TestTG.arn
}



resource "aws_security_group" "TestInstanceSG" {
  name = "LAB-Instance-SecurityGroup"
  ingress{
  from_port = 80
  to_port = 80
  protocol = "tcp"
  security_groups = [aws_security_group.TestLoadBalanceSG.id]
  }
  ingress{
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_groups = [aws_security_group.TestLoadBalanceSG.id]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.TestLoadBalanceSG.id]
  }
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "TestLoadBalanceSG" {
  name = "LAB-LoadBalancer-SecurityGroup"
  ingress{
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  vpc_id = module.vpc.vpc_id
}
