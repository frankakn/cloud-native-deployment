provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "default" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

resource "kubernetes_horizontal_pod_autoscaler" "recommender-hpa" {
  metadata {
    name = "terraform-recommender-hpa"
    namespace = "teastore-namespace" 
  }

  spec {
    max_replicas = 10
    min_replicas = 1
    target_cpu_utilization_percentage = 60 # default is 80
    scale_target_ref {
      kind = "Deployment"
      name = "teastore-recommender"
      api_version = "apps/v1" 
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "auth-hpa" {
  metadata {
    name = "terraform-auth-hpa"
    namespace = "teastore-namespace" 
  }

  spec {
    max_replicas = 10
    min_replicas = 1
    target_cpu_utilization_percentage = 60 # default is 80
    scale_target_ref {
      kind = "Deployment"
      name = "teastore-auth"
      api_version = "apps/v1" 
    }
  }
}
resource "kubernetes_horizontal_pod_autoscaler" "image-hpa" {
  metadata {
    name = "terraform-image-hpa"
    namespace = "teastore-namespace" 
  }

  spec {
    max_replicas = 10
    min_replicas = 1
    target_cpu_utilization_percentage = 60 # default is 80
    scale_target_ref {
      kind = "Deployment"
      name = "teastore-image"
      api_version = "apps/v1" 
    }
  }
}
resource "kubernetes_horizontal_pod_autoscaler" "persistence-hpa" {
  metadata {
    name = "terraform-persistence-hpa"
    namespace = "teastore-namespace" 
  }

  spec {
    max_replicas = 10
    min_replicas = 1
    target_cpu_utilization_percentage = 60 # default is 80
    scale_target_ref {
      kind = "Deployment"
      name = "teastore-persistence"
      api_version = "apps/v1" 
    }
  }
}
resource "kubernetes_horizontal_pod_autoscaler" "webui-hpa" {
  metadata {
    name = "terraform-webui-hpa"
    namespace = "teastore-namespace" 
  }

  spec {
    max_replicas = 10
    min_replicas = 1
    target_cpu_utilization_percentage = 60 # default is 80

    scale_target_ref {
      kind = "Deployment"
      name = "teastore-webui"
      api_version = "apps/v1" 

    }
  }
}