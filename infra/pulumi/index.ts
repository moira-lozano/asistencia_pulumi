
import { srv_front } from "./src/front";
import { srv_back } from "./src/backend";
import { sg_front } from "./src/sg-front";
import { sg_back } from "./src/sg-back";

export const servers = {
    client: {
        id: srv_front.id,
        public_ip: srv_front.publicIp,
        public_dns: srv_front.publicDns,
        private_ip: srv_front.privateIp,
    },
    backend: {
        id: srv_back.id,
        public_ip: srv_back.publicIp,
        private_ip: srv_back.privateIp,
    },
};

export const ssh_commands = {
    client: srv_front.publicIp.apply(
        ip => `ssh ec2-user@${ip || "<sin-ip-publica>"}`
    ),
    backend: srv_back.publicIp.apply(
        ip => `ssh ec2-user@${ip || "<sin-ip-publica>"}`
    ),
};

export const security_groups = {
    frontend: sg_front.id,
    backend: sg_back.id,
};
