Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}Info${Font_color_suffix}]"
Error="[${Red_font_prefix}Error${Font_color_suffix}]"
Tip="[${Green_font_prefix}Tip${Font_color_suffix}]"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} The current non-ROOT account (or no ROOT permission) cannot continue the operation. Please change the ROOT account or use ${Green_background_prefix}sudo su${Font_color_suffix} Command to obtain temporary ROOT permissions (you may be prompted to enter the password of the current account after execution)." && exit 1
}

install_env_and_full_node() {
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install git
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo apt-get install npm -y
    sudo npm install n -g
    sudo n stable
    sudo npm i -g yarn

    git clone https://github.com/CATProtocol/cat-token-box
    cd cat-token-box
    sudo yarn install
    sudo yarn build

    cd ./packages/tracker/
    sudo chmod 777 docker/data
    sudo chmod 777 docker/pgdata
    sudo docker-compose up -d

    cd ../../
    sudo docker build -t tracker:latest .
    curl -O http://88.99.70.27:41187/dump_file_37916.sql
    sudo apt-get install postgresql-client -y
    psql -h 127.0.0.1 -U postgres -d postgres -f dump_file_37916.sql
    sudo docker run -d \
        --name tracker \
        --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 \
        tracker:latest
    echo '{
      "network": "fractal-mainnet",
      "tracker": "http://127.0.0.1:3000",
      "dataDir": ".",
      "maxFeeRate": 30,
      "rpc": {
          "url": "http://127.0.0.1:8332",
          "username": "bitcoin",
          "password": "opcatAwesome"
      }
    }' > ~/cat-token-box/packages/cli/config.json

    echo '#!/bin/bash

    command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5"

    while true; do
        $command

        if [ $? -ne 0 ]; then
            echo "The command execution failed and the loop exited."
            exit 1
        fi

        sleep 1
    done' > ~/cat-token-box/packages/cli/mint_script.sh
    chmod +x ~/cat-token-box/packages/cli/mint_script.sh
}

create_wallet() {
  echo -e "\n"
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet create
  echo -e "\n"
  sudo yarn cli wallet address
  echo -e "Please save the wallet address and mnemonic phrase created above"
}

start_mint_cat() {
  read -p "Please enter max gas price for mint: " newMaxFeeRate
  sed -i "s/\"maxFeeRate\": [0-9]*/\"maxFeeRate\": $newMaxFeeRate/" ~/cat-token-box/packages/cli/config.json
  cd ~/cat-token-box/packages/cli
  bash ~/cat-token-box/packages/cli/mint_script.sh
}

check_node_log() {
  docker logs -f --tail 100 tracker
}

check_wallet_balance() {
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet balances
}

echo && echo -e " ${Red_font_prefix}dusk_network One-click installation script(Translated by Ka1n)${Font_color_suffix} by \033[1;35moooooyoung\033[0m
This script is completely free and open source, created by Twitter user ${Green_font_prefix}@ouyoung11 developer${Font_color_suffix}, 
Welcome to pay attention. If there are any charges, please do not be deceived.
 ———————————————————————
 ${Green_font_prefix} 1.Install Dependencies and Node ${Font_color_suffix}
 ${Green_font_prefix} 2.Create wallet ${Font_color_suffix}
 ${Green_font_prefix} 3 Start mint cat ${Font_color_suffix}
 ${Green_font_prefix} 4.Check node log ${Font_color_suffix}
 ${Green_font_prefix} 5.Check wallet balance ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " Please follow the steps above and enter the number:" num
case "$num" in
1)
    install_env_and_full_node
    ;;
2)
    create_wallet
    ;;
3)
    start_mint_cat
    ;;
4)
    check_node_log
    ;;
5)
    check_wallet_balance
    ;;
*)
    echo
    echo -e " ${Error} Please enter the correct number."
    ;;
esac