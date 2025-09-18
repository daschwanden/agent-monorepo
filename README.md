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
 
## Requirements

* [Docker Compose](https://docs.docker.com/compose/)

## 1. Configuring Access to the Vertex AI API

To run the Agents you need access to the Vertex AI API

You have two options to achieve that:
* Either use a [Google Cloud Project](https://console.cloud.google.com/projectselector2/home/dashboard) with [billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project) and the [Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com,storage.googleapis.com) enabled,
* or use a [Google AI Studio API Key](https://aistudio.google.com/welcome).

Depending on which option you chose you can now configure the environment variables by copying the `.env.sample` file to the `.env`  file and adjust the content accordingly.

```bash
cp .env.sample .env
```

## 2. Running the Agents with Docker Compose

```bash
docker compose up -d
```

### 2.1. Watch the Agent code updates with Docker Compose Watch

Run the below command in a second terminal
```bash
docker compose watch
```

### 2.2. Connect to the ADK WebUI

Point your browser to [http://localhost:8000](http://localhost:8000)

### 2.3. Turn down the environment

```bash
docker compose down
```

## 3. Use Agent Engine Sessions

You can use [Agent Engine Sessions](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview) to maintain the history of interactions between a user and agents.

To use this feature you have to create a [Vertext Agent Engine instance](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/manage-sessions-adk#create-agent-engine).

Note that for this feature you will need a [Google Cloud Project](https://console.cloud.google.com/projectselector2/home/dashboard) with [billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project) and the [Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com,storage.googleapis.com) enabled. 

You can run the below commands to do so:

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

Use the Agent Engine ID to update the `.env` accordingly.

