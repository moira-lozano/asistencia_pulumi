
import * as aws from "@pulumi/aws";

export const client = aws.ec2.getInstance({
    instanceId: "i-021e80f0aada3727b",
});

export const backend = aws.ec2.getInstance({
    instanceId: "i-0709dc12e57c36214",
});
