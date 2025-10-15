/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

##########################################################################
# Enable the required Cloud APIs
##########################################################################
resource "google_project_service" "aiplatform" {
  project = var.project_id
  service = "aiplatform.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "bigquery" {
  project = var.project_id
  service = "bigquery.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "cloudtrace" {
  project = var.project_id
  service = "cloudtrace.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "serviceusage" {
  project = var.project_id
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = false
}

##########################################################################
# Set up the VPC and subnet
##########################################################################
resource "google_compute_network" "agent_vpc" {
  name                    = "agent-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "agent_subnet" {
  name          = "agent-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.agent_vpc.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# allow access from health check ranges
resource "google_compute_firewall" "allow_l7_xlb_fw_hc" {
  name          = "allow-l7-xlb-fw-hc"
  direction     = "INGRESS"
  network       = google_compute_network.agent_vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}

# allow ssh ingress from iap
resource "google_compute_firewall" "allow_ssh_ingress_from_iap" {
  name          = "allow-ssh-ingress-from-iap"
  direction     = "INGRESS"
  network       = google_compute_network.agent_vpc.id
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

##########################################################################
# Set up the Artifact Registry 
##########################################################################
resource "google_artifact_registry_repository" "artifact_registry" {
  location      = var.region
  repository_id = "agents"
  description   = "docker repository"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "agent_artifact_writer" {
  location = google_artifact_registry_repository.artifact_registry.location
  repository = google_artifact_registry_repository.artifact_registry.name
  role = "roles/artifactregistry.writer"
  member      = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/agents/sa/agents-sa"
  depends_on = [
    google_container_cluster.agent_cluster
  ]
}

resource "google_artifact_registry_repository_iam_member" "agent_artifact_reader" {
  location = google_artifact_registry_repository.artifact_registry.location
  repository = google_artifact_registry_repository.artifact_registry.name
  role = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

##########################################################################
# Set up the NAT Router
##########################################################################
resource "google_compute_router" "agent_router" {
  name    = "agent-router"
  region  = var.region
  network = google_compute_network.agent_vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "agent_router_nat" {
  name                               = "agent-router-nat"
  router                             = google_compute_router.agent_router.name
  region                             = google_compute_router.agent_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

###########################################################################
# Set up the GKE cluster
##########################################################################
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.33."
}

resource "google_container_cluster" "agent_cluster" {
  name     = "agent-cluster"
  location = var.zone

  initial_node_count = 1

  network    = google_compute_network.agent_vpc.id
  subnetwork = google_compute_subnetwork.agent_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = google_compute_subnetwork.agent_subnet.secondary_ip_range.0.range_name
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  node_config {
    service_account = data.google_compute_default_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = var.nodepool_machine_type
    tags         = ["agent-pool-node", "allow-health-check"]
    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  monitoring_config {
    managed_prometheus {
      enabled = true
    }

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  }

  private_cluster_config {
    enable_private_nodes = true
  }

  datapath_provider = "ADVANCED_DATAPATH"

  enable_shielded_nodes = true

  deletion_protection = false
}

resource "google_bigquery_dataset" "logs" {
  project       = var.project_id
  dataset_id    = "logs"
  friendly_name = "agent logs"
  location      = var.region
}

resource "google_bigquery_dataset" "telemetry" {
  project       = var.project_id
  dataset_id    = "telemetry"
  friendly_name = "agent telemetry"
  location      = var.region
}

resource "google_bigquery_dataset" "audit" {
  project       = var.project_id
  dataset_id    = "audit"
  friendly_name = "agent audit logs"
  location      = var.region
}


resource "google_logging_project_sink" "logs" {
  project                = var.project_id
  name                   = "logs"
  filter                 = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"agents\""
  destination            = "bigquery.googleapis.com/${google_bigquery_dataset.logs.id}"
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}
