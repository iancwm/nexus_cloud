# Hosted Coder Server Specifications

## Objective
Provide an optional, fully automated Terraform module to deploy a centralized, hosted Coder server on AWS with a permanent domain, authentication, and robust observability. This replaces the need to run the Coder server locally.

## Architecture
* **Compute:** EC2 instance (e.g., `t3.medium`) to host the Coder control plane and embedded PostgreSQL database (keeps costs low while providing sufficient power).
* **Networking & Ingress:** 
  * VPC, Public Subnets, Security Groups (Ports 80/443).
  * **Application Load Balancer (ALB)** for traffic distribution and SSL termination.
  * **AWS Certificate Manager (ACM)** for automated TLS certificate provisioning.
  * **Route53** for DNS record management (requires the user to provide an existing Hosted Zone).
* **Authentication:** Built-in Coder password auth by default, with instructions for OIDC (GitHub/Google) integration.

## Automation
* A new Terraform module: `modules/coder-server`.
* Managed via a new `justfile` recipe: `just build-server DOMAIN=coder.example.com`.
* Uses `cloud-init` (`user_data`) to install Docker, start the Coder server container, and link it to the RDS/embedded DB.

## Observability & Testing
* **Observability:** 
  * Coder service logs shipped to AWS CloudWatch Logs.
  * Prometheus metrics endpoint enabled for the Coder server.
* **Testing:** 
  * Implementation of infrastructure tests (e.g., via `terraform test` or custom bash validation scripts) to ensure the server answers on `https://<domain>/api/v2/buildinfo` before marking deployment as successful.
