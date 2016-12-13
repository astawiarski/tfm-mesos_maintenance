# Input Variable

## Global
* cluster_name: Name of the cluster (must be uniq per region)

## Lambda 
* mesos_maintenance_handler: name of the handle witht the form 
<module>.<function_handler>

## Mesos
* mesos_master_endpoint: Endpoint of the Mesos Master

## AWS
* asg_agent_name: Name of the AutoScalingGroup to hook
* sg: Security Groups for lambda
* subnets: subnets for lambda
