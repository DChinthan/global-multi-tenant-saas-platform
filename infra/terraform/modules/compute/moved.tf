# These moved blocks remap the pre-Phase-1 singular resource addresses onto
# their for_each equivalents keyed by "app" (the var.services entry for
# app1-python — see envs/*/main.tf). Without them, Terraform would see the
# rename as "destroy the old resource, create a new one with the same name",
# which either errors (AWS rejects a duplicate name) or causes real downtime.
# With them, plan should show these resources as unchanged / moved only.

moved {
  from = aws_ecr_repository.app
  to   = aws_ecr_repository.this["app"]
}

moved {
  from = aws_ecr_lifecycle_policy.app
  to   = aws_ecr_lifecycle_policy.this["app"]
}

moved {
  from = aws_ecs_task_definition.app
  to   = aws_ecs_task_definition.this["app"]
}

moved {
  from = aws_ecs_service.app
  to   = aws_ecs_service.this["app"]
}

moved {
  from = aws_lb_target_group.app
  to   = aws_lb_target_group.this["app"]
}

moved {
  from = aws_appautoscaling_target.ecs
  to   = aws_appautoscaling_target.this["app"]
}

moved {
  from = aws_appautoscaling_policy.ecs_cpu
  to   = aws_appautoscaling_policy.this["app"]
}
