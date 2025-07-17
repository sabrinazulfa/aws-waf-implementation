#!/bin/bash

# AWS WAF AI/ML Enhanced Demo Deployment Script
# Deploys complete infrastructure with AI/ML capabilities

set -e

# Configuration
REGION=${1:-"us-east-1"}
KEY_PAIR=${2:-""}
ENVIRONMENT=${3:-"ai-ml-demo"}
ENABLE_BOT_CONTROL=${4:-"true"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🚀 AWS WAF AI/ML Enhanced Demo Deployment${NC}"
echo "=========================================="
echo "Region: $REGION"
echo "Key Pair: $KEY_PAIR"
echo "Environment: $ENVIRONMENT"
echo "Bot Control: $ENABLE_BOT_CONTROL"
echo "=========================================="

# Validate inputs
if [[ -z "$KEY_PAIR" ]]; then
    echo -e "${RED}❌ Error: EC2 Key Pair name is required${NC}"
    echo "Usage: $0 <region> <key-pair-name> [environment] [enable-bot-control]"
    echo "Example: $0 us-east-1 my-key-pair ai-ml-demo true"
    exit 1
fi

# Check AWS CLI configuration
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: AWS CLI not configured or no valid credentials${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI configured successfully${NC}"

# Verify key pair exists
if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR" --region "$REGION" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Key pair '$KEY_PAIR' not found in region '$REGION'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Key pair '$KEY_PAIR' found${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Step 1: Deploy Enhanced Application Infrastructure
echo -e "\n${BLUE}📦 Step 1: Deploying Enhanced Application Infrastructure${NC}"

# Check if basic infrastructure template exists, if not create it
BASIC_TEMPLATE="$PROJECT_DIR/cloudformation/01-enhanced-app.yaml"
if [[ ! -f "$BASIC_TEMPLATE" ]]; then
    echo -e "${YELLOW}⚠️  Creating enhanced application template${NC}"
    cat > "$BASIC_TEMPLATE" << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Enhanced Application Infrastructure for AI/ML WAF Demo'

Parameters:
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access
  
  Environment:
    Type: String
    Default: ai-ml-demo
    Description: Environment name

Resources:
  # VPC and Networking (simplified for demo)
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-vpc'

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-public-subnet-1'

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-public-subnet-2'

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-igw'

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-public-rt'

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRouteTable

  PublicSubnetRouteTableAssociation2:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref PublicRouteTable

  # Security Groups
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Application Load Balancer
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-alb-sg'

  EC2SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for EC2 instances
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3000
          ToPort: 3000
          SourceSecurityGroupId: !Ref ALBSecurityGroup
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-ec2-sg'

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub '${Environment}-alb'
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-alb'

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub '${Environment}-tg'
      Port: 3000
      Protocol: HTTP
      VpcId: !Ref VPC
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-tg'

  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  # Launch Template for Enhanced App
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: !Sub '${Environment}-launch-template'
      LaunchTemplateData:
        ImageId: ami-0c02fb55956c7d316  # Amazon Linux 2 AMI
        InstanceType: t3.micro
        KeyName: !Ref KeyPairName
        SecurityGroupIds:
          - !Ref EC2SecurityGroup
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y nodejs npm git
            
            # Clone and setup enhanced application
            cd /home/ec2-user
            git clone https://github.com/your-repo/aws-summit-lightning-talk.git || echo "Using local files"
            
            # Create enhanced app directory
            mkdir -p /home/ec2-user/ai-ml-app
            cd /home/ec2-user/ai-ml-app
            
            # Create package.json
            cat > package.json << 'PACKAGE_EOF'
            {
              "name": "aws-waf-ai-ml-demo",
              "version": "2.0.0",
              "main": "app.js",
              "dependencies": {
                "express": "^4.18.2",
                "sqlite3": "^5.1.6",
                "express-rate-limit": "^6.7.0"
              }
            }
            PACKAGE_EOF
            
            # Install dependencies
            npm install
            
            # Create enhanced app (simplified version for CloudFormation)
            cat > app.js << 'APP_EOF'
            const express = require('express');
            const rateLimit = require('express-rate-limit');
            const app = express();
            const port = 3000;
            
            app.use(express.json());
            app.use(express.urlencoded({ extended: true }));
            
            // Enhanced logging
            app.use((req, res, next) => {
                console.log(JSON.stringify({
                    timestamp: new Date().toISOString(),
                    ip: req.ip,
                    method: req.method,
                    url: req.url,
                    userAgent: req.get('User-Agent'),
                    headers: req.headers
                }));
                next();
            });
            
            const limiter = rateLimit({
                windowMs: 15 * 60 * 1000,
                max: 100
            });
            app.use('/api/', limiter);
            
            app.get('/', (req, res) => {
                res.send('<h1>AWS WAF AI/ML Enhanced Demo</h1><p>Application is running!</p>');
            });
            
            app.get('/api/bot-challenge', (req, res) => {
                const userAgent = req.get('User-Agent') || '';
                let botScore = 0.0;
                
                if (userAgent.toLowerCase().includes('bot')) botScore += 0.5;
                if (!userAgent || userAgent.length < 10) botScore += 0.4;
                
                res.json({
                    botScore: botScore,
                    userAgent: userAgent,
                    timestamp: new Date().toISOString()
                });
            });
            
            app.post('/api/login-attempt', (req, res) => {
                const { username, password } = req.body;
                let riskScore = Math.random() * 0.5;
                
                if (password && password.length < 6) riskScore += 0.3;
                
                res.json({
                    username: username,
                    riskScore: riskScore,
                    timestamp: new Date().toISOString()
                });
            });
            
            app.post('/api/transaction', (req, res) => {
                const { amount } = req.body;
                let fraudScore = Math.random() * 0.3;
                
                if (amount > 1000) fraudScore += 0.2;
                if (amount > 5000) fraudScore += 0.3;
                
                res.json({
                    amount: amount,
                    fraudScore: fraudScore,
                    timestamp: new Date().toISOString()
                });
            });
            
            app.listen(port, '0.0.0.0', () => {
                console.log(`Enhanced demo app listening at http://0.0.0.0:${port}`);
            });
            APP_EOF
            
            # Start the application
            chown -R ec2-user:ec2-user /home/ec2-user/ai-ml-app
            cd /home/ec2-user/ai-ml-app
            nohup node app.js > app.log 2>&1 &
            
            # Create systemd service for auto-start
            cat > /etc/systemd/system/ai-ml-demo.service << 'SERVICE_EOF'
            [Unit]
            Description=AI/ML WAF Demo Application
            After=network.target
            
            [Service]
            Type=simple
            User=ec2-user
            WorkingDirectory=/home/ec2-user/ai-ml-app
            ExecStart=/usr/bin/node app.js
            Restart=always
            
            [Install]
            WantedBy=multi-user.target
            SERVICE_EOF
            
            systemctl enable ai-ml-demo
            systemctl start ai-ml-demo

  # Auto Scaling Group
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: !Sub '${Environment}-asg'
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: 1
      MaxSize: 3
      DesiredCapacity: 2
      VPCZoneIdentifier:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      TargetGroupARNs:
        - !Ref TargetGroup
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-instance'
          PropagateAtLaunch: true

Outputs:
  LoadBalancerArn:
    Description: ARN of the Application Load Balancer
    Value: !Ref ApplicationLoadBalancer
    Export:
      Name: !Sub '${Environment}-alb-arn'
  
  LoadBalancerDNS:
    Description: DNS name of the Application Load Balancer
    Value: !GetAtt ApplicationLoadBalancer.DNSName
    Export:
      Name: !Sub '${Environment}-alb-dns'
  
  VPCId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub '${Environment}-vpc-id'
EOF
fi

aws cloudformation deploy \
    --template-file "$BASIC_TEMPLATE" \
    --stack-name "${ENVIRONMENT}-app" \
    --parameter-overrides \
        KeyPairName="$KEY_PAIR" \
        Environment="$ENVIRONMENT" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION"

echo -e "${GREEN}✅ Enhanced application infrastructure deployed${NC}"

# Get ALB ARN for WAF association
ALB_ARN=$(aws cloudformation describe-stacks \
    --stack-name "${ENVIRONMENT}-app" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text)

ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name "${ENVIRONMENT}-app" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

echo -e "${BLUE}📝 Application Load Balancer:${NC}"
echo "  ARN: $ALB_ARN"
echo "  DNS: $ALB_DNS"

# Step 2: Deploy AI/ML Enhanced WAF
echo -e "\n${BLUE}🛡️  Step 2: Deploying AI/ML Enhanced WAF${NC}"

WAF_TEMPLATE="$PROJECT_DIR/cloudformation/02-waf-ai-ml.yaml"
aws cloudformation deploy \
    --template-file "$WAF_TEMPLATE" \
    --stack-name "${ENVIRONMENT}-waf" \
    --parameter-overrides \
        LoadBalancerArn="$ALB_ARN" \
        Environment="$ENVIRONMENT" \
        BotControlEnabled="$ENABLE_BOT_CONTROL" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION"

echo -e "${GREEN}✅ AI/ML Enhanced WAF deployed${NC}"

# Get WAF details
WAF_ACL_ID=$(aws cloudformation describe-stacks \
    --stack-name "${ENVIRONMENT}-waf" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`WebACLId`].OutputValue' \
    --output text)

DASHBOARD_URL=$(aws cloudformation describe-stacks \
    --stack-name "${ENVIRONMENT}-waf" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`DashboardURL`].OutputValue' \
    --output text)

# Step 3: Wait for application to be ready
echo -e "\n${BLUE}⏳ Step 3: Waiting for application to be ready${NC}"
echo "Checking application health..."

for i in {1..30}; do
    if curl -s --connect-timeout 5 "http://$ALB_DNS" > /dev/null; then
        echo -e "${GREEN}✅ Application is responding${NC}"
        break
    else
        echo -n "."
        sleep 10
    fi
    
    if [[ $i -eq 30 ]]; then
        echo -e "\n${YELLOW}⚠️  Application may still be starting up${NC}"
    fi
done

# Step 4: Create attack simulation scripts if they don't exist
echo -e "\n${BLUE}🎯 Step 4: Setting up attack simulation scripts${NC}"

ATTACKS_DIR="$PROJECT_DIR/attacks"
mkdir -p "$ATTACKS_DIR"

# Make sure all attack scripts are executable
find "$ATTACKS_DIR" -name "*.sh" -exec chmod +x {} \;

echo -e "${GREEN}✅ Attack simulation scripts ready${NC}"

# Step 5: Display deployment summary
echo -e "\n${GREEN}🎉 AI/ML Enhanced Demo Deployment Complete!${NC}"
echo "================================================="
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo "  Application URL: http://$ALB_DNS"
echo "  WAF Web ACL ID: $WAF_ACL_ID"
echo "  Bot Control: $ENABLE_BOT_CONTROL"
echo ""
echo -e "${BLUE}🔗 Important URLs:${NC}"
echo "  Application: http://$ALB_DNS"
echo "  CloudWatch Dashboard: $DASHBOARD_URL"
echo "  WAF Console: https://${REGION}.console.aws.amazon.com/wafv2/homev2/web-acl/${WAF_ACL_ID}"
echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "1. Test the application: curl http://$ALB_DNS"
echo "2. Run baseline attacks: cd attacks && ./run-ai-ml-attacks.sh http://$ALB_DNS baseline"
echo "3. Run AI/ML attacks: cd attacks && ./run-ai-ml-attacks.sh http://$ALB_DNS ai-ml-enabled"
echo "4. View metrics in CloudWatch Dashboard"
echo ""
echo -e "${BLUE}🧹 Cleanup:${NC}"
echo "  Run: ./cleanup-ai-ml-demo.sh $REGION $ENVIRONMENT"
echo ""
echo -e "${PURPLE}🚀 Your AI/ML WAF demo is ready for the lightning talk!${NC}"

# Save deployment info
cat > "/tmp/${ENVIRONMENT}-deployment-info.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "environment": "$ENVIRONMENT",
    "region": "$REGION",
    "application_url": "http://$ALB_DNS",
    "alb_arn": "$ALB_ARN",
    "waf_acl_id": "$WAF_ACL_ID",
    "dashboard_url": "$DASHBOARD_URL",
    "bot_control_enabled": "$ENABLE_BOT_CONTROL",
    "stacks": [
        "${ENVIRONMENT}-app",
        "${ENVIRONMENT}-waf"
    ]
}
EOF

echo -e "${BLUE}📄 Deployment info saved to: /tmp/${ENVIRONMENT}-deployment-info.json${NC}"
