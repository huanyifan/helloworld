ip rule add fwmark 1 table 100 
ip route add local 0.0.0.0/0 dev lo table 100

iptables -t mangle -F
iptables -t filter -F

# 代理局域网设备
iptables -t mangle -N V2RAY
iptables -t mangle -A V2RAY -d 127.0.0.1/32 -j RETURN
iptables -t mangle -A V2RAY -d 224.0.0.0/4 -j RETURN 
iptables -t mangle -A V2RAY -d 255.255.255.255/32 -j RETURN 
iptables -t mangle -A V2RAY -d 192.168.0.0/16 -p tcp -j RETURN # 直连局域网，避免 V2Ray 无法启动时无法连网关的 SSH，如果你配置的是其他网段（如 10.x.x.x 等），则修改成自己的
iptables -t mangle -A V2RAY -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 
iptables -t mangle -A V2RAY -p udp -j TPROXY --on-port 55555 --tproxy-mark 1 # 给 UDP 打标记 1，转发至 55555 端口
iptables -t mangle -A V2RAY -p tcp -j TPROXY --on-port 55555 --tproxy-mark 1 # 给 TCP 打标记 1，转发至 55555 端口
iptables -t mangle -A PREROUTING -j V2RAY # 应用规则

# 代理网关本机
iptables -t mangle -N V2RAY_MARK 
iptables -t mangle -A V2RAY_MARK -d 224.0.0.0/4 -j RETURN 
iptables -t mangle -A V2RAY_MARK -d 255.255.255.255/32 -j RETURN 
iptables -t mangle -A V2RAY_MARK -d 192.168.0.0/16 -p tcp -j RETURN # 直连局域网
iptables -t mangle -A V2RAY_MARK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 DNS）
iptables -t mangle -A V2RAY_MARK -j RETURN -m mark --mark 0xff    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
iptables -t mangle -A V2RAY_MARK -p udp -j MARK --set-mark 1   # 给 UDP 打标记,重路由
iptables -t mangle -A V2RAY_MARK -p tcp -j MARK --set-mark 1   # 给 TCP 打标记，重路由
iptables -t mangle -A OUTPUT -j V2RAY_MARK # 应用规则

iptables -t mangle -I V2RAY -d 34.92.247.6/32 -j RETURN
iptables -t mangle -I V2RAY_MARK -d 34.92.247.6/32 -j RETURN
iptables -t mangle -I V2RAY -d 35.185.135.116/32 -j RETURN
iptables -t mangle -I V2RAY_MARK -d 35.185.135.116/32 -j RETURN
iptables -t mangle -I V2RAY -d 34.97.188.125/32 -j RETURN
iptables -t mangle -I V2RAY_MARK -d 34.97.188.125/32 -j RETURN
