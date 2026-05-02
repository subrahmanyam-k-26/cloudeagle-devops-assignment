# Architecture Diagrams

These are Mermaid diagrams. To get a PNG, paste them into [mermaid.live](https://mermaid.live) and export.

## Full picture

```mermaid
graph TD
    DEV[Developer] -->|push / PR| GH[GitHub]
    GH -->|webhook| JK[Jenkins]
    JK -->|build + push| ECR[Amazon ECR]

    subgraph "VPC"
        ALB[ALB — HTTPS :443]
        subgraph "Private Subnets"
            QA[QA — 0.25 vCPU]
            STG[Staging — 0.25 vCPU]
            PROD[Prod — 0.5 vCPU x2]
            DOCDB[DocumentDB]
        end
        NAT[NAT Gateway]
    end

    JK -->|ecs deploy| ALB
    ECR -.->|pull| QA
    ECR -.->|pull| STG
    ECR -.->|pull| PROD
    ALB --> QA
    ALB --> STG
    ALB --> PROD
    QA --> DOCDB
    STG --> DOCDB
    PROD --> DOCDB
    PROD --> NAT

    SM[Secrets Manager] -.-> QA
    CW[CloudWatch] -.-> QA
    CW --> SNS[SNS → Slack]
```

## Simplified version

```
User → ALB (HTTPS) → ECS Fargate (Spring Boot) → DocumentDB
                              |
                    Secrets Manager + SSM
                              |
                    CloudWatch → Slack / PagerDuty
```

## CI/CD flow

```
feature/*  →  PR  →  build + test only
develop    →  merge  →  build → push → deploy to QA
release/*  →  merge  →  build → push → deploy to Staging
main       →  merge  →  build → push → approval → deploy to Prod
```
