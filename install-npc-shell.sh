#! /bin/bash

# ./install-npc-shell.sh deploy
deploy(){
	[ -x ./npc-shell.sh ] && [ -f ./install-npc-shell.sh ] \
		&& tar -zcf npc-shell.tar.gz npc-shell.sh && ./npc-shell.sh nos PUT /npc/dl/npc-shell.tar.gz @npc-shell.tar.gz \
		&& rm -f npc-shell.tar.gz && ./npc-shell.sh nos PUT /npc/dl/install-npc-shell.sh @install-npc-shell.sh \
		&& echo 'Deployed' && return 0
	return 1
}

install(){
	# https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
	curl 'http://npc.nos-eastchina1.126.net/dl/jq_1.5_linux_amd64.tar.gz' |  tar -zx -C '/usr/bin' || {
		rm -f /usr/bin/jq
		return 1
	}
	# https://github.com/xiaopal/npc-shell
	mkdir -p /usr/npc-shell \
		&& curl 'http://npc.nos-eastchina1.126.net/dl/npc-shell.tar.gz' | tar -zx -C '/usr/npc-shell' \
		&& ln -sf /usr/npc-shell/npc-shell.sh /usr/bin/npc && {
		echo "Installed" && npc
		return 0
	}
	return 1
}
[ "$1" == "deploy" ] && {
	deploy || exit 1
}
install