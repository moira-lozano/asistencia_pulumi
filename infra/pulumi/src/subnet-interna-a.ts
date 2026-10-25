import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_interna_a = new aws.ec2.Subnet("subnet-interna-a", {
    availabilityZone: "us-east-1a",
    cidrBlock: "10.0.6.0/26",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-datos-zona-a",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});