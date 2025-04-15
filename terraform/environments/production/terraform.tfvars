environment = "production"
vpc_cidr    = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

eks_cluster_name          = "training-cluster"
eks_node_group_instance_type = "t3.medium"

rds_instance_class        = "db.t3.large"
rds_allocated_storage     = 200
rds_backup_retention_period = 7
rds_backup_window         = "03:00-09:00"
rds_maintenance_window    = "Mon:00:00-Mon:03:00"

db_name     = "training_db"
db_username = "training_user"
# TODO: use AWS secrets manager to get these values
db_password = "your_secure_password_here"  # Replace with a secure password

route53_zone_id = "your_route53_zone_id"  # Replace with your Route53 zone ID
sns_topic_arn   = "your_sns_topic_arn"    # Replace with your SNS topic ARN
datadog_api_key = "your_datadog_api_key"  # Replace with your Datadog API key 