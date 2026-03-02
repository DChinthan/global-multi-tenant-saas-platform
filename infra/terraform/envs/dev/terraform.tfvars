aws_region  = "us-east-1"
project     = "global-mt-saas"
environment = "dev"

cidr_block = "10.10.0.0/16"


# cost safety (OFF by default)
enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false

# sizing knobs
rds_instance_class       = "db.t4g.micro"
opensearch_instance_type = "t3.small.search"