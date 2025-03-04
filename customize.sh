# 设置 $MODPATH/bin 目录下的所有文件为可执行权限
if [ -d "$MODPATH/bin" ]; then
    chmod -R +x "$MODPATH/bin"
fi