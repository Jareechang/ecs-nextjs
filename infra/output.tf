output "aws_iam_access_id" {
    value = module.ecr_ecs_ci_user.aws_iam_access_id
}

output "aws_iam_access_key" {
    value = module.ecr_ecs_ci_user.aws_iam_access_key
}

output "ecr_repo_url" {
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}


output "ecr_repo_path" {
    value = aws_ecr_repository.main.name
}

output "ecs_task_role_arn" {
    value = module.ecs_roles.ecs_task_role_arn
}

output "ecs_execution_role_arn" {
    value = module.ecs_roles.ecs_execution_role_arn
}

output "aws_ssm_db_password_path" {
    value = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${aws_ssm_parameter.db_password.name}"
}
