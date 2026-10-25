import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const asistencia_igw = new aws.ec2.InternetGateway("asistencia-igw", {
    region: "us-east-1",
    tags: {
        Name: "igw-ecommerce",
    },
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});