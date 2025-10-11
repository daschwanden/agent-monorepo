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

variable "project_id" {
  description = "Google Cloud Project Identifier"
}

variable "region" {
  description = "region"
  default     = "us-central1"
}

variable "zone" {
  description = "zone"
  default     = "us-central1-b"
}

variable "agent_pool_num_nodes" {
  description = "number of GRR nodes"
  default     = 1
}

variable "nodepool" {
  description = "Agents nodepool"
  default     = "agent"
}

variable "nodepool_machine_type" {
  description = "Agent nodepool machine type"
  default     = "n2-standard-4"
}
