#!/usr/bin/env python3
"""
EKS Well-Architected Architecture Diagram Generator
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EKS, EC2, AutoScaling
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, InternetGateway, NATGateway, ElasticLoadBalancing
from diagrams.aws.security import IAM, KMS
from diagrams.aws.storage import EBS
from diagrams.aws.management import Cloudwatch
from diagrams.aws.integration import SNS
from diagrams.aws.general import General, User
from diagrams.generic.blank import Blank

def create_eks_architecture():
    """Create EKS Well-Architected Architecture Diagram"""
    
    with Diagram("EKS Well-Architected Architecture", 
                 show=False, 
                 direction="TB", 
                 filename="eks-well-architected-architecture",
                 outformat="png"):
        
        # External User
        developer = User("Developer\nkubectl/helm")
        
        with Cluster("AWS Cloud"):
            
            # Security & Identity
            with Cluster("Security & Identity"):
                iam = IAM("IAM Roles\n& Policies")
                kms = KMS("KMS\nEncryption")
            
            # Container Services
            ecr = General("ECR Repository\nImage Scanning")
            
            # Monitoring
            with Cluster("Monitoring & Observability"):
                cloudwatch = Cloudwatch("CloudWatch\nLogs & Metrics")
                sns = SNS("SNS\nAlerts")
            
            # VPC Architecture
            with Cluster("VPC (10.0.0.0/16)"):
                
                # Internet Gateway
                igw = InternetGateway("Internet Gateway")
                
                # Public Subnets
                with Cluster("Public Subnets (Multi-AZ)"):
                    pub_subnet_a = PublicSubnet("Public AZ-A\n10.0.1.0/24")
                    nat_gw = NATGateway("NAT Gateway")
                    pub_subnet_b = PublicSubnet("Public AZ-B\n10.0.2.0/24")
                
                # Private Subnets
                with Cluster("Private Subnets (Multi-AZ)"):
                    priv_subnet_a = PrivateSubnet("Private AZ-A\n10.0.10.0/24")
                    worker_a = EC2("Worker Node A\nt3.medium")
                    
                    priv_subnet_b = PrivateSubnet("Private AZ-B\n10.0.20.0/24")
                    worker_b = EC2("Worker Node B\nt3.medium")
                
                # EKS Control Plane
                eks = EKS("EKS Control Plane\nv1.29 Managed")
            
            # EKS Add-ons
            with Cluster("EKS Add-ons"):
                alb = ElasticLoadBalancing("AWS Load Balancer\nController")
                autoscaler = AutoScaling("Cluster\nAutoscaler")
                ebs_csi = EBS("EBS CSI\nDriver")
        
        # Connection flows
        developer >> Edge(label="kubectl") >> eks
        
        # EKS to Workers
        eks >> Edge(label="manages") >> [worker_a, worker_b]
        
        # Security
        iam >> Edge(label="auth") >> [eks, worker_a, worker_b]
        kms >> Edge(label="encrypt") >> eks
        
        # Container Registry
        [worker_a, worker_b] >> Edge(label="pull images") >> ecr
        
        # Monitoring
        [eks, worker_a, worker_b] >> Edge(label="logs/metrics") >> cloudwatch
        cloudwatch >> Edge(label="alerts") >> sns
        
        # Network
        igw >> nat_gw >> [worker_a, worker_b]
        
        # Add-ons
        [alb, autoscaler, ebs_csi] >> eks

def create_simplified_diagram():
    """Create a simplified EKS diagram"""
    
    with Diagram("Simple EKS Architecture", 
                 show=False, 
                 direction="LR", 
                 filename="simple-eks-architecture",
                 outformat="png"):
        
        # User
        user = User("Developer")
        
        # AWS Cloud
        with Cluster("AWS Cloud"):
            
            # Core Services
            iam = IAM("IAM")
            ecr = General("ECR")
            cw = Cloudwatch("CloudWatch")
            
            # VPC
            with Cluster("VPC"):
                # EKS
                eks = EKS("EKS\nControl Plane")
                
                # Worker Nodes
                with Cluster("Worker Nodes"):
                    node1 = EC2("Node 1\nt3.medium")
                    node2 = EC2("Node 2\nt3.medium")
        
        # Connections
        user >> eks
        eks >> [node1, node2]
        iam >> eks
        [node1, node2] >> ecr
        [eks, node1, node2] >> cw

def create_network_focused_diagram():
    """Create a network-focused EKS diagram"""
    
    with Diagram("EKS Network Architecture", 
                 show=False, 
                 direction="TB", 
                 filename="eks-network-architecture",
                 outformat="png"):
        
        user = User("Developer")
        
        with Cluster("AWS Region (us-west-2)"):
            
            with Cluster("VPC (10.0.0.0/16)"):
                
                igw = InternetGateway("Internet Gateway")
                
                with Cluster("Availability Zone A"):
                    pub_a = PublicSubnet("Public\n10.0.1.0/24")
                    nat = NATGateway("NAT Gateway")
                    priv_a = PrivateSubnet("Private\n10.0.10.0/24")
                    node_a = EC2("EKS Node A")
                
                with Cluster("Availability Zone B"):
                    pub_b = PublicSubnet("Public\n10.0.2.0/24")
                    priv_b = PrivateSubnet("Private\n10.0.20.0/24")
                    node_b = EC2("EKS Node B")
                
                eks = EKS("EKS Control Plane\n(Multi-AZ)")
            
            # External services
            ecr = General("ECR")
            cw = Cloudwatch("CloudWatch")
        
        # Connections - Fixed the list >> list issue
        user >> igw >> nat
        nat >> node_a
        nat >> node_b
        eks >> node_a
        eks >> node_b
        node_a >> ecr
        node_b >> ecr
        node_a >> cw
        node_b >> cw

if __name__ == "__main__":
    print("Generating EKS Architecture Diagrams...")
    
    try:
        print("1. Creating Well-Architected diagram...")
        create_eks_architecture()
        print("   ✅ eks-well-architected-architecture.png created")
        
        print("2. Creating simplified diagram...")
        create_simplified_diagram()
        print("   ✅ simple-eks-architecture.png created")
        
        print("3. Creating network-focused diagram...")
        create_network_focused_diagram()
        print("   ✅ eks-network-architecture.png created")
        
        print("\n🎉 All diagrams generated successfully!")
        print("📁 Check the current directory for the PNG files.")
        
    except Exception as e:
        print(f"❌ Error generating diagrams: {e}")
        print("Make sure you have the 'diagrams' package installed:")
        print("pip install diagrams")
