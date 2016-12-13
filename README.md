

# Maintenance

A AWS lambda will be create to run some maintenance everytime a instance is 
terminated using a lifecycle hook

## AWS Lambda

The lambda is configured to access the subnet of the vpc to be able to 
communicate with the Mesos Master.

## Maintenance python Code

So the maintenance take multiple step:
* Gather ip and dns for a specified instanc
* First enable maintenance in Mesos Master for the host, while removing 
maintenance which is over already.
* Remove instance from all ELB is attached on.
