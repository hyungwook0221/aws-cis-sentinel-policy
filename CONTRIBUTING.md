# 기여 가이드

AWS Well-Architected EKS 프로젝트에 기여해 주셔서 감사합니다! 이 가이드는 프로젝트에 기여하는 방법을 설명합니다.

## 🤝 기여 방법

### 1. 이슈 리포팅

버그를 발견하거나 새로운 기능을 제안하고 싶다면:

1. [GitHub Issues](../../issues)에서 기존 이슈 확인
2. 새로운 이슈 생성 시 템플릿 사용
3. 명확하고 상세한 설명 제공

#### 버그 리포트 템플릿

```markdown
## 버그 설명
버그에 대한 명확하고 간결한 설명

## 재현 단계
1. '...' 실행
2. '...' 클릭
3. '...' 확인
4. 오류 발생

## 예상 동작
예상했던 동작에 대한 설명

## 실제 동작
실제로 발생한 동작에 대한 설명

## 환경 정보
- OS: [예: macOS 12.0]
- Terraform 버전: [예: 1.5.7]
- AWS CLI 버전: [예: 2.13.0]
- kubectl 버전: [예: 1.28.0]

## 추가 정보
스크린샷, 로그, 기타 관련 정보
```

### 2. 코드 기여

#### 개발 환경 설정

```bash
# 저장소 포크 및 클론
git clone https://github.com/your-username/aws-well-architected-eks.git
cd aws-well-architected-eks

# 개발 브랜치 생성
git checkout -b feature/your-feature-name

# 의존성 확인
terraform --version
aws --version
kubectl version --client
```

#### 코딩 표준

1. **Terraform 코드**:
   - HCL 표준 포맷팅 사용 (`terraform fmt`)
   - 변수와 출력에 명확한 설명 추가
   - 리소스 태깅 일관성 유지

2. **문서**:
   - 마크다운 표준 준수
   - 한국어/영어 혼용 시 일관성 유지
   - 코드 예시에 주석 포함

3. **Sentinel 정책**:
   - 명확한 정책 설명 주석
   - 테스트 케이스 포함
   - 오류 메시지 명확성

#### 커밋 메시지 규칙

```bash
# 형식: type(scope): description
feat(eks): add support for Fargate profiles
fix(sentinel): correct EBS encryption policy logic
docs(readme): update installation instructions
refactor(modules): simplify addon module structure
test(scripts): add cluster validation tests
```

**타입**:
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `refactor`: 코드 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드/설정 변경

### 3. Pull Request 프로세스

#### PR 생성 전 체크리스트

- [ ] 코드가 올바르게 포맷팅됨 (`terraform fmt`)
- [ ] 모든 테스트 통과
- [ ] 문서 업데이트 완료
- [ ] 변경사항에 대한 테스트 추가
- [ ] 커밋 메시지가 규칙을 준수

#### PR 템플릿

```markdown
## 변경사항 설명
이 PR에서 변경된 내용에 대한 명확한 설명

## 변경 타입
- [ ] 버그 수정
- [ ] 새로운 기능
- [ ] 문서 업데이트
- [ ] 리팩토링
- [ ] 테스트 추가

## 테스트
- [ ] 기존 테스트 모두 통과
- [ ] 새로운 테스트 추가
- [ ] 수동 테스트 완료

## 체크리스트
- [ ] 코드 포맷팅 완료
- [ ] 문서 업데이트 완료
- [ ] 변경사항 테스트 완료
- [ ] 커밋 메시지 규칙 준수

## 관련 이슈
Closes #이슈번호
```

#### 리뷰 프로세스

1. **자동 검사**: CI/CD 파이프라인 통과
2. **코드 리뷰**: 최소 1명의 승인 필요
3. **테스트**: 모든 테스트 통과 확인
4. **문서**: 관련 문서 업데이트 확인

## 📋 개발 가이드라인

### 1. Terraform 모듈 개발

#### 모듈 구조
```
modules/
├── module-name/
│   ├── main.tf          # 주요 리소스 정의
│   ├── variables.tf     # 입력 변수
│   ├── outputs.tf       # 출력 값
│   ├── versions.tf      # 프로바이더 버전
│   └── README.md        # 모듈 문서
```

#### 변수 정의 예시
```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}
```

#### 출력 정의 예시
```hcl
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = false
}
```

### 2. Sentinel 정책 개발

