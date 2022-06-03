#!/bin/bash
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

            tmux new -s frp -d
            tmux send-key -t frp "cd ${HOME}" Enter
            tmux send-key -t frp "frp -c $HOME/frpc.ini" Enter

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
        wget -O $HOME/mc.tar.gz  -U "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.79 Safari/537.36" $ServerUrl 
    fi
    flag=1
    while [ $flag -eq 1 ]; do
        sleep 10s
        if [ -f "${HOME}/mc.tar.gz" ]; then
            flag=0
            echo "文件解压中"
            mkdir $HOME/mc
            tar -zxvf  $HOME/mc.tar.gz -C $HOME/mc
            echo "解压完毕"
            tmux new -s mc -d
            tmux send-key -t mc "cd ${HOME}/mc" Enter
            tmux send-key -t mc "java -Xmx400M -Xms64M -jar $HOME/mc/server.jar nogui" Enter
            echo '服务执行完毕'
        else
            echo "文件不存在"
        fi
    done

}

autoBak() {
    echo "备份已开启 首次运行将在180s后备份"
    sleep 3h
    echo "正在备份"
    cd $HOME/mc
    tar -zcvf  $HOME/mc.tar.gz ./
    rclone copy $HOME/mc.tar.gz mcserver:/mcserver/
    while [ 1==1 ]; do
        autoBak
    done
}


autoBak &
frp
installRclone 
checkIsInstall 
supervisord -c /etc/supervisord.conf
