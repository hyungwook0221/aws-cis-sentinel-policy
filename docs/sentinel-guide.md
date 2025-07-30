# HCP Terraform & Sentinel 정책 적용 가이드

## 📋 개요

이 가이드는 HCP Terraform에서 AWS CIS Foundations Benchmark 정책을 Sentinel을 사용하여 적용하는 방법을 설명합니다.

## 🎯 Sentinel 정책 목적

### CIS Foundations Benchmark 준수
- **보안 강화**: AWS 리소스의 보안 설정 검증
- **규정 준수**: 업계 표준 보안 정책 적용
- **자동화**: 인프라 배포 시 자동 정책 검증
- **거버넌스**: 조직 차원의 보안 정책 관리

## 🏗️ HCP Terraform 설정

### 1. HCP Terraform 계정 생성
1. [HCP Terraform](https://app.terraform.io) 접속
2. 계정 생성 또는 로그인
3. Organization 생성

### 2. Workspace 생성
```bash
# CLI를 통한 Workspace 생성
terraform login

# workspace 설정
terraform workspace new production
```

또는 웹 UI에서:
1. "New Workspace" 클릭
2. "Version control workflow" 선택
3. GitHub/GitLab 저장소 연결
4. Workspace 이름 설정: `aws-well-architected-eks`

### 3. 환경 변수 설정
HCP Terraform Workspace에서 다음 환경 변수를 설정:

```bash
# AWS 자격 증명 (Environment Variables)
AWS_ACCESS_KEY_ID = "your-access-key"
AWS_SECRET_ACCESS_KEY = "your-secret-key"
AWS_DEFAULT_REGION = "ap-northeast-2"

# Terraform 변수 (Terraform Variables)
region = "ap-northeast-2"
cluster_name = "well-architected-eks"
```

## 📝 Sentinel 정책 설정

### 1. Policy Set 생성
HCP Terraform에서 Policy Set을 생성합니다:

1. Organization Settings → Policy Sets
2. "Create a new policy set" 클릭
3. "Connect to VCS" 선택
4. 저장소 연결 및 `sentinel/` 디렉토리 지정

### 2. sentinel.hcl 설정
```hcl
# sentinel.hcl
policy "aws-cis-ec2-ebs-encryption" {
    source = "./policies/ec2/ec2-ebs-encryption-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-ec2-imdsv2" {
    source = "./policies/ec2/ec2-metadata-imdsv2-required.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-vpc-flow-logs" {
    source = "./policies/vpc/vpc-flow-logging-enabled.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-iam-password-policy" {
    source = "./policies/iam/iam-password-length.sentinel"
    enforcement_level = "soft-mandatory"
}

policy "aws-cis-s3-public-access" {
    source = "./policies/s3/s3-block-public-access-bucket-level.sentinel"
    enforcement_level = "hard-mandatory"
}

policy "aws-cis-kms-key-rotation" {
    source = "./policies/kms/kms-key-rotation-enabled.sentinel"
    enforcement_level = "advisory"
}
```

### 3. Enforcement Levels 설명
- **hard-mandatory**: 정책 위반 시 Plan/Apply 차단
- **soft-mandatory**: 정책 위반 시 경고, 관리자 승인으로 진행 가능
- **advisory**: 정책 위반 시 경고만 표시, 진행 가능

## 🔍 주요 CIS 정책 분석

### 1. EC2 관련 정책

#### EBS 암호화 (ec2-ebs-encryption-enabled.sentinel)
```sentinel
import "tfplan/v2" as tfplan

# EBS 볼륨 암호화 확인
ebs_volumes = filter tfplan.planned_values.resources as _, resource {
    resource.type is "aws_ebs_volume"
}

# 암호화되지 않은 볼륨 검출
unencrypted_volumes = filter ebs_volumes as _, volume {
    volume.values.encrypted is false
}

# 정책 위반 시 메시지
violations = []
for unencrypted_volumes as address, volume {
    violations append {
        "address": address,
        "message": "EBS volume must be encrypted",
        "resource": volume
    }
}

# 정책 결과
main = rule {
    length(violations) is 0
}
```

#### IMDSv2 강제 사용 (ec2-metadata-imdsv2-required.sentinel)
```sentinel
import "tfplan/v2" as tfplan

# EC2 인스턴스 및 Launch Template 확인
instances = filter tfplan.planned_values.resources as _, resource {
    resource.type in ["aws_instance", "aws_launch_template"]
}

# IMDSv2 설정 확인
violations = []
for instances as address, instance {
    if instance.values.metadata_options else {} as metadata {
        if metadata.http_tokens else "optional" is not "required" {
            violations append {
                "address": address,
                "message": "EC2 instance must use IMDSv2 (http_tokens = required)"
            }
        }
    } else {
        violations append {
            "address": address,
            "message": "EC2 instance must have metadata_options configured with IMDSv2"
        }
    }
}

main = rule {
    length(violations) is 0
}
```

### 2. VPC 관련 정책

#### VPC Flow Logs (vpc-flow-logging-enabled.sentinel)
```sentinel
import "tfplan/v2" as tfplan

# VPC 리소스 확인
vpcs = filter tfplan.planned_values.resources as _, resource {
    resource.type is "aws_vpc"
}

# Flow Logs 리소스 확인
flow_logs = filter tfplan.planned_values.resources as _, resource {
    resource.type is "aws_flow_log"
}

# VPC별 Flow Logs 매핑
vpc_flow_logs = {}
for flow_logs as _, flow_log {
    vpc_id = flow_log.values.vpc_id
    vpc_flow_logs[vpc_id] = true
}

# Flow Logs가 없는 VPC 검출
violations = []
for vpcs as address, vpc {
    vpc_id = vpc.values.id
    if vpc_flow_logs[vpc_id] else false is false {
        violations append {
            "address": address,
            "message": "VPC must have Flow Logs enabled"
        }
    }
}

main = rule {
    length(violations) is 0
}
```

### 3. KMS 관련 정책

#### KMS Key Rotation (kms-key-rotation-enabled.sentinel)
```sentinel
import "tfplan/v2" as tfplan

# KMS Key 리소스 확인
kms_keys = filter tfplan.planned_values.resources as _, resource {
    resource.type is "aws_kms_key"
}

# Key Rotation이 비활성화된 키 검출
violations = []
for kms_keys as address, key {
    if key.values.enable_key_rotation else false is false {
        violations append {
            "address": address,
            "message": "KMS key must have key rotation enabled"
        }
    }
}

main = rule {
    length(violations) is 0
}
```

## 🚀 정책 실행 프로세스

### 1. Terraform Plan 단계
```bash
# 로컬에서 Plan 실행
terraform plan

# HCP Terraform에서 자동 실행
# - VCS 연결 시 Push 트리거
# - 수동 실행 시 "Queue Plan" 클릭
```

### 2. Sentinel 정책 검증
HCP Terraform에서 자동으로 실행되는 단계:
1. **Plan 생성**: Terraform Plan 파일 생성
2. **정책 평가**: Sentinel 엔진이 모든 정책 실행
3. **결과 집계**: 정책 위반 사항 수집
4. **의사결정**: Enforcement Level에 따른 처리

### 3. 정책 결과 해석

#### ✅ 정책 통과 예시
```
Policy Check: aws-cis-ec2-ebs-encryption
Result: PASSED
Duration: 45ms
```

#### ❌ 정책 위반 예시
```
Policy Check: aws-cis-ec2-imdsv2
Result: FAILED
Duration: 67ms

Violations:
- aws_launch_template.eks_node_group: EC2 instance must use IMDSv2 (http_tokens = required)
- Address: module.eks.aws_launch_template.this["general"]
```

## 🔧 정책 커스터마이징

### 1. 정책 수정
기존 정책을 조직의 요구사항에 맞게 수정:

```sentinel
# 예: 특정 태그가 있는 리소스 제외
import "tfplan/v2" as tfplan

# 제외할 태그 정의
exempt_tags = ["Environment:development", "Testing:true"]

# 리소스 필터링 시 태그 확인
filtered_resources = filter all_resources as address, resource {
    # 제외 태그가 없는 리소스만 검사
    not has_exempt_tag(resource.values.tags else {})
}

# 태그 확인 함수
has_exempt_tag = func(tags) {
    for exempt_tags as exempt_tag {
        tag_parts = strings.split(exempt_tag, ":")
        key = tag_parts[0]
        value = tag_parts[1]
        if tags[key] else "" is value {
            return true
        }
    }
    return false
}
```

### 2. 새로운 정책 추가
조직별 요구사항에 따른 커스텀 정책:

```sentinel
# custom-tagging-policy.sentinel
import "tfplan/v2" as tfplan

# 필수 태그 정의
required_tags = ["Environment", "Project", "Owner", "CostCenter"]

# 태그 가능한 리소스 타입
taggable_resources = [
    "aws_instance",
    "aws_eks_cluster",
    "aws_vpc",
    "aws_s3_bucket",
    "aws_kms_key"
]

# 태그 가능한 리소스 필터링
resources = filter tfplan.planned_values.resources as _, resource {
    resource.type in taggable_resources
}

# 태그 검증
violations = []
for resources as address, resource {
    tags = resource.values.tags else {}
    
    for required_tags as required_tag {
        if required_tag not in keys(tags) {
            violations append {
                "address": address,
                "message": sprintf("Resource must have required tag: %s", [required_tag])
            }
        }
    }
}

main = rule {
    length(violations) is 0
}
```

## 📊 예상 결과 및 대응 방안

### 1. Well-Architected EKS 클러스터 정책 결과

#### ✅ 통과 예상 정책들
- **EBS 암호화**: 모든 EBS 볼륨 암호화 설정
- **IMDSv2**: Launch Template에서 IMDSv2 강제 설정
- **VPC Flow Logs**: VPC 모듈에서 자동 활성화
- **KMS Key Rotation**: KMS 키에서 rotation 활성화

#### ⚠️ 주의 필요 정책들
- **IAM 정책**: 기본 EKS IAM 역할은 일부 정책에서 경고 발생 가능
- **보안 그룹**: 클러스터 간 통신을 위한 규칙이 일부 정책과 충돌 가능

### 2. 정책 위반 시 대응 방안

#### Hard-Mandatory 위반
```bash
# 1. 코드 수정
# 위반 사항을 코드에서 직접 수정

# 2. 정책 예외 처리
# 특정 리소스에 대한 예외 태그 추가

# 3. Enforcement Level 조정
# 임시로 soft-mandatory로 변경
```

#### Soft-Mandatory 위반
```bash
# 1. 관리자 승인 요청
# HCP Terraform UI에서 "Override and Continue" 선택

# 2. 위반 사유 문서화
# 정책 위반에 대한 비즈니스 정당성 기록
```

## 🔍 모니터링 및 리포팅

### 1. 정책 준수 대시보드
HCP Terraform에서 제공하는 기능:
- 정책 실행 히스토리
- 위반 사항 트렌드
- 조직별 준수율

### 2. 알림 설정
```bash
# Slack/Teams 통합
# 정책 위반 시 자동 알림

# 이메일 알림
# 중요 정책 위반 시 관리자에게 이메일 발송
```

### 3. 정기 리포트
- 주간/월간 정책 준수 리포트
- 위반 사항 분석 및 개선 계획
- 정책 효과성 평가

## 🎯 베스트 프랙티스

### 1. 정책 개발
- **점진적 적용**: Advisory → Soft-Mandatory → Hard-Mandatory
- **테스트 환경**: 프로덕션 적용 전 충분한 테스트
- **문서화**: 정책 목적과 예외 사항 명확히 기록

### 2. 조직 관리
- **역할 분리**: 정책 관리자와 인프라 개발자 역할 분리
- **교육**: 팀원들에게 정책 목적과 준수 방법 교육
- **피드백**: 정책 사용자로부터 지속적인 피드백 수집

### 3. 지속적 개선
- **정기 검토**: 정책의 효과성과 적절성 정기 검토
- **업데이트**: 새로운 보안 요구사항 반영
- **자동화**: 정책 관리 프로세스 자동화