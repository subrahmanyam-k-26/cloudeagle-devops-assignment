# CloudEagle DevOps Assignment

A production-grade DevOps setup for deploying a Spring Boot microservice on AWS, covering:

- CI/CD pipeline with Jenkins (branch-based deploys, automated testing, manual prod gate)
- AWS infrastructure on ECS Fargate with auto-scaling and private networking
- Secure secrets management through AWS Secrets Manager and SSM
- Zero-downtime rolling deployments with automated rollback
- Observability through CloudWatch (metrics, structured logs, alerting with SLO targets)
- Cost-optimized for startup scale (~$437/month across QA, Staging, and Production)

The service is `sync-service`, a Spring Boot backend that connects to MongoDB.

**Note on cloud choice:** The original assignment references GCP. I went with AWS because I have deeper hands-on experience building production systems there, and I wanted to focus on a realistic, implementation-ready design rather than a theoretical one. The architecture follows standard cloud patterns — ECS maps to GKE/Cloud Run, Secrets Manager maps to GCP Secret Manager, CloudWatch maps to Cloud Monitoring — so adapting this to GCP would be straightforward.

## What's in here

```
├── design/
│   ├── cicd-design.md           # CI/CD pipeline walkthrough
│   └── infra-design.md          # AWS infrastructure setup
├── jenkins/
│   ├── Jenkinsfile              # Main pipeline (handles PRs and merges)
│   └── Rollback_Jenkinsfile     # Standalone rollback job
├── diagrams/
│   └── architecture.md          # Mermaid diagrams (paste into mermaid.live for PNG)
├── Dockerfile                   # Multi-stage build
├── docker-compose.yml           # Local dev setup
└── infra/
    ├── ecs/                     # Task definitions + service configs per env
    └── iam/                     # IAM policies for ECS roles and Jenkins
```

## Quick summary

On the CI/CD side, I went with a modified GitFlow branching model where `develop` auto-deploys to QA, `release/*` goes to Staging, and `main` goes to Production behind a manual approval gate. PRs only run build/test/analysis — no deployments. The pipeline also handles rollback: ECS circuit breaker catches health check failures automatically, and there's a separate Jenkins job for manual rollbacks when needed.

For infrastructure, I chose ECS Fargate over EKS because we're running a single service at startup scale — Kubernetes would be overkill and adds $75/month just for the control plane. DocumentDB handles the MongoDB side for Staging and Prod (QA just uses a MongoDB container to save money). Everything sits in a VPC with private subnets, and secrets come from AWS Secrets Manager — nothing hardcoded anywhere.

Total estimated cost across all three environments is around $437/month.

## Running locally

```bash
docker compose up --build
```

This spins up the service on `localhost:8080` with a MongoDB instance on `27017`. Hit `/actuator/health` to check it's running.

## Things I'd add next

- Terraform for the infra (right now it's config files, not IaC)
- ArgoCD for GitOps-style deploys with drift detection and Git-based audit trail
- Canary deployments for production (weighted ALB target groups, watch metrics before full rollout)
- AWS X-Ray for distributed tracing
- Fargate Spot for QA/Staging to cut compute costs ~70%
- Scheduled scaling to shut down non-prod environments outside business hours
