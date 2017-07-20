#! /bin/bash

# NPC_INSTALL_ACTION=deploy ./install-npc-shell.sh
deploy(){
	tar -zcf npc-shell.tar.gz npc-shell.sh npc-setup.sh && npc nos PUT /npc/dl/npc-shell.tar.gz @npc-shell.tar.gz \
		&& rm -f npc-shell.tar.gz && npc nos PUT /npc/dl/install-npc-shell.sh @install-npc-shell.sh \
		&& echo 'Deployed' && return 0
	return 1
}

install(){
	# https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
	curl 'http://npc.nos-eastchina1.126.net/dl/jq_1.5_linux_amd64.tar.gz' |  tar -zx -C '/usr/local/bin' \
		|| rm -f /usr/local/bin/jq
	# https://github.com/xiaopal/npc-shell
	curl 'http://npc.nos-eastchina1.126.net/dl/npc-shell.tar.gz' | tar -zx -C '/usr/local/bin' \
		&& ln -sf /usr/local/bin/npc-shell.sh /usr/local/bin/npc

	[ -x /usr/local/bin/jq ] && [ -x /usr/local/bin/npc-shell.sh ] && {
		echo "Installed" && npc
		return 0
	}
	return 1
}

"${NPC_INSTALL_ACTION:-install}"
