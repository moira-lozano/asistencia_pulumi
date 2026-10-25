import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const sg_back = new aws.ec2.SecurityGroup("sg-back", {
    description: "launch-wizard-3 created 2026-10-16T02:09:28.917Z",
    egress: [{
        cidrBlocks: ["0.0.0.0/0"],
        fromPort: 0,
        protocol: "-1",
        toPort: 0,
    }],
    ingress: [
        {
            cidrBlocks: ["0.0.0.0/0"],
            fromPort: 8090,
            protocol: "tcp",
            toPort: 8090,
        },
        {
            cidrBlocks: ["189.28.75.151/32"],
            fromPort: 22,
            protocol: "tcp",
            toPort: 22,
        },
    ],
    name: "launch-wizard-3",
    region: "us-east-1",
    vpcId: "vpc-060b642494b60df97",
}, {
    protect: true,
});