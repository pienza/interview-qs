module "vpc" {
  source = "../../modules/vpc"

  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "eks" {
  source = "../../modules/eks"

  environment                = var.environment
  eks_cluster_name          = var.eks_cluster_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  eks_node_group_instance_type = var.eks_node_group_instance_type
  datadog_api_key           = var.datadog_api_key
}

module "rds" {
  source = "../../modules/rds"

  environment                = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_backup_retention_period = var.rds_backup_retention_period
  rds_backup_window         = var.rds_backup_window
  rds_maintenance_window    = var.rds_maintenance_window
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  allowed_security_groups   = [module.eks.cluster_security_group_id]
}

module "application_gateway" {
  source = "../../modules/application_gateway"

  environment      = var.environment
  vpc_id          = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  route53_zone_id = var.route53_zone_id
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors ALB 5XX errors"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = module.application_gateway.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "${var.environment}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors RDS CPU utilization"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu_utilization" {
  alarm_name          = "${var.environment}-eks-node-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EKS node CPU utilization"
  alarm_actions      = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = module.eks.node_group_name
  }
} 