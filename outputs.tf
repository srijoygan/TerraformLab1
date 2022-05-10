output "lb_endpoint" {
  value = "http://${aws_lb.TestLB.dns_name}"
}

output "application_endpoint" {
  value = "http://${aws_lb.TestLB.dns_name}/index.html"
}

output "asg_name" {
  value = aws_autoscaling_group.TestASG.name
}
