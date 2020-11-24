# terraform-scripts

This repository contains sample Terraform scripts written for AWS. Right now, it only contains the `getting-started` scripts I wrote following the [Hashicorp's 'Get Started - AWS' guide](https://learn.hashicorp.com/collections/terraform/aws-get-started), and the `vpc` scripts I wrote to launch a network setup identical to the one created by the AWS CloudFormation script: [Digipie/nodejs-mysql-cloudformation/vpc.cfn.yml](https://github.com/DigiPie/nodejs-mysql-cloudformation/blob/main/vpc.cfn.yml).

I will update it to include more Terraform scripts for AWS and also GCP in future.

## Design decisions

### Why not inline security group rule

**Context:** Terraform currently provides both a standalone Security Group Rule resource (a single ingress or egress rule), and a Security Group resource with ingress and egress rules defined in-line. At this time you cannot use a Security Group with in-line rules in conjunction with any Security Group Rule resources. Doing so will cause a conflict of rule settings and will overwrite rules.

**Choice 1:** Use in-line rules for better logical grouping of relevant resources: i.e. a security group and all its rules in one place.

**Choice 2 (Chosen):** Use standalone rules which result in loose coupling but also weaker logical grouping of relevant resources.

**Decision:** Unfortunately, given that the security group rules reference each other, in-line rules will result in circular dependencies between said security groups which will cause Terraform to fail. As such, the security groups must first be created without their rules, which will then be created as standalone resources. Hence **Choice 2** was chosen.