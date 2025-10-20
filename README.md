# AI Agent Monorepo

## Introduction
This repo contains AI Agents in a [monoreop](https://en.wikipedia.org/wiki/Monorepo) showcasing a starter pack setup using [ADK](https://google.github.io/adk-docs/) and [A2A](https://a2a-protocol.org/latest/).

Note that the Agent sample code contained in this repo is for illustrative purposes only and not intended to be used in production.

Key items to point out:
* The repo proposes a directory structure for a [monorepo]([https](https://en.wikipedia.org/wiki/Monorepo)) so all Agents could be managed in a central location.
* The repo contains sample code for two agents:
  - the [Coordinator/Root Agent](./agent-host) that offers a chat UI to interact with, and
  - the [Remote Agent](./agent-prime) to showcase the A2A features.
* The repo ships with a [Docker Compose file](./docker-compose.yaml) to run the Agents in a local development environment.
  - Read more below on how to develop/test the Agents locally on [Docker Compose](https://docs.docker.com/compose/).
* Alternatively, you can also run the Agents on [minikube](https://minikube.sigs.k8s.io/) using the provided [helm](https://helm.sh/) Chart.

## 1. Configuring Access to the Vertex AI API

To run the Agents you need access to the Vertex AI API

You have two options to achieve that:
* Either use a [Google Cloud Project](https://console.cloud.google.com/projectselector2/home/dashboard) with [billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project) and the [Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com,storage.googleapis.com) enabled,
* or use a [Google AI Studio API Key](https://aistudio.google.com/welcome).

Depending on which option you chose you can now configure the environment variables by copying the `.env.sample` file to the `.env`  file and adjust the content accordingly.

```bash
cp .env.sample .env

# adjust the values in the .env accordingly
# then source the file to make the variables available
source .env
```

The examples in sections 2 - 4 use the Google AI Studio API Key approach.

Refer to section 5 for the required steps to use more features on the Vertex AI Agent Engine with a Google Cloud Project.

## 2. Running on Docker Compose

### Requirements

* [Docker Compose](https://docs.docker.com/compose/)

### 2.1. Start the Agents with Docker Compose

```bash
docker compose up -d
```

### 2.2. Watch the Agent code updates with Docker Compose Watch

Run the below command in a second terminal
```bash
docker compose watch
```

### 2.3. Connect to the ADK WebUI

Point your browser to [http://localhost:8000](http://localhost:8000)

### 2.4. Turn down the environment

```bash
docker compose down
```

## 3. Running on minikube

### Requirements

* [Docker](https://docs.docker.com/)
* [helm](https://helm.sh/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)
* [minikube](https://minikube.sigs.k8s.io/)

### 3.1. Create a minikube cluster

```bash
# 1) Start minikube
minikube start
kubectl config get-contexts # ensure that you are in the minikube context.

# 2) Install local registry add-on
# https://minikube.sigs.k8s.io/docs/handbook/registry
minikube addons enable registry
docker run --rm -it -d --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"

# 3) Push local images to minikube registry
cd ./agent-host
docker build -t agent-host .
cd -
cd ./agent-prime
docker build -t agent-prime .
cd -
docker tag agent-host localhost:5000/agent-host:latest
docker tag agent-prime localhost:5000/agent-prime:latest
docker push localhost:5000/agent-host:latest
docker push localhost:5000/agent-prime:latest
```

### 3.2. Create a secret with the Google Vertex API key

```bash
kubectl create ns agents
kubectl create secret generic sec-google-api-key -n agents --from-literal=google-api-key=${GOOGLE_API_KEY}
```

### 3.3. Push the Agent manifests

```bash
cd helm
helm install agent-mono ./agent-mono -f ./agent-mono/values-local.yaml
```

### 3.4. Connect to the host Agent

```bash
minikube service agent-host -n agents
```

### 3.5. Delete the environment

```bash
helm uninstall agent-mono

# in case you also want to clean up the minikube environment then run the following command.
minikube delete
```

## 4. Running on GKE

### Requirements

* [gcloud](https://cloud.google.com/sdk/gcloud)
* [helm](https://helm.sh/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)

### 4.1. Create a GKE cluster

For running the Agents on GKE you will need a [Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [billing enabled](https://cloud.google.com/billing/docs/concepts).

You have two options to get started with Agents on GKE.

The quick way with option 1) with the GKE cluster as the only Google Cloud resource required.
Or with option 2) which also provisions the Google Cloud resources that you will need for a more sophisticated implementation described in [section 5](#5-use-vertex-ai-agent-engine-features).

1. In case you want to get started with a GKE cluster only (and none of the other Google Cloud resources) you can follow the instructions in the [online docs to create a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster#gcloud_1).
2. For your convenience you can use the Terraform script in the [iac](./iac) folder to provision the required Google Cloud resources.

```bash
# These are the commands required for option 2) above
cd ./iac
# Initialise Terraform
terraform init

# Plan to see the resources that the Terraform script will provision
terraform plan -var "project_id=${PROJECT_ID}"

# Apply to provision the resources
terraform apply -var  "project_id=${PROJECT_ID}"

cd ..
```

Once your GKE cluster is provisioned and ready fetch the credentials to access the cluster.

```bash
# Login to gcloud
gcloud auth login

# The command to fetch the credentials looks similar to the below
# Modify the variables to match your setup.
gcloud container clusters get-credentials agent-cluster --zone us-central1-b --project ${PROJECT_ID}
```

### 4.2. Create a secret with the Google Vertex API key

```bash
kubectl create ns agents
kubectl create secret generic sec-google-api-key -n agents --from-literal=google-api-key=${GOOGLE_API_KEY}
```

### 4.3. Push the Agent manifests

```bash
cd helm
helm install agent-mono ./agent-mono -f ./agent-mono/values-gke.yaml
```

### 4.4. Connect to the host Agent

```bash
kubectl port-forward service/agent-host 8000:8000 -n agents
```

You can now point your browser to [http://localhost:8000](http://localhost:8000) to interact with the Agent.

### 4.5. Delete the environment

```bash
helm uninstall agent-mono
```

## 5. Use Vertex AI Agent Engine Features

Google Cloud [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) offers several interesting features that you can take advantage of even when you are not using it as the runtime for your Agents.

- You can use [Agent Engine Sessions](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview) to maintain the history of interactions between a user and agents.
- Furthermore, [Memory Bank](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/memory-bank/overview) lets you dynamically generate long-term memories based on users' conversations with your agent

To use these features ([and more features](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)) you have to create a [Vertext Agent Engine instance](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/manage-sessions-adk#create-agent-engine).

Note that for the features you will need a [Google Cloud Project](https://console.cloud.google.com/projectselector2/home/dashboard) with [billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project) and the [Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com,storage.googleapis.com) enabled. 

You can run the below commands to create a Vertex Engine instance:

```bash
gcloud auth login
gcloud config set project $PROJECT_ID

# If you have not already install the required Python packages
python3 -m venv .venv
source .venv/bin/activate
pip install google-cloud-aiplatform[agent_engines,adk]

# Create the Agent Engine instance
python create-agent-engine.py
```

Note that the above command will create the Agent Engine instance in the `us-central1` Google Cloud Region.

Take note of the ID of the created Agent Engine. You can find it either in the output when running the script or on the [Google Cloud Console](https://console.cloud.google.com/vertex-ai/agents/agent-engines).


### 5.1. Running on Docker Compose

To start using the Agent Engine features with Docker Compose you can follow the approach outlined below:

1. Update the Agent Engine ID in the `.env` file accordingly.
2. Make sure you are successfully logged in by running `gcloud auth login` and `gcloud auth application-default login` 
3. Then you can follow the steps outlined in [section 2](#2-running-on-docker-compose) above.

### 5.2. Running on GKE

To start using the Agent Engine features with GKE you can follow the approach outlined below:

1. Follow the steps outlined in [section 4](#4-running-on-gke) to create a GKE cluster with [Workload Identity Federation for GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) enabled.
2. Grant the principal `principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${PROJECT_ID}.svc.id.goog/subject/ns/agents/sa/agents-sa` access to the [Vertex AI User](https://cloud.google.com/iam/docs/roles-permissions/aiplatform#aiplatform.user)(roles/aiplatform.user) and the [Cloud Trace Agent](https://cloud.google.com/trace/docs/iam#cloudtrace.agent)(roles/cloudtrace.agent) role.
3. Update the [values-agent-engine.yaml](./helm/agent-mono/values-agent-engine.yaml) with your `PROJECT_ID` and the Agent Engine ID created above.
4. The follow the steps outlined in [section 4](#4-running-on-gke) using the [values-agent-engine.yaml](./helm/agent-mono/values-agent-engine.yaml) for the `helm install` command.
