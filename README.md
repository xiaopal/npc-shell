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

## openapi v2 (New)
```
$ NPC_API_KEY=<key> NPC_API_SECRET=<secret> npc api2 GET '/ncs?Version=2017-11-16&Action=DescribeNamespaces'

```
or
```
$ NPC_API_KEY=<key> NPC_API_SECRET=<secret> npc api2 GET '/vpc/ListVPC/2017-11-30?PageSize=20&PageNumber=1'

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

## docker
```
$ docker run -it --rm \
    -e NPC_API_KEY=<API_KEY> \
    -e NPC_API_SECRET=<API_SECRET> \
    xiaopal/npc-shell

docker:/# npc api GET /api/v1/namespaces
```
