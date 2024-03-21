provider "aws" {
  region = "us-east-2"
}

resource "aws_wafv2_web_acl" "WafWebAcl" {
  name  = "wafv2-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_RateLimit"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {

      rate_based_statement {
        aggregate_key_type = "IP" 
        limit              = 100 #lowest possible limit - for easy testing purposes

      }
      
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitCombined"
    priority = 2

    action {
      block {}
    }

    statement {

      rate_based_statement {
        aggregate_key_type = "FORWARDED_IP" 
        limit              = 200 
        forwarded_ip_config {
        header_name = "X-Forwarded-For"
        fallback_behavior = "MATCH"
        }
      }
      
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }
  
}

resource "aws_cloudwatch_log_group" "WafWebAclLoggroup" {
  name              = "aws-waf-logs-wafv2-web-acl"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "WafWebAclLogging" {
  log_destination_configs = [aws_cloudwatch_log_group.WafWebAclLoggroup.arn]
  resource_arn            = aws_wafv2_web_acl.WafWebAcl.arn
  depends_on = [
    aws_wafv2_web_acl.WafWebAcl,
    aws_cloudwatch_log_group.WafWebAclLoggroup
  ]
}

data "aws_lb" "alb" {
  name = "alb-eks"
}

resource "aws_wafv2_web_acl_association" "WafWebAclAssociation" {
  resource_arn = data.aws_lb.alb.arn      # refers to ALB
  web_acl_arn  = aws_wafv2_web_acl.WafWebAcl.arn
  depends_on = [
    aws_wafv2_web_acl.WafWebAcl,
    aws_cloudwatch_log_group.WafWebAclLoggroup
  ]
}