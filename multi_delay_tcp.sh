#!/bin/bash

# 檢查是否提供了網域列表
if [ -z "$1" ]; then
  echo "用法: $0 <domain_list_file>"
  echo "例如: $0 domain_list.txt"
  exit 1
fi

# 網域列表文件
DOMAIN_LIST_FILE="$1"
STOP=50

# 確認文件是否存在
if [ ! -f "$DOMAIN_LIST_FILE" ]; then
  echo "文件 $DOMAIN_LIST_FILE 不存在，請檢查路徑。"
  exit 2
fi

echo "START time $(date)"

# 逐行處理每個網域
while IFS= read -r HOSTURL; do
  echo "處理域名: $HOSTURL"

  # 獲取該域名解析到的所有 IP 地址
  IP_LIST=$(host "${HOSTURL}" | grep 'has address' | awk '{print $NF}')

  if [ -z "$IP_LIST" ]; then
    echo "無法解析域名 ${HOSTURL} 的 IP，請確認域名是否正確。"
    continue
  fi

  echo "以下 IP 與 ${HOSTURL} 相關聯:"
  echo "$IP_LIST"

  # 對每個解析到的 IP 處理
  for IP in $IP_LIST; do
    echo "處理 IP: $IP"
    if iptables -L OUTPUT -n | grep -q "$IP"; then
      echo "IP $IP 已存在於 iptables 規則中"
    else
      # 添加規則
      sudo iptables -A OUTPUT -d "$IP" -j DROP
      echo "已添加 DROP 規則到 IP ${HOSTURL} ${IP}"
    fi
  done
done < "$DOMAIN_LIST_FILE"

echo "pause START time $(date)"
echo "所有域名的連線已被 DROP，暫停 ${STOP} 秒"
sleep ${STOP}
echo "pause END time $(date)"

# 移除所有 DROP 規則
while IFS= read -r HOSTURL; do
  echo "恢復域名: $HOSTURL"

  # 獲取該域名解析到的所有 IP 地址
  IP_LIST=$(host "${HOSTURL}" | grep 'has address' | awk '{print $NF}')

  if [ -z "$IP_LIST" ]; then
    echo "無法解析域名 ${HOSTURL} 的 IP，跳過恢復。"
    continue
  fi

  for IP in $IP_LIST; do
    if iptables -L OUTPUT -n | grep -q "$IP"; then
      echo "移除 DROP 規則，針對 IP: $IP"
      sudo iptables -D OUTPUT -d "$IP" -j DROP
    fi
  done
done < "$DOMAIN_LIST_FILE"

sudo iptables -L -n
echo "所有域名的連線已經回復正常"
echo "END time $(date)"
