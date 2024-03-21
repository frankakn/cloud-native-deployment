
variable "cpu_utilization" {
  type        = string
  default = 40
  description = "Average CPU utilization that the cluster autscaler targets."
}

variable "autoscaling_group_1" {
  type        = string
  default = "eks-node-group-2-20231001092444907400000019-7cc57546-f83d-5acb-40b7-315b4b59ab7d" # Adjust according to the created autoscaling group
  description = "Name of the first autoscaling group."
}

variable "autoscaling_group_2" {
  type        = string
  default = "eks-node-group-1-2023100109244490740000001b-22c57546-f83c-3d6b-46ee-9f3be7ac500b" # adjust according to the created autoscaling group
  description = "Name of the second autoscaling group."
}


variable "ALBRequestCountTargetValue" {
  type        = string
  default = 100
  description = "The optimal average request count per instance during any one-minute interval"
}
