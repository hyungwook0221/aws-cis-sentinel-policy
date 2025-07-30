# AWS Well-Architected EKS Cluster with Sentinel Policies

이 프로젝트는 AWS Well-Architected Framework의 5가지 기둥(Security, Reliability, Performance Efficiency, Cost Optimization, Operational Excellence)을 준수하는 EKS 클러스터를 Terraform으로 구축하고, HashiCorp Sentinel을 사용하여 AWS CIS 정책을 적용하는 예제입니다.

## 🏗️ 아키텍처 개요

### EKS 클러스터 구성요소
- **VPC**: 3개 AZ에 걸친 프라이빗/퍼블릭 서브넷
- **EKS 클러스터**: 프라이빗 엔드포인트, 암호화, 로깅 활성화
- **관리형 노드 그룹**: AL2023 AMI, IMDSv2, EBS 암호화
- **필수 애드온**: VPC CNI, CoreDNS, Kube-proxy, EBS CSI, Pod Identity Agent
- **보안**: KMS 암호화, VPC Flow Logs, CloudWatch 로깅

### Well-Architected Framework 준수사항
1. **Security**: KMS 암호화, 프라이빗 엔드포인트, IMDSv2, 보안 그룹 최소 권한
2. **Reliability**: 멀티 AZ 배포, 관리형 서비스 사용
3. **Performance Efficiency**: GP3 스토리지, 최적화된 인스턴스 타입
4. **Cost Optimization**: 적절한 인스턴스 크기, 스팟 인스턴스 옵션
5. **Operational Excellence**: CloudWatch 로깅, 태깅 전략

## 🎯 목적

- AWS Well-Architected Framework 기반 EKS 클러스터 구축
- HCP Terraform과 Sentinel을 통한 CIS 정책 준수 검증
- 보안, 안정성, 성능, 비용, 운영 우수성 확보

## 📋 포함된 보안 기능

### 네트워크 보안
- 프라이빗 서브넷에 워커 노드 배치
- 프라이빗 API 엔드포인트 사용
- VPC Flow Logs 활성화
- 보안 그룹 최소 권한 원칙

### 데이터 보안
- KMS를 통한 EKS secrets 암호화
- EBS 볼륨 암호화
- CloudWatch 로그 암호화

### 접근 제어
- IAM 역할 기반 접근 제어
- OIDC 기반 서비스 계정 인증
- IMDSv2 강제 사용

## 🚀 사용 방법

### 1. 사전 요구사항
```bash
# AWS CLI 설정
aws configure

# Terraform 설치 (>= 1.5.7)
terraform --version

# kubectl 설치
kubectl version --client
```

### 2. 클러스터 배포
```bash
# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 배포 실행
terraform apply
```

### 3. kubectl 설정
```bash
# kubeconfig 업데이트
aws eks --region ap-northeast-2 update-kubeconfig --name well-architected-eks

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods -A
```

## 📁 파일 구조

```
.
├── main.tf                    # 메인 EKS 클러스터 설정
├── variables.tf               # 변수 정의
├── outputs.tf                 # 출력 값 정의
├── modules/
│   └── eks-addons/           # EKS 애드온 모듈
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── sentinel/                  # Sentinel 정책 파일들
│   └── policies/             # CIS 정책 파일들
└── docs/                     # 문서 및 다이어그램
```

## 🔍 HCP Terraform & Sentinel 설정

