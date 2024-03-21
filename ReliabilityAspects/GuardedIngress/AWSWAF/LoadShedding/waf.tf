provider "aws" {
  region = "us-east-2"
}
###
resource "aws_wafv2_regex_pattern_set" "regex_pattern_api" {
  name  = "regex-path-api"
  scope = "REGIONAL"

  regular_expression {
    regex_string = "/login"  #only requests for login path are limited
  }
}

resource "aws_wafv2_web_acl" "waf" {
  name  = "waf"
  scope = "REGIONAL"

  default_action {
    allow {}
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
        limit              = 100

        scope_down_statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.regex_pattern_api.arn

            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "NONE"
            }
          }
        }
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

         scope_down_statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.regex_pattern_api.arn

            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "NONE"
            }
          }
        }
      }
      
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "waf"
    sampled_requests_enabled   = false
  }
}


data "aws_lb" "alb" {
  name = "alb-eks"
}

resource "aws_wafv2_web_acl_association" "WafWebAclAssociation" {
  resource_arn = data.aws_lb.alb.arn       #refer to alb
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}