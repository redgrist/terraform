#!/bin/bash

REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

echo "========================================"
echo " AWS COST SCAN – ALL REGIONS"
echo "========================================"

for REGION in $REGIONS; do
  echo
  echo "########################################"
  echo " REGION: $REGION"
  echo "########################################"

  echo -e "\n🔥 NAT Gateways"
  aws ec2 describe-nat-gateways --region $REGION \
    --query 'NatGateways[*].{Id:NatGatewayId,State:State}' \
    --output table 2>/dev/null

  echo -e "\n🔥 Elastic IPs"
  aws ec2 describe-addresses --region $REGION \
    --query 'Addresses[*].{IP:PublicIp,Associated:AssociationId}' \
    --output table 2>/dev/null

  echo -e "\n🔥 EC2 Instances"
  aws ec2 describe-instances --region $REGION \
    --query 'Reservations[*].Instances[*].{Id:InstanceId,State:State.Name,Type:InstanceType}' \
    --output table 2>/dev/null

  echo -e "\n🔥 EBS Volumes"
  aws ec2 describe-volumes --region $REGION \
    --query 'Volumes[*].{Id:VolumeId,State:State,Size:Size}' \
    --output table 2>/dev/null

  echo -e "\n🔥 Load Balancers"
  aws elbv2 describe-load-balancers --region $REGION \
    --query 'LoadBalancers[*].{Name:LoadBalancerName,Type:Type,State:State.Code}' \
    --output table 2>/dev/null

  echo -e "\n🔥 VPN Connections"
  aws ec2 describe-vpn-connections --region $REGION \
    --query 'VpnConnections[*].{Id:VpnConnectionId,State:State}' \
    --output table 2>/dev/null

  echo -e "\n🔥 Transit Gateways"
  aws ec2 describe-transit-gateways --region $REGION \
    --query 'TransitGateways[*].{Id:TransitGatewayId,State:State}' \
    --output table 2>/dev/null

  echo -e "\n🔥 RDS"
  aws rds describe-db-instances --region $REGION \
    --query 'DBInstances[*].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass}' \
    --output table 2>/dev/null

  echo -e "\n🔥 ElastiCache"
  aws elasticache describe-cache-clusters --region $REGION \
    --query 'CacheClusters[*].{Id:CacheClusterId,Status:CacheClusterStatus,NodeType:CacheNodeType}' \
    --output table 2>/dev/null

  echo -e "\n🔥 OpenSearch"
  aws opensearch list-domain-names --region $REGION \
    --output table 2>/dev/null
done

