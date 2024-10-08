Section 6
=========

~.~.~.~.~.~.~. Chapter 6.1  ~.~.~.~.~.~.~.
---------

```bash
export OS_TENANT_NAME=admin
export OS_USERNAME=erstebank.at
export OS_PASSWORD="george_2024!!_?"
```

```bash
curl -s -X POST http://192.168.56.101:5000/v2.0/tokens \
  -H "Content-Type: application/json" \
  -d '{"auth": {"tenantName": "'"$OS_TENANT_NAME"'", "passwordCredentials": {"username": "'"$OS_USERNAME"'", "password": "'"$OS_PASSWORD"'"}}}' \
  | python -m json.tool
```

```bash
export OS_TOKEN=<<__ token id __ >>
```

```bash
curl -s -H "X-Auth-Token:$OS_TOKEN" \
http://192.168.56.101:8774/v2/<< ______ >>/images | python -m json.tool
```

~.~.~.~.~.~.~. Chapter 6.2  ~.~.~.~.~.~.~.
---------

[OpenStack API Bindings](http://docs.openstack.org/developer/language-bindings.html)


[Python Nova Client](http://docs.openstack.org/developer/python-novaclient/)

```bash
export OS_USERNAME='admin'
export OS_PASSWORD='password'
export OS_AUTH_URL="http://192.168.56.101:5000/v2.0/"
export OS_TENANT_NAME='admin'
```

```bash
    vim credentials.py
```

```python
#!/usr/bin/env python
import os
def get_keystone_credentials():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['password'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['tenant_name'] = os.environ['OS_TENANT_NAME']
    return d
```

```bash
    python
```

```python
>>> import keystoneclient.v2_0.client as kclient
>>> from credentials import get_keystone_credentials
>>> creds = get_keystone_credentials()
>>> keystone = kclient.Client(**creds)
>>> print keystone.auth_token
>>> import glanceclient.v2.client as gclient
>>> glance_endpoint = keystone.service_catalog.url_for(service_type='image')
>>> glance = gclient.Client(glance_endpoint, token=keystone.auth_token)
>>> images = glance.images.list()
>>> images.next()
```

To exit the python interactive session
```bash
>>> exit(0)
```

```

~.~.~.~.~.~.~. Chapter 6.3  ~.~.~.~.~.~.~.
---------

```bash
printenv
```

```bash
export OS_USERNAME='admin'
export OS_PASSWORD='password'
export OS_AUTH_URL="http://192.168.56.101:5000/v2.0/"
export OS_TENANT_NAME='admin'
```

```bash
test -f ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

```bash
    glance image-list
```

```bash
    vim credentials_nova.py
```

```python
#!/usr/bin/env python
import os
def get_nova_credentials():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['api_key'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['project_id'] = os.environ['OS_TENANT_NAME']
    d['version'] = 2
    return d
```
    
    
```bash
    vim boot_vm.py
```
    
```python
#!/usr/bin/env python

import os
import time
import novaclient.client as nclient
from credentials_nova import get_nova_credentials
creds = get_nova_credentials()

# Instantiating a nova client object which will be used to make calls
nova = nclient.Client(**creds)

# If there are no keypairs creating the keypairs for the instance to boot with
if not nova.keypairs.findall(name="mykey"):
    with open(os.path.expanduser('~/.ssh/id_rsa.pub')) as mypubkey:
        nova.keypairs.create(name="testkey", public_key=mypubkey.read())

# Now preparing an image
image = nova.images.find(name="cirros-0.3.4-x86_64-uec")        

# Getting the flavor
flavor = nova.flavors.find(name="m1.tiny")

# Creating our vm now
vm = nova.servers.create(name="bugs", image=image, flavor=flavor, key_name="testkey")

# Get the status of the instance
status = vm.status
print "The instance Status is : %s" % status

# To query the instance status every few seconds
while status == 'BUILD':
    time.sleep(5)
    vm = nova.servers.get(vm.id)
    status = vm.status

# Acknowledgement once done
print "VM is now: %s" %status 

# Getting the IP of the vm
print vm.networks

# Updating theSecurity Group 
sgroup = nova.security_groups.find(name="default")
nova.security_group_rules.create(sgroup.id, ip_protocol="tcp", from_port=22, to_port=22)
nova.security_group_rules.create(sgroup.id, ip_protocol="icmp", from_port=-1, to_port=-1)

# Printing the boot log of this instance now
print vm.get_console_output()
```

```bash
python boot_vm.py
```
