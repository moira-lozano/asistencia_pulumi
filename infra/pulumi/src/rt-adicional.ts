import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const rt_adicional = new aws.ec2.RouteTable("rt-adicional", {
    region: "us-east-1",
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});