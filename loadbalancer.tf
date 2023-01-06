resource "aws_lb_target_group" "sre_lb_tg" {
  name     = "sre-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sre_vpc.id

  health_check {
    path                = "/"
    port                = 80
    healthy_threshold   = 10
    unhealthy_threshold = 4
    timeout             = 4
    interval            = 10
    matcher             = "200" # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "sre_lb_tg_attachment" {
  count            = var.main_instance_count
  target_group_arn = aws_lb_target_group.sre_lb_tg.arn
  target_id        = aws_instance.sre_main[count.index].id
  port             = 80
}

resource "aws_lb" "sre_lb" {
  name               = "sre-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sre_alb_sg.id]
  subnets            = aws_subnet.sre_public_subnet.*.id

  # enable_deletion_protection = true

  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.bucket
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = {
    Environment = "production"
  }
}


resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.sre_front_end.arn

  priority     = 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "444"
    }
  }

  condition {
    host_header {
      values = [aws_lb.sre_lb.dns_name]
    }
  }
}



resource "aws_lb_listener" "sre_front_end" {
  load_balancer_arn = aws_lb.sre_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.sre_acm_certificate_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sre_lb_tg.arn
  }
}