import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_servicios_b = new aws.ec2.Subnet("subnet-servicios-b", {
    availabilityZone: "us-east-1b",
    cidrBlock: "10.0.5.0/24",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-app-zona-b",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});