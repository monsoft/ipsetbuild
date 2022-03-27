#!/bin/ash

# ipsetbuild by Irek Pelech (c) 2022 Ascot
#
# Add this configuration to OpenWrt /etc/config/firewall and run script manually:
#
# config ipset                  
#         option name 'tornodes' 
#         option match 'src_net'
#         option storage 'hash'
#         option enabled '1'              


# config rule                  
#         option src 'wan'      
#         option ipset 'tornodes'
#         option dest '*'
#         option target 'DROP'
#         option name 'DENY-from-TOR-Network'
#         list proto 'all'

# Install package libustream-openssl
# opkg install libustream-openssl
#
# Setup cron job to refresh list daily
# 0 1 * * * /root/listbuilder.sh
#
# and restart cron service if this is 1st entry in cron file https://openwrt.org/docs/guide-user/base-system/cron

TORLIST="https://check.torproject.org/torbulkexitlist"
SETNAME="tornodes"

IPSET_FILE="/etc/tornodes.ipset"
COUNTER=0

# Empty file or create one
cp /dev/null ${IPSET_FILE}

# Build insert file for ipset
for IP in $(wget -q ${TORLIST} -O- --no-check-certificate); do
    echo "add ${SETNAME} ${IP}" >> ${IPSET_FILE}
    let "COUNTER=COUNTER+1"
done

echo "Insert file ${IPSET_FILE} for ipset has been build. ${COUNTER} IPs has been added to it."

# Check if SETNAME exist
ipset list ${SETNAME} &> /dev/null
if [ $? -eq 1 ]; then
    echo "Configure Firewall first !!!"
else
    ipset flush ${SETNAME}
    ipset restore -! < ${IPSET_FILE}
fi

