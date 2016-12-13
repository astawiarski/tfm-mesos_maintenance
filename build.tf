resource "null_resource" "build" {
  # Changes to any instance of the cluster requires re-provisioning
  provisioner "local-exec" "build-lambda" {
    command = "cd ${path.module}/src/ && make mesos_maintenance"
  }
}
