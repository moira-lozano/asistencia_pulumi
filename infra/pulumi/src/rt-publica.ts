import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const rt_publica = new aws.ec2.RouteTable("rt-publica", {
    region: "us-east-1",
    routes: [{
        cidrBlock: "0.0.0.0/0",
        gatewayId: "igw-0ba81df8e3f386dc7",
    }],
    tags: {
        Name: "rt-publica-ecommerce",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});