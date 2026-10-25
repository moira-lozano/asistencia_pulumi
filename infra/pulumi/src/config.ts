
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();

export const project = "asistencia";
export const suffix = "asistencia";
export const options: pulumi.CustomResourceOptions = {
    protect: true,
};

export const tags = (name: string) => ({
    Project: project,
    Name: name,
    ManagedBy: "Pulumi",
});
