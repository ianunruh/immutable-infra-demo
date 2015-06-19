# immutable-infra-demo

Demonstrates usage of Ansible, Terraform, Packer, and Consul to deploy applications in an immutable fashion

## Prerequisites

The following components were used when developing and testing this demo:

* Ansible v1.9.1
* Packer v0.7.5
* Terraform v0.5.2

## Usage

**WARNING** This will incur charges on your AWS account. Be sure to use `terraform destroy` when finished.

```bash
git clone https://github.com/ianunruh/immutable-infra-demo.git
cd immutable-infra-demo/services/consul

# Export AWS credentials and region
export AWS_ACCESS_KEY_ID=XXX
export AWS_SECRET_ACCESS_KEY=YYY

# Build the Consul AMI
packer build packer.json

# Configure Terraform
cat <<EOF | tee terraform.tfvars
consul_ami = "ami-ZZZ"
key_name = "WWW"
EOF

# Run Terraform
terraform apply

# Verify Consul deployed successfully
ssh -A ubuntu@ec2-XXX.us-west-1.compute.amazonaws.com
ssh consul-bootstrap.example.com
consul members
ping -c4 consul.service.consul
```
