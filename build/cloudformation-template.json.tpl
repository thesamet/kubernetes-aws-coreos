{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "Kubernetes 1.0.1 on EC2 powered by CoreOS 681.2.0 (stable)",
  "Mappings": {
    "RegionMap": {
      "eu-central-1" : {
        "AMI" :	"ami-bececaa3"
      },
      "ap-northeast-1" : {
        "AMI" :	"ami-f2338ff2"
      },
      "us-gov-west-1" : {
        "AMI" :	"ami-c75033e4"
      },
      "sa-east-1" : {
        "AMI" :	"ami-11e9600c"
      },
      "ap-southeast-2" : {
        "AMI" :	"ami-8f88c8b5"
      },
      "ap-southeast-1" : {
        "AMI" :	"ami-b6d8d4e4"
      },
      "us-east-1" : {
        "AMI" :	"ami-3d73d356"
      },
      "us-west-2" : {
        "AMI" :	"ami-85ada4b5"
      },
      "us-west-1" : {
        "AMI" :	"ami-1db04f59"
      },
      "eu-west-1" : {
        "AMI" :	"ami-0e104179"
      }
    }
  },
  "Parameters": {
    "MasterInstanceType": {
      "Description": "EC2 HVM instance type (m3.medium, etc) for master.",
      "Type": "String",
      "Default": "t2.micro"
    },
    "MinionInstanceType": {
      "Description": "EC2 HVM instance type (m3.medium, etc) for minions.",
      "Type": "String",
      "Default": "m3.medium"
    },
    "ClusterSize": {
      "Description": "Number of nodes in cluster (2-12).",
      "Default": "2",
      "MinValue": "2",
      "MaxValue": "12",
      "Type": "Number"
    },
    "KeyPair": {
      "Description": "The name of an EC2 Key Pair to allow SSH access to the instance.",
      "Type": "AWS::EC2::KeyPair::KeyName"
    },
    "VpcId": {
      "Description": "The ID of the VPC to launch into.",
      "Type": "AWS::EC2::VPC::Id"
    },
    "SubnetId": {
      "Description": "The ID of the subnet to launch into (that must be within the supplied VPC)",
      "Type": "AWS::EC2::Subnet::Id"
    },
    "SubnetAZ": {
      "Description": "The availability zone of the subnet supplied (for example eu-west-1a)",
      "Type": "String"
    },
    "AllowSSHFrom": {
      "Description": "The net block (CIDR) that SSH is available to.",
      "Default": "0.0.0.0/0",
      "Type": "String"
    },
    "AllowHTTPSFrom": {
      "Description": "The net block (CIDR) that HTTPS is available to.",
      "Default": "0.0.0.0/0",
      "Type": "String"
    },
    "AllowServiceAccessFrom": {
      "Description": "The net block (CIDR) that HTTPS is available to.",
      "Default": "0.0.0.0/0",
      "Type": "String"
    },
    "ExternalAccessSecurityGroupId": {
      "Description": "Optional security group id that is allowed to access exposed services",
      "Default": "NONE",
      "Type": "String"
    },
    "ManagedMinionPolicyArn": {
      "Description": "Managed ARNs to apply to the minion role.",
      "Type": "String",
      "Default": "NONE"
    },
    "KubernetesBinaries": {
      "Description": "URL to download Kubenetes binaries from.",
      "Type": "String",
      "Default": "http://nadavsr-kubernetes-build.s3-website-us-west-2.amazonaws.com"
    }
  },
  "Conditions": {
    "UseEC2Classic": {
        "Fn::Equals": [{"Ref": "VpcId"}, ""]},
    "NoExternalAccessSecurityGroupId": {
        "Fn::Equals": [{"Ref": "ExternalAccessSecurityGroupId"}, "NONE"]},
    "NoManagedMinionPolicyArn": {
        "Fn::Equals": [{"Ref": "ManagedMinionPolicyArn"}, "NONE"]
    }
  },
  "Resources": {
    "KubernetesMinionRole": {
        "Type" : "AWS::IAM::Role",
        "Properties" : {
            "AssumeRolePolicyDocument": {
                "Version" : "2012-10-17",
                "Statement": [ {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": [ "ec2.amazonaws.com" ]
                    },
                    "Action": [ "sts:AssumeRole" ]
                } ]
            },
            "Policies": [ {
                "PolicyName" : "KubernetesMinionPolicy",
                "PolicyDocument" : {
                    "Version": "2012-10-17",
                    "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": "s3:*",
                        "Resource": [
                            "arn:aws:s3:::kubernetes-*"
                            ]
                    },
                    {
                        "Effect": "Allow",
                        "Action": "ec2:Describe*",
                        "Resource": "*"
                    },
                    {
                        "Effect": "Allow",
                        "Action": "ec2:AttachVolume",
                        "Resource": "*"
                    },
                    {
                        "Effect": "Allow",
                        "Action": "ec2:DetachVolume",
                        "Resource": "*"
                    }
                    ]
                }
            }],
            "ManagedPolicyArns": {
                "Fn::If": [
                    "NoManagedMinionPolicyArn",
                    {"Ref": "AWS::NoValue"},
                    [{"Ref": "ManagedMinionPolicyArn"}]
                ]}
        }
    },
    "KubernetesMasterRole": {
        "Type" : "AWS::IAM::Role",
        "Properties" : {
            "AssumeRolePolicyDocument": {
                "Version" : "2012-10-17",
                "Statement": [ {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": [ "ec2.amazonaws.com" ]
                    },
                    "Action": [ "sts:AssumeRole" ]
                } ]
            },
            "Policies": [ {
                "PolicyName" : "KubernitionMasterPolicy",
                "PolicyDocument" : {
                    "Version": "2012-10-17",
                    "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": ["ec2:*"],
                        "Resource": ["*"]
                    },
                    {
                        "Effect": "Allow",
                        "Action": ["elasticloadbalancing:*"],
                        "Resource": ["*"]
                    },
                    {
                        "Effect": "Allow",
                        "Action": "s3:*",
                        "Resource": [
                            "arn:aws:s3:::kubernetes-*"
                        ]
                    }
                    ]
                }
            }]
        }
    },
    "KubernetesMasterInstanceProfile": {
        "Type": "AWS::IAM::InstanceProfile",
        "Properties": {
            "Roles": [ {
                "Ref": "KubernetesMasterRole"
            } ]
        }
    },
    "KubernetesMinionInstanceProfile": {
        "Type": "AWS::IAM::InstanceProfile",
        "Properties": {
            "Roles": [ {
                "Ref": "KubernetesMinionRole"
            } ]
        }
    },
    "KubernetesSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "VpcId": {"Fn::If": ["UseEC2Classic", {"Ref": "AWS::NoValue"}, {"Ref": "VpcId"}]},
        "GroupDescription": "Kubernetes SecurityGroup",
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "CidrIp": {"Ref": "AllowSSHFrom"}
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIp": {"Ref": "AllowHTTPSFrom"}
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "30000",
            "ToPort": "32767",
            "CidrIp": {"Ref": "AllowServiceAccessFrom"}
          },
          {"Fn::If": ["NoExternalAccessSecurityGroupId",
          {"Ref" : "AWS::NoValue"},
          {
            "IpProtocol": "tcp",
            "FromPort": "30000",
            "ToPort": "32767",
            "SourceSecurityGroupId": {"Ref": "ExternalAccessSecurityGroupId"}
          }
          ]
          }
        ]
      }
    },
    "KubernetesIngress": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupId": {"Fn::GetAtt": ["KubernetesSecurityGroup", "GroupId"]},
        "IpProtocol": "tcp",
        "FromPort": "1",
        "ToPort": "65535",
        "SourceSecurityGroupId": {
          "Fn::GetAtt" : [ "KubernetesSecurityGroup", "GroupId" ]
        }
      }
    },
    "KubernetesIngressUDP": {
      "Type": "AWS::EC2::SecurityGroupIngress",
      "Properties": {
        "GroupId": {"Fn::GetAtt": ["KubernetesSecurityGroup", "GroupId"]},
        "IpProtocol": "udp",
        "FromPort": "1",
        "ToPort": "65535",
        "SourceSecurityGroupId": {
          "Fn::GetAtt" : [ "KubernetesSecurityGroup", "GroupId" ]
        }
      }
    },
    "KubernetesMasterInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "NetworkInterfaces" : [{
          "GroupSet"                 : [{"Fn::GetAtt": ["KubernetesSecurityGroup", "GroupId"]}],
          "AssociatePublicIpAddress" : "false",
          "DeviceIndex"              : "0",
          "DeleteOnTermination"      : "true",
          "SubnetId"                 : {"Fn::If": ["UseEC2Classic", {"Ref": "AWS::NoValue"}, {"Ref": "SubnetId"}]}
        }],
        "ImageId": {"Fn::FindInMap" : ["RegionMap", {"Ref": "AWS::Region" }, "AMI"]},
        "IamInstanceProfile" : {"Ref": "KubernetesMasterInstanceProfile"},
        "InstanceType": {"Ref": "MasterInstanceType"},
        "KeyName": {"Ref": "KeyPair"},
        "Tags" : [
          {"Key" : "Name", "Value" : {"Fn::Join" : [ "-", [ {"Ref" : "AWS::StackName"}, "k8s-master" ] ]}},
          {"Key" : "KubernetesRole", "Value" : "node"}
        ],
        "UserData": { "Fn::Base64": {"Fn::Join" : ["",
            %(master_yaml)s
            ]}
        }
      }
    },
    "KubernetesNodeLaunchConfig": {
      "Type": "AWS::AutoScaling::LaunchConfiguration",
      "Properties": {
        "ImageId": {"Fn::FindInMap" : ["RegionMap", {"Ref": "AWS::Region" }, "AMI"]},
        "InstanceType": {"Ref": "MinionInstanceType"},
        "KeyName": {"Ref": "KeyPair"},
        "AssociatePublicIpAddress" : "false",
        "IamInstanceProfile" : {"Ref": "KubernetesMinionInstanceProfile"},
        "SecurityGroups": [{"Fn::If": [
          "UseEC2Classic",
          {"Ref": "KubernetesSecurityGroup"},
          {"Fn::GetAtt": ["KubernetesSecurityGroup", "GroupId"]}]
        }],
        "UserData": { "Fn::Base64": {"Fn::Join" : ["",
            %(node_yaml)s
          ]}
        }
      }
    },
    "KubernetesAutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": {"Fn::If": ["UseEC2Classic", {"Fn::GetAZs": ""}, [{"Ref": "SubnetAZ"}]]},
        "VPCZoneIdentifier": {"Fn::If": ["UseEC2Classic", {"Ref": "AWS::NoValue"}, [{"Ref": "SubnetId"}]]},
        "LaunchConfigurationName": {"Ref": "KubernetesNodeLaunchConfig"},
        "MinSize": "2",
        "MaxSize": "12",
        "DesiredCapacity": {"Ref": "ClusterSize"},
        "Tags" : [
          {"Key" : "Name", "Value" : {"Fn::Join" : [ "-", [ {"Ref" : "AWS::StackName"}, "k8s-node" ] ]}, "PropagateAtLaunch" : true},
          {"Key" : "KubernetesRole", "Value" : "node", "PropagateAtLaunch" : true}
        ]
      }
    }
  },
  "Outputs": {
    "KubernetesMasterPrivateIp": {
    "Description": "Public Ip of the newly created Kubernetes Master instance",
      "Value": {"Fn::GetAtt": ["KubernetesMasterInstance" , "PrivateIp"]}
    }
  }
}
