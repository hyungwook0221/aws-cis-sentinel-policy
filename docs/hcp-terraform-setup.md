# HCP Terraform 설정 가이드

## 📋 개요

이 가이드는 AWS Well-Architected EKS 클러스터를 HCP Terraform에서 관리하고 Sentinel 정책을 적용하는 방법을 설명합니다.

## 🚀 HCP Terraform 초기 설정

### 1. HCP Terraform 계정 생성

1. [HCP Terraform](https://app.terraform.io) 접속
2. "Sign up" 클릭하여 계정 생성
3. Organization 생성 (예: `your-company-eks`)

### 2. Workspace 생성

#### 방법 1: VCS 연결 (권장)
1. "New Workspace" 클릭
2. "Version control workflow" 선택
3. GitHub/GitLab 연결
4. 저장소 선택: `aws-well-architected-eks`
5. Workspace 이름: `aws-eks-production`

#### 방법 2: CLI 기반
```bash
# Terraform CLI 로그인
terraform login

# Workspace 설정
cat > backend.tf << EOF
terraform {
  cloud {
    organization = "your-company-eks"
    workspaces {
      name = "aws-eks-production"
    }
  }
}
EOF
```

### 3. 환경 변수 설정

HCP Terraform Workspace → Variables 탭에서 설정:

#### Environment Variables (민감 정보)
```bash
AWS_ACCESS_KEY_ID = "AKIA..."          # Sensitive: ✅
AWS_SECRET_ACCESS_KEY = "..."          # Sensitive: ✅
AWS_DEFAULT_REGION = "ap-northeast-2"  # Sensitive: ❌
```

#### Terraform Variables
```hcl
# 기본 설정
region = "ap-northeast-2"
cluster_name = "production-eks"
cluster_version = "1.31"

# VPC 설정
vpc_cidr = "10.0.0.0/16"
azs = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

# 노드 그룹 설정 (HCL 형식)
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 5
    desired_size   = 3
  }
}

# 태그 설정 (HCL 형식)
tags = {
  Environment = "production"
  Project     = "eks-platform"
  ManagedBy   = "hcp-terraform"
}
```

## 🛡️ Sentinel 정책 설정

### 1. Policy Set 생성

1. Organization Settings → Policy Sets
2. "Create a new policy set" 클릭
3. 설정 입력:
   - **Name**: `aws-cis-foundations`
   - **Description**: `AWS CIS Foundations Benchmark policies`
   - **Scope**: `Policies enforced on selected workspaces`

### 2. VCS 연결 설정

1. "Connect to VCS" 선택
2. GitHub/GitLab 저장소 연결
3. **VCS branch**: `main`
4. **Policies path**: `sentinel/`
5. **Policy framework**: `Sentinel`

### 3. Workspace 연결

1. Policy Set → Workspaces 탭
2. "Add workspace" 클릭
3. `aws-eks-production` 선택

### 4. 정책 테스트

```bash
# 로컬에서 Sentinel 정책 테스트
sentinel test sentinel/policies/ec2/ec2-ebs-encryption-enabled.sentinel

# 모든 정책 테스트
find sentinel/policies -name "*.sentinel" -exec sentinel test {} \;
```

## 🔄 워크플로우 설정

### 1. 자동 실행 설정

Workspace Settings → General:
- **Auto-apply**: `Only apply on merge to main branch` (권장)
- **Terraform Version**: `Latest`
- **Execution Mode**: `Remote`

### 2. 알림 설정

Workspace Settings → Notifications:

#### Slack 통합
```json
{
  "webhook_url": "https://hooks.slack.com/services/...",
  "channel": "#infrastructure",
  "triggers": [
    "run:planning",
    "run:needs_attention",
    "run:applying",
    "run:completed",
    "run:errored"
  ]
}
```

#### Email 알림
- **Recipients**: `devops-team@company.com`
- **Triggers**: `Needs Attention`, `Errored`

### 3. 팀 권한 설정

Organization Settings → Teams:

#### DevOps Team
- **Permissions**: `Manage Workspaces`
- **Workspace Access**: `Admin`

#### Developers Team
- **Permissions**: `Manage Workspaces`
- **Workspace Access**: `Plan`

## 📊 실행 및 모니터링

### 1. 첫 번째 실행

1. 코드를 main 브랜치에 푸시
2. HCP Terraform에서 자동으로 Plan 실행
3. Sentinel 정책 검증
4. 승인 후 Apply 실행

### 2. Plan 단계 확인사항

```bash
# 예상 리소스 생성 수
Plan: 45 to add, 0 to change, 0 to destroy.

# 주요 리소스들
+ aws_eks_cluster.main
+ aws_eks_node_group.general
+ aws_vpc.main
+ aws_kms_key.eks
+ aws_cloudwatch_log_group.eks_cluster
```

### 3. Sentinel 정책 결과

#### ✅ 통과 예상 정책들
```
✅ aws-cis-ec2-ebs-encryption: PASSED
✅ aws-cis-ec2-imdsv2: PASSED
✅ aws-cis-vpc-flow-logs: PASSED
✅ aws-cis-kms-key-rotation: PASSED
```

#### ⚠️ 주의 필요 정책들
```
⚠️ aws-cis-iam-no-admin-policies: ADVISORY
   - EKS service roles require elevated permissions
   
⚠️ aws-cis-s3-public-access-block: SOFT-MANDATORY
   - No S3 buckets in this configuration
```

### 4. Apply 후 검증

```bash
# 클러스터 상태 확인
aws eks describe-cluster --name production-eks --region ap-northeast-2

# kubectl 설정
aws eks update-kubeconfig --name production-eks --region ap-northeast-2

# 노드 확인
kubectl get nodes
```

## 🔧 고급 설정

### 1. 환경별 Workspace 분리

#### Development Workspace
- **Name**: `aws-eks-development`
- **VCS Branch**: `develop`
- **Auto-apply**: `Disabled`
- **Policy Enforcement**: `Advisory` 모드

#### Staging Workspace
- **Name**: `aws-eks-staging`
- **VCS Branch**: `staging`
- **Auto-apply**: `On merge to staging`
- **Policy Enforcement**: `Soft-mandatory`

#### Production Workspace
- **Name**: `aws-eks-production`
- **VCS Branch**: `main`
- **Auto-apply**: `Manual approval required`
- **Policy Enforcement**: `Hard-mandatory`

### 2. 변수 세트 활용

Organization Settings → Variable Sets:

#### AWS Credentials Set
```hcl
# 모든 AWS 워크스페이스에 적용
variable_set_name = "aws-credentials"
variables = {
  AWS_DEFAULT_REGION = "ap-northeast-2"
}
```

#### Common Tags Set
```hcl
variable_set_name = "common-tags"
variables = {
  tags = {
    Organization = "YourCompany"
    ManagedBy    = "hcp-terraform"
    CostCenter   = "engineering"
  }
}
```

### 3. 정책 예외 처리

특정 리소스에 대한 정책 예외가 필요한 경우:

```hcl
# terraform.tfvars
# 정책 예외 태그
tags = {
  Environment = "production"
  PolicyException = "approved-by-security-team"
  ExceptionReason = "legacy-system-compatibility"
}
```

Sentinel 정책에서 예외 처리:
```sentinel
# 예외 태그가 있는 리소스 제외
exempt_resources = filter resources as address, resource {
    resource.values.tags.PolicyException else "" is not "approved-by-security-team"
}
```

## 📈 모니터링 및 리포팅

### 1. 실행 히스토리 분석

Workspace → Runs 탭에서 확인:
- Plan/Apply 성공률
- 정책 위반 트렌드
- 실행 시간 분석

### 2. 비용 추정

HCP Terraform의 Cost Estimation 기능:
- 월간 예상 비용
- 리소스별 비용 분석
- 변경사항에 따른 비용 영향

### 3. 정책 준수 리포트

Organization → Policy Sets → Reports:
- 정책별 준수율
- 워크스페이스별 위반 현황
- 시간별 트렌드 분석

## 🚨 트러블슈팅

### 일반적인 문제들

#### 1. AWS 권한 오류
```
Error: AccessDenied: User is not authorized to perform: eks:CreateCluster
```

**해결방법**:
- IAM 사용자에게 필요한 권한 추가
- `AdministratorAccess` 또는 세분화된 EKS 권한 부여

#### 2. Sentinel 정책 실패
```
Policy Check: aws-cis-ec2-ebs-encryption
Result: FAILED
```

**해결방법**:
- 정책 로그 확인
- 리소스 설정 수정
- 필요시 정책 예외 처리

#### 3. State Lock 오류
```
Error: Error acquiring the state lock
```

**해결방법**:
- HCP Terraform UI에서 "Force Unlock"
- 동시 실행 방지

### 지원 및 문의

- **HCP Terraform 문서**: https://developer.hashicorp.com/terraform/cloud-docs
- **Sentinel 문서**: https://docs.hashicorp.com/sentinel
- **AWS EKS 문서**: https://docs.aws.amazon.com/eks/
- **커뮤니티 포럼**: https://discuss.hashicorp.com/