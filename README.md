# npc-shell
npc/nos OpenAPI command line utility

# How to use

## install
```
# curl 'https://npc.nos-eastchina1.126.net/dl/install-npc-shell.sh' | /bin/bash
```

## openapi
```
$ NPC_API_KEY=<key> NPC_API_SECRET=<secret> npc api GET /api/v1/namespaces
```

## nos openapi
```
$ NPC_API_KEY=<key> NPC_API_SECRET=<secret> npc nos PUT /<bucket>/<object> <file_data|@file>
```

## save api key & secret
```
$ cat ~/.npc/api.key
{"api_key":"<key>", "api_secret":"<secret>"}

$ npc api 'json.namespaces[]' GET /api/v1/namespaces
```

## setup
```
$ npc setup - --init-ssh-key <<EOF
{
  "npc_instance_image": "Debian 8.6",
  "npc_instance_type": {
    "cpu": 2,
    "memory": "4G"
  },
  "npc_ssh_key": {
    "name": "ansible"
  },
  "npc_instances": [
    {
      "name": "debian-{01,02}"
    },
    {
      "name": "ubuntu-{a..c}",
      "instance_image": "Ubuntu 16.04",
      "instance_type": {
        "cpu": 1,
        "memory": "2G"
      },
      "groups": [
        "ubuntu"
      ]
    }
  ]
}
EOF
```