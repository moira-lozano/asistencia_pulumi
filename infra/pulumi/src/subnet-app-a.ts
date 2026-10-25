import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_app_a = new aws.ec2.Subnet("subnet-app-a", {
    availabilityZone: "us-east-1a",
    cidrBlock: "10.0.0.0/23",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-web-zona-a ",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});