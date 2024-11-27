* TCP/HTTP 雍塞問題程式面向的解決與測試

* curl 中有分成 --connect-timeout 和 --max-time , 其中 --connect-timeout 是對於 dns , tcp , http 連不上的壅塞 timeout 這種 timeout 不會送出資料, max-time 是整體最大連線 timeout 通常是已經送出資料

* 可以使用 ifconfig.me 這個網站測試
```
curl --connect-timeout 4 --max-time 8 https://ifconfig.me
```

* 成功是這樣
```
$ curl --connect-timeout 4 --max-time 8 https://ifconfig.me
54.64.167.221
```

* TCP timeout 是這樣
```
$  curl --connect-timeout 4 --max-time 8 https://ifconfig.me
curl: (28) Failed to connect to ifconfig.me port 443 after 2201 ms: Connection timed out
```

* 模擬壅塞內部網路連到 ifconfig.me 的連線被中斷 50 秒
```
sudo ./delay_tcp.sh ifconfig.me
```

* 模擬壅塞把 domain_list.txt 的所有網址對應的 ip 都塞滿 50 秒
```
$ cat domain_list.txt 
ifconfig.me
example.com
```

* 執行 , 可以檢查 iptables -L -n 看看被封鎖的狀況
```
$ ./multi_delay_tcp.sh domain_list.txt
```
