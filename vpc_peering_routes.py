import boto3
import logging
import os

route_table_id = os.environ.get('ROUTE_TABLE_ID')

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def lambda_handler(event, context):
    logger.info(event)
    vpc_peering_connection_id = event['detail']['responseElements']['vpcPeeringConnection']['vpcPeeringConnectionId']
    accepter_vpc_id = event['detail']['responseElements']['vpcPeeringConnection']['accepterVpcInfo']['vpcId']
    requester_vpc_cidr = event['detail']['responseElements']['vpcPeeringConnection']['requesterVpcInfo']['cidrBlock']
    ec2_client = boto3.client('ec2')

    ec2_client.create_route(
            DestinationCidrBlock=requester_vpc_cidr,
            VpcPeeringConnectionId=vpc_peering_connection_id,
            RouteTableId=route_table_id
        )
    return {
        'statusCode': 200,
        'body': 'Route added successfully'
    }
