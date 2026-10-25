import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const asistencia_vpc = new aws.ec2.Vpc("asistencia-vpc", {
    cidrBlock: "10.0.0.0/16",
    instanceTenancy: "default",
    region: "us-east-1",
    tags: {
        Name: "vpc-ecommerce-lab",
    },
}, {
    protect: true,
});