#! /bin/bash

# deploy(){
#	npc nos PUT /npc/dl/install-npc-shell.sh @install-npc-shell.sh
#	npc nos PUT /npc/dl/npc-shell.sh @npc-shell.sh
# }

install(){
	# https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
	curl 'http://npc.nos-eastchina1.126.net/dl/jq_1.5_linux_amd64.tar.gz' |  tar -zx -C '/usr/local/bin' \
		|| rm -f /usr/local/bin/jq
	# https://github.com/xiaopal/npc-shell
	curl 'http://npc.nos-eastchina1.126.net/dl/npc-shell.sh' > /usr/local/bin/npc-shell.sh \
		&& chmod a+x /usr/local/bin/npc-shell.sh \
		&& ln -sf /usr/local/bin/npc-shell.sh /usr/local/bin/npc \
		&& ln -sf /usr/local/bin/npc-shell.sh /usr/local/bin/npc-api \
		&& ln -sf /usr/local/bin/npc-shell.sh /usr/local/bin/npc-nos
	[ -x /usr/local/bin/jq ] && [ -x /usr/local/bin/npc-shell.sh ] && {
		echo "Installed" && npc
		return 0
	}
	return 1
}
install
