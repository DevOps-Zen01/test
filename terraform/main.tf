terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 25.0"

  project_id = var.project_id
  name       = "go-hello-cluster"
  region     = var.region
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  ip_range_pods     = "pod-ranges"
  ip_range_services = "service-ranges"

  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = "e2-medium"
      min_count    = 1
      max_count    = 3
    },
  ]
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 6.0"

  project_id   = var.project_id
  network_name = "gke-network"
  
  subnets = [
    {
      subnet_name   = "gke-subnet"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "gke-subnet" = [
      {
        range_name    = "pod-ranges"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "service-ranges"
        ip_cidr_range = "10.2.0.0/16"
      },
    ]
  }
}

output "cluster_name" {
  value = module.gke.name
}