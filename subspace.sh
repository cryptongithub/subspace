#!/bin/bash

if curl > /dev/null 2>&1; then
	echo ''
else
  sudo apt install curl -y
fi

clear && curl -s https://raw.githubusercontent.com/cryptongithub/init/main/logo.sh | bash && sleep 3

sudo apt update && sudo apt upgrade -y

sudo apt install wget -y

cd $HOME

wget -O subspace-node https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-node-ubuntu-x86_64-snapshot-2022-mar-09
wget -O subspace-farmer https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-farmer-ubuntu-x86_64-snapshot-2022-mar-09
sudo mv subspace* /usr/local/bin/
sudo chmod +x /usr/local/bin/subspace*

sudo adduser --system --home=/var/lib/subspace subspace

echo -e '\e[40m\e[92m' && read -p "Enter wallet address: " SUBSPACE_WALLET && echo -e '\e[0m'
echo -e '\e[40m\e[92m' && read -p "Enter node name: " SUBSPACE_NODENAME && echo -e '\e[0m'

echo "export SUBSPACE_ADDRESS=$SUBSPACE_WALLET" >> $HOME/.bash_profile
echo "export NICKNAME=$SUBSPACE_NODENAME" >> $HOME/.bash_profile
source $HOME/.bash_profile

sudo tee <<EOF >/dev/null /etc/systemd/system/subspace-node.service
[Unit]
Description=Subspace Node
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which subspace-node) \\
--chain testnet \\
--wasm-execution compiled \\
--execution wasm \\
--bootnodes "/dns/farm-rpc.subspace.network/tcp/30333/p2p/12D3KooWPjMZuSYj35ehced2MTJFf95upwpHKgKUrFRfHwohzJXr" \\
--rpc-cors all \\
--rpc-methods unsafe \\
--ws-external \\
--validator \\
--telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \\
--telemetry-url "wss://telemetry.subspace.network/submit 1" \\
--name $SUBSPACE_NODENAME
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo tee <<EOF >/dev/null /etc/systemd/system/subspace-farmer.service
[Unit]
Description=Subspace Farmer
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which subspace-farmer) farm --reward-address=$SUBSPACE_WALLET
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload 
sudo systemctl enable subspace-farmer subspace-node  
sudo systemctl restart subspace-farmer subspace-node

echo -e '\n\e[40m\e[92mNode logs:\e[0m'
echo -e '\e[40m\e[91msudo journalctl -u subspace-node -f -o cat\n\e[0m'
echo -e '\n\e[40m\e[92mFarmer logs:\e[0m'
echo -e '\e[40m\e[91msudo journalctl -u subspace-farmer -f -o cat\n\e[0m'
echo -e '\n\e[40m\e[92mFarmed blocks:\e[0m'
echo -e '\e[40m\e[91msudo journalctl -u subspace-farmer -o cat | grep Successfully\n\e[0m'
