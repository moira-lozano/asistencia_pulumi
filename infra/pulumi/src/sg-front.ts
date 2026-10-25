import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const sg_front = new aws.ec2.SecurityGroup("sg-front", {
    description: "launch-wizard-4 created 2026-10-16T02:13:59.973Z",
    egress: [{
        cidrBlocks: ["0.0.0.0/0"],
        fromPort: 0,
        protocol: "-1",
        toPort: 0,
    }],
    ingress: [
        {
            cidrBlocks: ["0.0.0.0/0"],
            fromPort: 443,
            protocol: "tcp",
            toPort: 443,
        },
        {
            cidrBlocks: ["0.0.0.0/0"],
            fromPort: 80,
            protocol: "tcp",
            toPort: 80,
        },
        {
            cidrBlocks: ["189.28.75.151/32"],
            fromPort: 22,
            protocol: "tcp",
            toPort: 22,
        },
    ],
    name: "launch-wizard-4",
    region: "us-east-1",
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});