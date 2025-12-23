#!/bin/bash
REGION="eu-central-1"

echo "=============================="
echo " AWS COST SCAN – $REGION"
echo "=============================="

echo -e "\n🔥 NAT Gateways"
aws ec2 describe-nat-gateways --region $REGION \
  --query 'NatGateways[*].{Id:NatGatewayId,State:State}' --output table

echo -e "\n🔥 Elastic IPs"
aws ec2 describe-addresses --region $REGION \
  --query 'Addresses[*].{IP:PublicIp,Associated:AssociationId}' --output table

echo -e "\n🔥 EC2 Instances"
aws ec2 describe-instances --region $REGION \
  --query 'Reservations[*].Instances[*].{Id:InstanceId,State:State.Name,Type:InstanceType}' --output table

echo -e "\n🔥 EBS Volumes"
aws ec2 describe-volumes --region $REGION \
  --query 'Volumes[*].{Id:VolumeId,State:State,Size:Size}' --output table

echo -e "\n🔥 Load Balancers"
aws elbv2 describe-load-balancers --region $REGION \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,Type:Type,State:State.Code}' --output table

echo -e "\n🔥 VPN Connections"
aws ec2 describe-vpn-connections --region $REGION \
  --query 'VpnConnections[*].{Id:VpnConnectionId,State:State}' --output table

echo -e "\n🔥 Transit Gateways"
aws ec2 describe-transit-gateways --region $REGION \
  --query 'TransitGateways[*].{Id:TransitGatewayId,State:State}' --output table

echo -e "\n🔥 RDS"
aws rds describe-db-instances --region $REGION \
  --query 'DBInstances[*].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass}' --output table

echo -e "\n🔥 ElastiCache"
aws elasticache describe-cache-clusters --region $REGION \
  --query 'CacheClusters[*].{Id:CacheClusterId,Status:CacheClusterStatus,NodeType:CacheNodeType}' --output table

echo -e "\n🔥 OpenSearch"
aws opensearch list-domain-names --region $REGION --output table

