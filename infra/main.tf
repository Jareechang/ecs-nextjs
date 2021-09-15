provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

locals {
  # Target port to expose
  target_port = 3000
}

#### Networking (subnets, igw, nat gw, rt etc)
module "networking" {
    source = "github.com/Jareechang/tf-modules//networking?ref=v1.0.1"
    env = var.env
    project_id = var.project_id
    subnet_public_cidrblock = [
        "10.0.1.0/24",
        "10.0.2.0/24"
    ]
    subnet_private_cidrblock = [
        "10.0.11.0/24",
        "10.0.22.0/24"
    ]
    azs = ["us-east-1a", "us-east-1b"]
}

#### Security groups

resource "aws_security_group" "alb_ecs_sg" {
    vpc_id = module.networking.vpc_id

    ## Allow inbound on port 80 from internet (all traffic)
    ingress {
        protocol         = "tcp"
        from_port        = 80
        to_port          = 80
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ## Allow outbound to ecs instances in private subnet
    egress {
        protocol    = "tcp"
        from_port   = local.target_port
        to_port     = local.target_port
        cidr_blocks = module.networking.private_subnets[*].cidr_block
    }
}

resource "aws_security_group" "ecs_sg" {
    vpc_id = module.networking.vpc_id
    ingress {
        protocol         = "tcp"
        from_port        = local.target_port
        to_port          = local.target_port
        security_groups  = [aws_security_group.alb_ecs_sg.id]
    }

    ## Allow ECS service to reach out to internet (download packages, pull images etc)
    egress {
        protocol         = -1
        from_port        = 0
        to_port          = 0
        cidr_blocks      = ["0.0.0.0/0"]
    }
}

module "ecs_tg_blue" {
    project_id          = "${var.project_id}-blue"
    source              = "github.com/Jareechang/tf-modules//alb?ref=v1.0.2"
    create_target_group = true
    port                = local.target_port
    protocol            = "HTTP"
    target_type         = "ip"
    vpc_id              = module.networking.vpc_id
}

module "ecs_tg_green" {
    project_id          = "${var.project_id}-green"
    source              = "github.com/Jareechang/tf-modules//alb?ref=v1.0.2"
    create_target_group = true
    port                = local.target_port
    protocol            = "HTTP"
    target_type         = "ip"
    vpc_id              = module.networking.vpc_id
}

module "alb" {
    source              = "github.com/Jareechang/tf-modules//alb?ref=v1.0.2"
    create_alb         = true
    enable_https       = false
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb_ecs_sg.id]
    subnets            = module.networking.public_subnets[*].id
    target_group       = module.ecs_tg_blue.tg.arn
}

resource "aws_ecs_cluster" "web_cluster_node" {
    name = "web-cluster-node"
    setting {
        name  = "containerInsights"
        value = "enabled"
    }
}

resource "aws_ecs_service" "web_service" {
    name            = "web-nodejs"
    cluster         = aws_ecs_cluster.web_cluster_node.id
    task_definition = aws_ecs_task_definition.nodejs.arn
    desired_count   = 2
    launch_type = "FARGATE"

    load_balancer {
        target_group_arn = module.ecs_tg_blue.tg.arn
        container_name   = "node-app-image"
        container_port   = 3000
    }

    network_configuration {
        subnets         = module.networking.private_subnets[*].id
        security_groups = [aws_security_group.ecs_sg.id]
    }

    deployment_controller {
      type = "CODE_DEPLOY"
    }

    tags = {
        Name = "${var.project_id}-${var.env}-ecs-service"
    }

    depends_on = [
        module.alb.lb,
        module.ecs_tg_blue.tg
    ]
}

resource "aws_ecr_repository" "main" {
    name                 = "web/${var.project_id}/test"
    image_tag_mutability = "MUTABLE"
}

### Logging
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/aws/ecs/${var.project_id}-${var.env}"
  retention_in_days = 1
}

## Investigate into LB https://particule.io/en/blog/cicd-ecr-ecs/
resource "aws_ecs_task_definition" "nodejs" {
    family                   = "task-definition-node"
    execution_role_arn       = module.ecs_roles.ecs_execution_role_arn
    task_role_arn            = module.ecs_roles.ecs_task_role_arn

    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = 512
    memory                   = 1024
    container_definitions    = file("task-definitions/service.base.json")
}

resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "_%@"
}

#### Secrets
resource "aws_kms_key" "default" {
    description             = "Default encryption key (symmetric)"
    deletion_window_in_days = 10
}

resource "aws_ssm_parameter" "db_password" {
    name        = "/web/${var.project_id}/database/secret"
    description = "Datbase password"
    type        = "SecureString"
    key_id      = aws_kms_key.default.key_id
    value       = random_password.db.result
}

data "aws_caller_identity" "current" {}

## CI/CD user role for managing pipeline for AWS ECR resources
module "ecr_ecs_ci_user" {
    source            = "github.com/Jareechang/tf-modules//iam/ecr?ref=v1.0.7"
    env               = var.env
    project_id        = var.project_id
    create_ci_user    = true
    ecr_resource_arns = [
        "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/web/${var.project_id}",
        "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/web/${var.project_id}/*"
    ]

    other_iam_statements = {
      codedeploy = {
        actions = [
          "codedeploy:GetDeploymentGroup",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        effect = "Allow"
        resources = [
          "*"
          #aws_codedeploy_app.node_app.arn,
          #aws_codedeploy_deployment_group.node_app.arn,
          #"arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        ]
      }
    }
}

## ECS Execution and Task roles
module "ecs_roles" {
    source                    = "github.com/Jareechang/tf-modules//iam/ecs?ref=v1.0.7"
    create_ecs_execution_role = true
    create_ecs_task_role      = true

    # Extend baseline policy statements
    ecs_execution_other_iam_statements = {
        ssm = {
            actions = [
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParametersByPath"
            ]
            effect = "Allow"
            resources = [
                "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web/${var.project_id}/*"
            ]
        }
        kms = {
            actions = [
                "kms:Decrypt"
            ]
            effect = "Allow"
            resources = [
                aws_kms_key.default.arn
            ]
        }
    }
}

data "template_file" "task_def_generated" {
  template = "${file("./task-definitions/service.json.tpl")}"
  vars = {
      ecs_execution_role  = module.ecs_roles.ecs_execution_role_arn
      ssm_db_password_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${aws_ssm_parameter.db_password.name}"
  }
}

resource "local_file" "output_task_def" {
  content         = data.template_file.task_def_generated.rendered
  file_permission = "644"
  filename        = "./task-definitions/service.latest.json"
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [
        "codedeploy.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "CodeDeployRole${var.project_id}"
  description        = "CodeDeployRole for ${var.project_id} in ${var.env}"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_codedeploy_app" "node_app" {
  compute_platform = "ECS"
  name             = "${var.project_id}-${var.env}-nextjs"
}

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "MyAppAccessCount"
  pattern        = "[Error]"
  log_group_name = aws_cloudwatch_log_group.ecs.name
  metric_transformation {
    name      = "AppLogErrors-Ecs-${var.project}"
    namespace = "${var.env}"
    value     = "1"
  }
}


module "http_error_alarm" {
    source             = "github.com/Jareechang/tf-modules//cloudwatch/alarms/alb-http-errors?ref=v1.0.8"
    evaluation_periods = "2"
    threshold          = "10"
    arn_suffix         = module.alb.lb.arn_suffix
    project_id         = var.project_id
}

resource "aws_codedeploy_deployment_config" "custom_canary" {
  deployment_config_name = "EcsCanary25Percent20Minutes"
  compute_platform       = "ECS"
  traffic_routing_config {
    type = "TimeBasedCanary"
    time_based_canary {
      interval   = 10
      percentage = 25
    }
  }
}

resource "aws_codedeploy_deployment_group" "node_app" {
  app_name               = aws_codedeploy_app.node_app.name
  deployment_config_name = aws_codedeploy_deployment_config.custom_canary.id
  deployment_group_name  = "${var.project_id}-${var.env}-nextjs-deploy-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    alarms  = [
      module.http_error_alarm.name,
      aws_cloudwatch_log_metric_filter.app_errors.name
    ]
    enabled = true
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.web_cluster_node.name
    service_name = aws_ecs_service.web_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [module.alb.http_listener.arn]
      }

      target_group {
        name = module.ecs_tg_blue.tg.name
      }

      target_group {
        name = module.ecs_tg_green.tg.name
      }
    }
  }
}
