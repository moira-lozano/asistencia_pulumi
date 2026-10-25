import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const rt_secundaria = new aws.ec2.RouteTable("rt-secundaria", {
    region: "us-east-1",
    routes: [
        {
            cidrBlock: "0.0.0.0/0",
            networkInterfaceId: "eni-0714287fe4e425d8c",
        },
        {
            cidrBlock: "10.8.0.0/24",
            networkInterfaceId: "eni-08f5499e492c90b98",
        },
    ],
    tags: {
        Name: "rt-privada-ecommerce",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});