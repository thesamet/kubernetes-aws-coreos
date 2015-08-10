Kubernetes on AWS with CoreOS through CloudFormations
-----------------------------------------------------

This repository provides an easy way to set up a fully working Kubernetes
cluster on EC2 machines running CoreOS.

*Highlights (things that are actually working out of the box):*

- Uses an existing provided VPC instead of creating a new one.
- Secure token authentication
- EBS volume mounts
- ELB creation works (if you have just one subnet, upsteam bug)
- SkyDNS works

*Lowlights:*

- Custom Kubernetes binaries are used instead of the official ones. Mainly, for
  merging [this PR](https://github.com/GoogleCloudPlatform/kubernetes/pull/8530)
  since otherwise EBS mounting will not work. However, you can customize where
  the release is downloaded from by passing a parameter to the template (see
  the template for more information)

*Note:*

- All EC2 instances created will have only private IPs. You will need to have
  some way of connecting to them (some other machine in your VPC with a
  public IP)

Getting Started
---------------

Download the template:

```
curl https://raw.githubusercontent.com/thesamet/kubernetes-aws-coreos/master/output/cloudformation-template.json -o cloudformation-template.json
```

Launch it with this command (don't forget to replace <things> with actual
values):

```
aws cloudformation create-stack --stack-name kubernetes \
    --region us-west-2 \
    --template-body file://cloudformation-template.json \
    --capabilities CAPABILITY_IAM \
    --parameters \
    ParameterKey=VpcId,ParameterValue=<vpc-id> \
    ParameterKey=SubnetId,ParameterValue=<subnet-id> \
    ParameterKey=SubnetAZ,ParameterValue=<subnet-az> \
    ParameterKey=KeyPair,ParameterValue=<keypair>
```

On the machine you intend to access your cluster from (your computer, if it
can reached the master through its private IP).

1. Download kubectl (this version of kubectl matches the default
version being installed by the CloudFormation template):

```
curl http://nadavsr-kubernetes-build.s3-website-us-west-2.amazonaws.com/kubectl -o
    kubectl && chmod +x ./kubectl
```

2. Find the Kubernetes master IP (look for it in the EC2 console). Wait for it to be up.
Then, copy your kubeconfig from it:

```
scp core@<master_ip>:kubeconfig ~/.kube/config
```

3. Try it out:

`./kubectl version`

`./kubectl get nodes`

