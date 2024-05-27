#!/bin/bash
# создаем неймспейсы
ip netns add h2
ip netns add h3
ip netns add h4

# создаем интерфейсы
ip link add name h2eth10 type veth peer name h2eth11
ip link add name h2eth20 type veth peer name h2eth21
ip link add name h3eth10 type veth peer name h3eth11
ip link add name h4eth20 type veth peer name h4eth21
# ip link add name vheth30 type veth peer name vheth31
ip link add name ethbr0 type veth peer name ethrou0
ip link add name ethbr1 type veth peer name ethrou1

# заводим интерфейсы в неймспейсы
ip link set dev h2eth10 netns h2
ip link set dev h2eth20 netns h2
ip link set dev h3eth10 netns h3
ip link set dev h4eth20 netns h4

# включаем интерфейсы
ip netns exec h2 ip link set dev lo up
ip netns exec h2 ip link set dev h2eth10 up
ip netns exec h2 ip link set dev lo up
ip netns exec h2 ip link set dev h2eth20 up
ip netns exec h3 ip link set dev lo up
ip netns exec h3 ip link set dev h3eth10 up
ip netns exec h4 ip link set dev lo up
ip netns exec h4 ip link set dev h4eth20 up
# ip link set dev vheth30 up

ip link set dev lo up
ip link set dev h2eth11 up
ip link set dev h2eth21 up
ip link set dev h3eth11 up
ip link set dev h4eth21 up
# ip link set dev vheth31 up
ip link set dev ethbr0 up
ip link set dev ethbr1 up

ip link set dev ethrou0 up
ip link set dev ethrou1 up

# создаем бридж и включаем его
ip link add name br0 type bridge
ip link set dev br0 up
ip link add name br1 type bridge
ip link set dev br1 up

# переводим бридж в режим VLAN-aware
ip link set dev br0 type bridge vlan_filtering 1
ip link set dev br1 type bridge vlan_filtering 1

# подключаем к нему интерфейсы
ip link set dev h2eth11 master br0
ip link set dev h2eth21 master br0
ip link set dev h3eth11 master br0
ip link set dev h4eth21 master br0
# ip link set dev vheth31 master br1
ip link set dev ethbr0 master br0
ip link set dev ethbr1 master br1

# устанавливаем режим access на veth11, veth21, veth31
bridge vlan add vid 10 dev h2eth11 pvid untagged
bridge vlan add vid 20 dev h2eth21 pvid untagged
bridge vlan add vid 10 dev h3eth11 pvid untagged
bridge vlan add vid 20 dev h4eth21 pvid untagged

# устанавливаем режим trunk на vethbr
bridge vlan add dev ethbr0 vid 10
bridge vlan add dev ethbr0 vid 20

# присваиваем ip адреса
ip netns exec h2 ip addr add 10.0.0.2/24 dev h2eth10
ip netns exec h2 ip addr add 20.0.0.2/24 dev h2eth20
ip netns exec h3 ip addr add 10.0.0.3/24 dev h3eth10
ip netns exec h4 ip addr add 20.0.0.4/24 dev h4eth20
# ip addr add 30.0.0.2/24 dev vheth30

# и дефолтные маршруты через маршрутизатор
ip netns exec h2 ip r add default via 10.0.0.1
ip netns exec h3 ip r add default via 10.0.0.1
ip netns exec h4 ip r add default via 20.0.0.1

# создаем vlan интерфейсы и включаем их
ip link add link ethrou0 name ethrou0.10 type vlan id 10
ip link add link ethrou0 name ethrou0.20 type vlan id 20
ip link set dev ethrou0.10 up
ip link set dev ethrou0.20 up

ip link add link ethrou1 name ethrou1.30 type veth
ip link set dev ethrou1.30 up

# присваиваем им адреса
ip addr add 10.0.0.1/24 dev ethrou0.10
ip addr add 20.0.0.1/24 dev ethrou0.20
ip addr add 30.0.0.1/24 dev ethrou1.30

# включаем форвардинг пакетов между интерфейсами
sysctl -w net.ipv4.ip_forward=1
