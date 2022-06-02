#!/bin/bash
mkdir ~/.screen && chmod 700 ~/.screen
export SCREENDIR=$HOME/.screen
installRclone() {
    cd /tmp
    echo "正在安装rclone..."
    wget https://downloads.rclone.org/v1.57.0/rclone-v1.57.0-linux-amd64.zip
    unzip rclone-v1.57.0-linux-amd64.zip
    mv rclone-v1.57.0-linux-amd64 rclone
    cd rclone
    chmod +x ./rclone
    mv ./rclone /usr/sbin/
    mkdir -p ~/.config/rclone/
    echo "[mcserver]
type = dropbox
token = ${DropBoxToken}" >>~/.config/rclone/rclone.conf
}
frp(){
    cat > $HOME/frpc.ini <<EOF
${FRP}
EOF
    until /bin/frpc -c $HOME/frpc.ini; do
        sleep 0.1
    done
}
# 检查服务端是否存在
checkIsInstall() {
    checkServerHas=$(rclone ls mcserver:/ --cache-db-purge)
    if [[ "${checkServerHas}" == *"mcserver/mc.tar.gz"* ]]; then
        echo "存在"
        # 备份到home
        rclone copy mcserver:/mcserver/mc.tar.gz $HOME
    else
        echo "不存在"
        wget -o mc.tar.gz  -U "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.79 Safari/537.36" $ServerUrl 
    fi
    flag=1
    while [ $flag -eq 1 ]; do
        sleep 10s
        if [ ! -f "${HOME}/mc.tar.gz" ]; then
            flag=0
            echo "备份文件下载成功正在解压。。。。"
            cd
            tar -xvf $HOME/mc.tar.gz -C $HOME/mc
        else
            echo "文件不存在"
        fi
    done
    java -Xmx500M -Xms64M -jar $HOME/mc/server.jar nogui
}

autoBak() {
    echo "备份已开启 首次运行将在180s后备份"
    sleep 180s
    echo "正在备份"
    tar -cvf $HOME/mc.tar.gz ~/mc
    rclone copy $HOME/mc.tar.gz mcserver:/mcserver/
    while [ 1==1 ]; do
        autoBak
    done
}

runTtyd(){
    echo "ttyd 启动"
    until /bin/ttyd -c mc:$Pwd -p $PORT bash; do
        sleep 0.1
    done
}
installRclone
checkIsInstall &
frp &
runTtyd &
autoBak &