### 1. HCP Terraform Workspace 생성
1. HCP Terraform에 로그인
2. 새 Workspace 생성 (VCS 연결 또는 CLI 기반)
3. 환경 변수 설정:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_DEFAULT_REGION`

### 2. Sentinel 정책 설정
```hcl
# sentinel.hcl
policy "aws-cis-foundations" {
    source = "./sentinel/policies/"
    enforcement_level = "hard-mandatory"
}
```

### 3. 정책 검증 실행
- Terraform Plan 실행 시 자동으로 Sentinel 정책 검증
- CIS 정책 위반 시 Plan 실패
- 정책 통과 시에만 Apply 가능

## 📊 예상 결과

### 보안 정책 준수
- ✅ EBS 암호화 활성화
- ✅ VPC Flow Logs 활성화
- ✅ IMDSv2 강제 사용
- ✅ 프라이빗 엔드포인트 사용
- ✅ KMS 암호화 적용

### 성능 최적화
- GP3 스토리지 사용으로 비용 절감
- 적절한 인스턴스 타입 선택
- 멀티 AZ 배포로 고가용성 확보

## 📁 상세 파일 구조

```
.
├── main.tf                           # 메인 EKS 클러스터 설정
├── variables.tf                      # 입력 변수 정의
├── outputs.tf                        # 출력 값 정의
├── terraform.tfvars.example          # 변수 예시 파일
├── modules/
│   └── eks-addons/                   # EKS 애드온 모듈
│       ├── main.tf                   # 애드온 리소스 정의
│       ├── variables.tf              # 모듈 입력 변수
│       └── outputs.tf                # 모듈 출력 값
├── sentinel/                         # Sentinel 정책 디렉토리
│   ├── sentinel.hcl                  # 정책 설정 파일
│   ├── modules/                      # 공통 모듈
│   └── policies/                     # CIS 정책 파일들
│       ├── ec2/                      # EC2 관련 정책
│       ├── vpc/                      # VPC 관련 정책
│       ├── iam/                      # IAM 관련 정책
│       ├── s3/                       # S3 관련 정책
│       └── kms/                      # KMS 관련 정책
├── docs/                             # 문서 디렉토리
│   ├── deployment-guide.md           # 배포 가이드
│   └── sentinel-guide.md             # Sentinel 정책 가이드
└── generated-diagrams/               # 생성된 아키텍처 다이어그램
    ├── eks-architecture.png          # EKS 아키텍처 다이어그램
    └── terraform-structure.png       # Terraform 구조 다이어그램
```

## 🎯 다음 단계

### 1. 즉시 실행 가능한 작업
```bash
# 1. 저장소 클론
git clone <repository-url>
cd aws-well-architected-eks

# 2. Terraform 초기화 및 배포
terraform init
terraform plan
terraform apply

# 3. kubectl 설정
aws eks --region ap-northeast-2 update-kubeconfig --name well-architected-eks
kubectl get nodes
```

### 2. HCP Terraform 설정
1. [HCP Terraform](https://app.terraform.io) 계정 생성
2. Workspace 생성 및 VCS 연결
3. 환경 변수 설정 (AWS 자격 증명)
4. Policy Set 생성 및 Sentinel 정책 연결

### 3. 추가 보안 강화 (선택사항)
- **Network Policies**: Calico 또는 Cilium 설치
- **Pod Security Standards**: PSS/PSA 설정
- **Service Mesh**: Istio 또는 App Mesh 구성
- **Secrets Management**: External Secrets Operator 설치

### 4. 모니터링 및 관찰성
- **Prometheus & Grafana**: 메트릭 수집 및 시각화
- **Fluent Bit**: 로그 수집 및 전송
- **AWS X-Ray**: 분산 추적
- **Container Insights**: CloudWatch 컨테이너 모니터링

## 🔗 유용한 링크

### AWS 문서
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [EKS Security Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/security-best-practices.html)

### Terraform 문서
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [VPC Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

### Sentinel 문서
- [Sentinel Language Guide](https://docs.hashicorp.com/sentinel/language)
- [Terraform Sentinel Imports](https://www.terraform.io/docs/cloud/sentinel/import/index.html)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 지원

문제가 발생하거나 질문이 있으시면:
- GitHub Issues를 통해 문의
- 문서를 먼저 확인해 주세요
- 커뮤니티 포럼 활용

---

**⚠️ 중요**: 이 프로젝트는 AWS 리소스를 생성하므로 비용이 발생할 수 있습니다. 테스트 후에는 `terraform destroy`를 실행하여 리소스를 정리하세요.