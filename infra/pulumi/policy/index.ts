import * as aws from "@pulumi/aws";
import { PolicyPack, validateResourceOfType } from "@pulumi/policy";

const PUERTOS_PUBLICOS_PERMITIDOS = [80, 443];

new PolicyPack("asistencia-seguridad", {
  policies: [
    {
      name: "ingreso-publico-solo-web",
      description: "Solo los puertos 80 y 443 pueden abrirse a 0.0.0.0/0 (SSH y MySQL nunca).",
      enforcementLevel: "mandatory",
      validateResource: validateResourceOfType(aws.vpc.SecurityGroupIngressRule, (regla, _args, reportViolation) => {
        if (regla.cidrIpv4 !== "0.0.0.0/0") return;
        const soloWeb =
          regla.fromPort !== undefined &&
          regla.fromPort === regla.toPort &&
          PUERTOS_PUBLICOS_PERMITIDOS.includes(regla.fromPort);
        if (!soloWeb) {
          reportViolation(
            `Regla abierta a todo Internet en ${regla.ipProtocol}/${regla.fromPort ?? "todos"}-${regla.toPort ?? "todos"}. Restringe el CIDR.`,
          );
        }
      }),
    },
    {
      name: "ec2-imdsv2-obligatorio",
      description: "Las instancias EC2 deben exigir IMDSv2 (protege las credenciales del metadata service).",
      enforcementLevel: "mandatory",
      validateResource: validateResourceOfType(aws.ec2.Instance, (instancia, _args, reportViolation) => {
        if (instancia.metadataOptions?.httpTokens !== "required") {
          reportViolation("Configura metadataOptions.httpTokens = \"required\".");
        }
      }),
    },
    {
      name: "ec2-disco-cifrado",
      description: "El disco raíz de cada EC2 debe estar cifrado.",
      enforcementLevel: "mandatory",
      validateResource: validateResourceOfType(aws.ec2.Instance, (instancia, _args, reportViolation) => {
        if (instancia.rootBlockDevice?.encrypted !== true) {
          reportViolation("Configura rootBlockDevice.encrypted = true.");
        }
      }),
    },
    {
      name: "ec2-etiquetas-requeridas",
      description: "Toda EC2 debe llevar las etiquetas Project y ManagedBy.",
      enforcementLevel: "advisory",
      validateResource: validateResourceOfType(aws.ec2.Instance, (instancia, _args, reportViolation) => {
        const etiquetas = instancia.tags ?? {};
        for (const clave of ["Project", "ManagedBy"]) {
          if (!(clave in etiquetas)) reportViolation(`Falta la etiqueta ${clave}.`);
        }
      }),
    },
  ],
});
