#!/usr/bin/env python
import json
import os
import re

VARS = {
  'dns_replicas': 1,
  'dns_domain': 'cluster.local',
  'dns_server': '10.100.1.1',
  'kube_version': '1.0.1',
  'kube_binaries': 'http://nadavsr-kubernetes-build.s3-website-us-west-2.amazonaws.com'
}

def process_jinja_file(filename):
    with open(filename) as fin:
        r = fin.read()
    for var in VARS:
        r = r.replace("{{ pillar['%s'] }}" % var, str(VARS[var]))
    dest = os.path.join('../output', filename)
    if dest.endswith('.in'):
        dest = dest[:-3]
    dest_dir = os.path.dirname(dest)
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    with open(dest, 'w') as fout:
        fout.write(r)

node = open('node.yaml').readlines()
master = open('master.yaml').readlines()
cft_tpl = open('cloudformation-template.json.tpl').read()

node_json = json.dumps(node, indent=2).replace(
  '<master-private-ip>', '", {"Fn::GetAtt" :["KubernetesMasterInstance" , "PrivateIp"]}, "')
master_json = json.dumps(master, indent=2)

VARS['node_yaml'] = node_json % VARS
VARS['master_yaml'] = master_json % VARS

for f in ['dns/skydns-rc.yaml.in', 
          'dns/skydns-svc.yaml.in',
          'kube-ui/kube-ui-rc.yaml',
          'kube-ui/kube-ui-svc.yaml',
         ]:
    process_jinja_file(f)

with open('../output/cloudformation-template.json', 'w') as output:
    output.write(cft_tpl % VARS)