#### 정책 구조
```sentinel
# 정책 설명 주석
import "tfplan/v2" as tfplan

# 상수 정의
required_encryption = true

# 리소스 필터링
resources = filter tfplan.planned_values.resources as _, resource {
    resource.type is "aws_ebs_volume"
}

# 정책 로직
violations = []
for resources as address, resource {
    if resource.values.encrypted is not required_encryption {
        violations append {
            "address": address,
            "message": "EBS volume must be encrypted"
        }
    }
}

# 메인 규칙
main = rule {
    length(violations) is 0
}
```

#### 테스트 케이스
```hcl
# test/policy-name/pass.hcl
resource "aws_ebs_volume" "example" {
  encrypted = true
  size      = 10
}

# test/policy-name/fail.hcl
resource "aws_ebs_volume" "example" {
  encrypted = false
  size      = 10
}
```

### 3. 문서 작성 가이드

#### 마크다운 스타일
- 제목: `#`, `##`, `###` 사용
- 코드 블록: 언어 지정 (```hcl, ```bash)
- 링크: 상대 경로 사용
- 이미지: `docs/images/` 디렉토리 사용

#### 문서 구조
```markdown
# 제목

## 개요
간단한 설명

## 사전 요구사항
필요한 도구 및 권한

## 사용 방법
단계별 가이드

## 예시
실제 사용 예시

## 트러블슈팅
일반적인 문제 해결

## 참고 자료
관련 링크
```

## 🧪 테스트 가이드

### 1. Terraform 테스트

```bash
# 포맷 검사
terraform fmt -check

# 유효성 검사
terraform validate

# 계획 생성
terraform plan

# 보안 검사 (선택사항)
tfsec .
```

### 2. Sentinel 테스트

```bash
# 개별 정책 테스트
sentinel test policies/ec2/ec2-ebs-encryption-enabled.sentinel

# 모든 정책 테스트
find policies -name "*.sentinel" -exec sentinel test {} \;
```

### 3. 통합 테스트

```bash
# 클러스터 검증 스크립트 실행
./scripts/validate-cluster.sh

# 샘플 애플리케이션 배포 테스트
kubectl apply -f examples/sample-app.yaml
kubectl get pods -n sample-app
```

## 🏷️ 릴리스 프로세스

### 1. 버전 관리

- **Semantic Versioning** 사용 (v1.0.0)
- **Major**: 호환성 없는 변경
- **Minor**: 새로운 기능 추가
- **Patch**: 버그 수정

### 2. 릴리스 노트

```markdown
## v1.1.0 (2025-01-30)

### 새로운 기능
- EKS Fargate 프로필 지원 추가
- 추가 Sentinel 정책 구현

### 개선사항
- 클러스터 검증 스크립트 향상
- 문서 업데이트

### 버그 수정
- EBS 암호화 정책 로직 수정
- 노드 그룹 태깅 이슈 해결

### 호환성
- Terraform >= 1.5.7
- AWS Provider >= 6.0
- Kubernetes >= 1.28
```

## 📞 커뮤니티

### 소통 채널

- **GitHub Issues**: 버그 리포트, 기능 요청
- **GitHub Discussions**: 일반적인 질문, 아이디어 공유
- **Pull Requests**: 코드 기여

### 행동 강령

1. **존중**: 모든 기여자를 존중합니다
2. **건설적**: 건설적인 피드백을 제공합니다
3. **협력**: 협력적인 환경을 만듭니다
4. **포용**: 다양성을 환영합니다

## 🎯 기여 아이디어

### 우선순위 높음
- [ ] EKS Fargate 지원 추가
- [ ] 추가 보안 정책 구현
- [ ] 모니터링 대시보드 구성
- [ ] 자동화 스크립트 개선

### 우선순위 중간
- [ ] 다중 리전 지원
- [ ] 비용 최적화 기능
- [ ] 성능 튜닝 가이드
- [ ] 재해 복구 계획

### 우선순위 낮음
- [ ] UI 대시보드 개발
- [ ] 추가 클라우드 지원
- [ ] 고급 네트워킹 기능
- [ ] 커스텀 애드온 개발

## 📚 참고 자료

- [Terraform 모듈 작성 가이드](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Sentinel 정책 작성 가이드](https://docs.hashicorp.com/sentinel/writing)
- [AWS EKS 베스트 프랙티스](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes 기여 가이드](https://kubernetes.io/docs/contribute/)

---

다시 한 번 기여해 주셔서 감사합니다! 질문이 있으시면 언제든지 이슈를 생성해 주세요. 🚀