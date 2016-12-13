#global
variable "cluster_name" {
  default     = ""
  description = "Name of the cluster (must be uniq per region)"
}

variable "mesos_maintenance_handler" {
  default     = "mesos_maintenance.lambda_handler"
  description = "name of the handle witht the form <module>.<function_handler>"
}

variable "asg_agent_name" {
  default     = ""
  description = "Name of the AutoScalingGroup to hook"
}

variable "mesos_master_endpoint" {
  default     = "http://mesos-master/"
  description = "Endpoint of the Mesos Master"
}

variable "sg" {
  default     = ""
  description = "Security Groups for lambda"
}

variable "subnets" {
  default     = ""
  description = "subnets for lambda"
}
