import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_interna_b = new aws.ec2.Subnet("subnet-interna-b", {
    availabilityZone: "us-east-1b",
    cidrBlock: "10.0.6.64/26",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-datos-zona-b",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});