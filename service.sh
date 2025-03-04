#!/system/bin/sh
sleep 20s

if ! pm list packages | grep -q "com.termux.dockershell"; then
    pm install "/data/adb/modules/Docker/dockershell.apk" || echo "安装失败，请检查权限或文件完整性！"
fi

export PATH=/data/adb/modules/Docker/bin:$PATH

if [ -d "/data/adb/modules/Docker/bin" ]; then
    chmod -R +x /data/adb/modules/Docker/bin
fi

/data/adb/modules/Docker/bin/dockerd.sh