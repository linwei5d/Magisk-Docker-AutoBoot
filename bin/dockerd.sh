#!/system/bin/sh

mount -o rw,remount /
mount -o rw,remount /system/etc
# 创建 Docker 相关的目录
root_dirs=("/var" "/run" "/tmp" "/opt" "/usr" "/system/etc/docker")
for dir in "${root_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir "$dir"
    fi
done

# 创建 /data 目录相关的目录
data_dirs=("/data/var:/var" "/data/run:/run" "/data/tmp:/tmp" "/data/opt:/opt" "/data/etc/docker:/system/etc/docker")
for dir in "${data_dirs[@]}"; do
    # 分割目录路径和挂载点
    paths=$(echo "$dir" | tr ':' ' ')
    data_dir=$(echo "$paths" | cut -d ' ' -f 1)
    mount_dir=$(echo "$paths" | cut -d ' ' -f 2)
    # 如果 /data/var 目录存在，清理目录中的 ./run 目录
    if [ "$data_dir" = "/data/var" ] && [ -d "$data_dir" ]; then
        rm -rf /data/var/run
    fi
    # 尝试创建并挂载目录
        mkdir -p "$data_dir"
        mount --bind "$data_dir" "$mount_dir"
        echo "mount $data_dir to $mount_dir"
done


# 创建 /dev 目录相关的目录，并挂载 cgroup
cgroup_dirs=("cpu" "cpuacct" "devices" "freezer" "hugetlb" "net_cls" "net_prio" "perf_event" "pids" "rdma")
for dir in "${cgroup_dirs[@]}"; do
    if [ ! -d "/dev/$dir" ]; then
        mkdir -p "/dev/$dir"
        case "$dir" in
            "cpu"|"cpuacct")
            ;;
        *)
            echo "mount -t cgroup -o $dir none /dev/$dir"
            mount -t cgroup -o $dir none /dev/$dir
            ;;
        esac
    fi
done


# 为 Docker 添加路由表
ip_rule1=$(ip rule | grep "from all lookup main" | wc -l)
if [ "$ip_rule1" -ne 1 ]; then
    ip rule add pref 1 from all lookup main
fi
ip_rule2=$(ip rule | grep "from all lookup default" | wc -l)
if [ "$ip_rule2" -ne 1 ]; then
    ip rule add pref 2 from all lookup default
fi

# 关闭默认防火墙，允许外部访问 Docker 容器端口
setenforce 0
# 启动 Docker
export DOCKER_RAMDISK=true
dockerd --add-runtime crun=crun -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock > /dev/null 2>&1 &