Kubernetes on AWS with CoreOS through CloudFormations
-----------------------------------------------------

This repository provides an easy way to set up a fully working Kubernetes
cluster on EC2 machines running CoreOS.

Highlights (things that are actually working out of the box)

- Uses an existing provided VPC instead of creating a new one.
- Secure token authentication
- EBS volume mounts (using a custom kubernetes build that includes https://github.com/GoogleCloudPlatform/kubernetes/pull/8530)
- ELB creation works (if you have just one subnet, upsteam bug)
- SkyDNS works

Note:

- All EC2 instances created will have only private IPs. You will need to have
  some way of connecting to them.

Getting Started
---------------

