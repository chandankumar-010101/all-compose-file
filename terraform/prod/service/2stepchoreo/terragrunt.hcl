include "root" {
  path = find_in_parent_folders()
}
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir()}//_modules/aws/ecs-service"
}

dependencies {
  paths = ["../../network/vpc", "../../network/ecs-cluster/backend", "../../network/elb/backend", "../../network/sg/ecs-container"]
}

dependency "vpc" {
  config_path = "../../network/vpc"
}
dependency "ecs_cluster" {
  config_path = "../../network/ecs-cluster/backend"
}
dependency "alb" {
  config_path = "../../network/elb/backend"
}
dependency "sg" {
  config_path = "../../network/sg/ecs-container"
}

inputs = {
  service_name      = "2stepchoreo"
  vpc_id            = dependency.vpc.outputs.vpc_id
  cluster_arn       = dependency.ecs_cluster.outputs.ecs_cluster_arn
  security_group_id = dependency.sg.outputs.security_group_id
  subnets           = dependency.vpc.outputs.private_subnets
  alb_listener_arn  = dependency.alb.outputs.https_listener_arns[0]
  alb_listener_rules = [
    {
      conditions = [{
        path_patterns = ["/choreo", "/it_initialstep", "/it_step", "/message_service", "/learner_data"]
      }]
    }
  ]
  health_check_matcher = "404"
  desired_count        = 0
  task_cpu             = 512
  task_memory          = 4096
  container_port       = 5000

  environment = {
    PROD_DB_NAME                = "pangea_prod_learner"
    PROD_USER                   = "pangea_prod_admin"
    PROD_PORT                   = "5432"
  }
  secrets = {
    PROD_HOST     = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/2stepchoreo/learner_db_host"
    PROD_PASSWORD = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/2stepchoreo/learner_db_pass"
  }

}