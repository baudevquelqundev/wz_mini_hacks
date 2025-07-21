#!/bin/sh

# iptables script generated 2022-10-22
# http://www.mista.nu/iptables

IPT="iptables"

# Flush old rules, old custom tables
$IPT --flush
$IPT --delete-chain

# Set default policies for all three default chains
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT DROP

# Enable free use of loopback interfaces
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# All TCP sessions should begin with SYN
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -s 0.0.0.0/0 -j DROP

# Accept inbound TCP packets (SSH, RTSP, HTTPD Server, MQTT)
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport 22 -m state --state NEW -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p tcp --dport 8554 -m state --state NEW -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p tcp --dport 8081 -m state --state NEW -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 1883 -j ACCEPT

# Accept inbound UDP packets (123 NTP, 67 DHCP, 53 DNS, RTSP, MQTT)
$IPT -A INPUT -p udp -m udp --dport 123 -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p udp -m udp --dport 67 -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p udp -m udp --dport 53 -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p udp -m udp --dport 8554 -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p udp -m udp --dport 1883 -j ACCEPT

# Accept inbound ICMP messages (ping and traceroute)
$IPT -A INPUT -p ICMP --icmp-type 8 -s 0.0.0.0/0 -j ACCEPT
$IPT -A INPUT -p ICMP --icmp-type 11 -s 0.0.0.0/0 -j ACCEPT

# Accept outbound packets (53 dns)
$IPT -I OUTPUT 1 -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p udp -m udp --dport 1883 -j ACCEPT
$IPT -A OUTPUT -p tcp -m tcp --dport 1883 -j ACCEPT