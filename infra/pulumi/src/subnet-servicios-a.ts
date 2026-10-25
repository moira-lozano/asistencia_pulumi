import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const subnet_servicios_a = new aws.ec2.Subnet("subnet-servicios-a", {
    availabilityZone: "us-east-1a",
    cidrBlock: "10.0.4.0/24",
    privateDnsHostnameTypeOnLaunch: "ip-name",
    region: "us-east-1",
    tags: {
        Name: "sn-app-zona-a ",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});