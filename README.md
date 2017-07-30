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
