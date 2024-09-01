terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    tls = {
      source = "hashicorp/tls"
    }
   local =  {
    source = "hashicorp/local"
  }
  kubernetes = {
    source = "hashicorp/kubernetes"
   }
  kubectl = {
    source  = "gavinbunney/kubectl"
    version = ">= 1.7.0"
  }
 }
}

provider "yandex" {
    zone = "ru-central1-a"
}


provider "kubernetes" {
     host                   = data.yandex_kubernetes_cluster.otus-cluster.master.0.external_v4_endpoint
     cluster_ca_certificate = data.yandex_kubernetes_cluster.otus-cluster.master.0.cluster_ca_certificate
     token                  = data.yandex_client_config.client.iam_token
}


provider "helm" {
   kubernetes {
     host                   = data.yandex_kubernetes_cluster.otus-cluster.master.0.external_v4_endpoint
     cluster_ca_certificate = data.yandex_kubernetes_cluster.otus-cluster.master.0.cluster_ca_certificate
     token                  = data.yandex_client_config.client.iam_token
   }
}

provider "kubectl" {
     host                   = data.yandex_kubernetes_cluster.otus-cluster.master.0.external_v4_endpoint
     cluster_ca_certificate = data.yandex_kubernetes_cluster.otus-cluster.master.0.cluster_ca_certificate
     token                  = data.yandex_client_config.client.iam_token
     load_config_file       = false
}
