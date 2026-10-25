import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export const srv_back = new aws.ec2.Instance("srv-back", {
    ami: "ami-0b6d9d3d33ba97d99",
    associatePublicIpAddress: true,
    availabilityZone: "us-east-1a",
    capacityReservationSpecification: {
        capacityReservationPreference: "open",
    },
    cpuOptions: {
        coreCount: 1,
        threadsPerCore: 2,
    },
    creditSpecification: {
        cpuCredits: "unlimited",
    },
    ebsOptimized: true,
    instanceInitiatedShutdownBehavior: "stop",
    instanceType: aws.ec2.InstanceType.T3_Micro,
    keyName: "CLAVES",
    maintenanceOptions: {
        autoRecovery: "default",
    },
    metadataOptions: {
        httpEndpoint: "enabled",
        httpProtocolIpv6: "disabled",
        httpPutResponseHopLimit: 2,
        httpTokens: "required",
        instanceMetadataTags: "disabled",
    },
    privateDnsNameOptions: {
        hostnameType: "ip-name",
    },
    privateIp: "10.0.1.134",
    region: "us-east-1",
    rootBlockDevice: {
        iops: 3000,
        throughput: 125,
        volumeSize: 8,
        volumeType: "gp3",
    },
    subnetId: "subnet-09ba9af789798ee75",
    tags: {
        Name: "srv-back",
    },
    tenancy: aws.ec2.Tenancy.Default,
    vpcSecurityGroupIds: ["sg-0c8c28f2beda67529"],
}, {
    protect: true,
});