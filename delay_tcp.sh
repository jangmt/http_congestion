#!/bin/bash

# 檢查是否提供了 HOSTURL
if [ -z "$1" ]; then
  echo "用法: $0 <HOSTURL>"
  echo "例如: $0 api.examle.com"
  exit 1
fi

# 接收命令列參數作為 HOSTURL
HOSTURL="$1"
STOP=52
echo "START time $(date)"

# 獲取所有解析到的 IP 地址
IP_LIST=$(host "${HOSTURL}" | grep 'has address' | awk '{print $NF}')

if [ -z "$IP_LIST" ]; then
  echo "無法解析域名 ${HOSTURL} 的 IP，請確認域名是否正確。"
  exit 2
fi

echo "以下 IP 與 ${HOSTURL} 相關聯:"
echo "$IP_LIST"

# 處理每個 IP
for IP in $IP_LIST; do
  echo "處理 IP: $IP"
  # 檢查 iptables 是否已存在規則針對該 IP
  if iptables -L OUTPUT -n | grep -q "$IP"; then
    echo "IP $IP 已存在於 iptables 規則中"
  else
    # 添加規則
    sudo iptables -A OUTPUT -d "$IP" -j DROP
    echo "已添加 DROP 規則到 IP ${HOSTURL} ${IP}"
  fi
done

echo "pause START time $(date)"
echo "所有域名的連線已被 DROP，暫停 ${STOP} 秒"
sleep ${STOP}
echo "pause END time $(date)"


# 移除所有相關的 DROP 規則
for IP in $IP_LIST; do
  if iptables -L OUTPUT -n | grep -q "$IP"; then
    echo "移除 DROP 規則，針對 IP: $IP"
    sudo iptables -D OUTPUT -d "$IP" -j DROP
  fi
done

iptables -L -n
echo "本機對外連線到 ${HOSTURL} 已經回復正常"
echo "END time $(date)"


