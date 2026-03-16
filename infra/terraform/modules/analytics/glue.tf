resource "aws_glue_catalog_database" "analytics" {
  count = var.enable_glue_crawler ? 1 : 0

  name = local.glue_database_name

  tags = local.common_tags
}

resource "aws_glue_crawler" "analytics" {
  count = var.enable_glue_crawler ? 1 : 0

  database_name = aws_glue_catalog_database.analytics[0].name
  name          = "${local.name_prefix}-analytics-crawler"
  role          = aws_iam_role.glue_crawler[0].arn

  s3_target {
    path = "s3://${var.analytics_bucket_name}/${var.crawler_s3_target_path}"
  }

  schedule = var.crawler_schedule

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = local.common_tags
}