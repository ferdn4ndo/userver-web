#!/usr/bin/env sh

now=$(date +'%m/%d/%Y %H:%M:%S')
docker_version=$(docker -v)
disk_usage=$(df -h /)
docker_stats=$(docker stats --no-stream --all)

cat > "$STATS_FILE" <<- EOM
HEARTBEAT LOG AT $now

================================================
Docker version
================================================
$docker_version

================================================
Containers stats
================================================
$docker_stats

================================================
Disk Usage
================================================
$disk_usage

END OF LOG
EOM

echo "Heartbeat created for timestamp $now!"
