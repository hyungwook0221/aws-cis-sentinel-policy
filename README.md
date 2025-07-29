# CIS Sentinel Policy Test with HCP Terraform

이 프로젝트는 HCP Terraform과 Sentinel 정책을 사용하여 AWS CIS Foundations Benchmark 준수 여부를 테스트합니다.

## 🎯 목적

- HCP Terraform에서 Sentinel 정책 실행 테스트
- AWS CIS Foundations Benchmark 정책 위반 사항 확인
- tfplan/v2 모듈을 사용한 실제 정책 검증

## 📋 포함된 CIS 정책 위반 사항

### Critical 위반
- SSH 포트(22)가 0.0.0.0/0에 개방
- RDP 포트(3389)가 0.0.0.0/0에 개방

### Medium 위반
- EBS 볼륨 암호화 비활성화
- S3 버킷 퍼블릭 액세스 차단 설정 누락
- CloudTrail 로깅 설정 누락

## 🚀 사용 방법

1. HCP Terraform에서 workspace 생성
2. Sentinel 정책 설정
3. Terraform plan 실행 및 정책 검증

## 📁 파일 구조

```
.
├── main.tf                    # 메인 Terraform 설정
├── variables.tf               # 변수 정의
├── sentinel/                  # Sentinel 정책 파일들
│   └── policies/             # CIS 정책 파일들
└── CIS_Compliance_Analysis_Report.md  # 분석 보고서
```

## 🔍 예상 결과

- 총 13개 CIS 정책 중 11개 위반 (85% 위반율)
- Sentinel에서 정책 위반으로 인한 plan 실패 예상
