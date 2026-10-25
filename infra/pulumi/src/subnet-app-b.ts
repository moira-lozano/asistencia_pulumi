import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_app_b = new aws.ec2.Subnet("subnet-app-b", {
    availabilityZone: "us-east-1b",
    cidrBlock: "10.0.2.0/23",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-web-zona-b ",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});