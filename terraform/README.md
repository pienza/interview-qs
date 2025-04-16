create a terraform file for AWS that has the following components:
1. A public endpoint called https://training.inflection.io on AWS application gateway. 
2. An EKS cluster in us-east-1 which hosts a java application that needs 4gb of RAM, 2 cores and 32gb of disk each. This cluster needs to have sidecar installations of datadog agent for monitoring
3. An RDS instance that is highly available  across multiple data centers. This RDS should support at least 200GB of data on disk and should have backups enabled every 6 hours
4. Cloudwatch enabled for issues in application gateway, EKS and RDS