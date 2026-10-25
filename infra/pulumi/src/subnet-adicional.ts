import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_adicional = new aws.ec2.Subnet("subnet-adicional", {
    availabilityZone: "us-east-1a",
    cidrBlock: "10.0.7.0/28",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-vpn-zona-a",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});