# AWS Well-Architected EKS 클러스터 배포 가이드

## 📋 사전 요구사항

### 1. 필수 도구 설치
```bash
# AWS CLI 설치 및 설정
aws --version
aws configure

# Terraform 설치 (>= 1.5.7)
terraform --version

# kubectl 설치
kubectl version --client

# Helm 설치 (선택사항)
helm version
```

### 2. AWS 권한 설정
다음 AWS 서비스에 대한 권한이 필요합니다:
- EC2 (VPC, 서브넷, 보안 그룹, 인스턴스)
- EKS (클러스터, 노드 그룹, 애드온)
- IAM (역할, 정책, OIDC 공급자)
- KMS (키 생성 및 관리)
- CloudWatch (로그 그룹)
- CloudTrail (선택사항)

## 🚀 배포 단계

### 1. 저장소 클론 및 설정
```bash
git clone <repository-url>
cd aws-well-architected-eks
```

### 2. 변수 설정 (선택사항)
`terraform.tfvars` 파일을 생성하여 기본값을 재정의할 수 있습니다:

```hcl
# terraform.tfvars
region       = "ap-northeast-2"
cluster_name = "my-eks-cluster"
vpc_cidr     = "10.0.0.0/16"

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 5
    desired_size   = 3
  }
  spot = {
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 10
    desired_size   = 2
  }
}

tags = {
  Environment = "production"
  Project     = "my-project"
  Owner       = "platform-team"
}
```

### 3. Terraform 초기화 및 배포
```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 배포 실행
terraform apply
```

### 4. kubectl 설정
```bash
# kubeconfig 업데이트
aws eks --region ap-northeast-2 update-kubeconfig --name well-architected-eks

# 클러스터 연결 확인
kubectl get nodes
kubectl get pods -A
```

## 🔧 배포 후 설정

### 1. 클러스터 상태 확인
```bash
# 노드 상태 확인
kubectl get nodes -o wide

# 시스템 파드 확인
kubectl get pods -n kube-system

# EKS 애드온 확인
aws eks describe-addon --cluster-name well-architected-eks --addon-name vpc-cni
aws eks describe-addon --cluster-name well-architected-eks --addon-name coredns
aws eks describe-addon --cluster-name well-architected-eks --addon-name kube-proxy
aws eks describe-addon --cluster-name well-architected-eks --addon-name aws-ebs-csi-driver
```

### 2. 샘플 애플리케이션 배포
```yaml
# sample-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
# 애플리케이션 배포
kubectl apply -f sample-app.yaml

# 배포 확인
kubectl get deployments
kubectl get pods
kubectl get services
```

### 3. 스토리지 테스트
```yaml
# storage-test.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: ebs-claim
```

```bash
# 스토리지 테스트
kubectl apply -f storage-test.yaml
kubectl get pvc
kubectl get pv
```

## 🔍 모니터링 및 로깅

### 1. CloudWatch 로그 확인
```bash
# EKS 클러스터 로그 확인
aws logs describe-log-groups --log-group-name-prefix /aws/eks/well-architected-eks

# 로그 스트림 확인
aws logs describe-log-streams --log-group-name /aws/eks/well-architected-eks/cluster
```

### 2. VPC Flow Logs 확인
```bash
# VPC Flow Logs 상태 확인
aws ec2 describe-flow-logs --filter Name=resource-type,Values=VPC
```

### 3. 메트릭 확인
```bash
# CloudWatch 메트릭 확인
aws cloudwatch list-metrics --namespace AWS/EKS
aws cloudwatch list-metrics --namespace AWS/EC2
```

## 🧹 정리 (Clean Up)

### 1. 애플리케이션 제거
```bash
# 배포된 애플리케이션 제거
kubectl delete -f sample-app.yaml
kubectl delete -f storage-test.yaml

# PVC 제거 (EBS 볼륨 정리)
kubectl delete pvc --all
```

### 2. Terraform 리소스 제거
```bash
# Terraform으로 생성된 모든 리소스 제거
terraform destroy
```

## ⚠️ 주의사항

1. **비용 관리**: EKS 클러스터와 EC2 인스턴스는 시간당 요금이 부과됩니다.
2. **보안**: 프로덕션 환경에서는 추가 보안 설정이 필요할 수 있습니다.
3. **백업**: 중요한 데이터는 정기적으로 백업하세요.
4. **업데이트**: EKS 버전과 애드온을 정기적으로 업데이트하세요.

## 🔧 트러블슈팅

### 일반적인 문제들

1. **노드가 Ready 상태가 되지 않는 경우**
   ```bash
   kubectl describe nodes
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

2. **파드가 Pending 상태인 경우**
   ```bash
   kubectl describe pod <pod-name>
   kubectl get events -n <namespace>
   ```

3. **EBS CSI 드라이버 문제**
   ```bash
   kubectl logs -n kube-system -l app=ebs-csi-controller
   ```

4. **네트워크 연결 문제**
   ```bash
   kubectl get endpoints
   kubectl describe service <service-name>
   ```