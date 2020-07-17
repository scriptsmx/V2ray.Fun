#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
meu_ip () {
if [[ -e /etc/MEUIPADM ]]; then
echo "$(cat /etc/MEUIPADM)"
else
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
echo "$MEU_IP2" > /etc/MEUIPADM
fi
}
IP="$(meu_ip)"
#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ]; then
  OS=CentOS
  [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
  [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
  [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ]; then
  OS=CentOS
  CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
  [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
  echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
  kill -9 $$
fi

#Install Needed Packages

if [ ${OS} == Ubuntu ] || [ ${OS} == Debian ];then
	apt-get update -y
	apt-get install wget curl socat git unzip python python-dev openssl libssl-dev ca-certificates supervisor -y
	wget -O - "https://bootstrap.pypa.io/get-pip.py" | python
	pip install --upgrade pip
	pip install flask requests urllib3 Flask-BasicAuth Jinja2 requests six wheel
	pip install pyOpenSSL
fi

if [ ${OS} == CentOS ];then
	yum install epel-release -y
	yum install python-pip python-devel socat ca-certificates openssl unzip git curl crontabs wget -y
	pip install --upgrade pip
	pip install flask requests urllib3 Flask-BasicAuth supervisor Jinja2 requests six wheel
	pip install pyOpenSSL
fi

if [ ${Debian_version} == 9 ];then
	wget -N --no-check-certificate https://raw.githubusercontent.com/scriptsmx/V2ray.Fun/master/enable-debian9-rclocal.sh
	bash enable-debian9-rclocal.sh
	rm enable-debian9-rclocal.sh
fi

#Install acme.sh
curl https://get.acme.sh | sh

#Install V2ray
curl -L -s https://install.direct/go.sh | bash

#Install V2ray.Fun
cd /usr/local/
git clone https://github.com/scriptsmx/V2ray.Fun

#Generate Default Configurations
cd /usr/local/V2ray.Fun/ && python init.py
cp /usr/local/V2ray.Fun/v2ray.py /usr/local/bin/v2ray
chmod +x /usr/local/bin/v2ray
chmod +x /usr/local/V2ray.Fun/start.sh

#Start All services
service v2ray start

#Configure Supervisor
mkdir /etc/supervisor
mkdir /etc/supervisor/conf.d
echo_supervisord_conf > /etc/supervisor/supervisord.conf
cat>>/etc/supervisor/supervisord.conf<<EOF
[include]
files = /etc/supervisor/conf.d/*.ini
EOF
touch /etc/supervisor/conf.d/v2ray.fun.ini
cat>>/etc/supervisor/conf.d/v2ray.fun.ini<<EOF
[program:v2ray.fun]
command=/usr/local/V2ray.Fun/start.sh run
stdout_logfile=/var/log/v2ray.fun
autostart=true
autorestart=true
startsecs=5
priority=1
stopasgroup=true
killasgroup=true
EOF
#Reload the supervisor after modifying the configuration
supervisorctl reload
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "\e[1;100mESTOS DATOS SE USARAN PARA ENRAR AL PANEL\e[0m"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
read -p "ingrese el nombre de usuario [predeterminado admin]: " un
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
read -p "Ingrese la contrasena de inicio de sesion [predeterminado admin]: " pw
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
read -p "Introduzca el numero de puerto [predeterminado 5000]: " uport
if [[ -z "${uport}" ]];then
	uport="5000"
else
	if [[ "$uport" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
		if [[ $uport -ge "65535" || $uport -le 1 ]];then
			echo -e "\e[1;31mvalor de rango de puerto [1,65535], aplique el numero de puerto predeterminado 5000"
			unset uport
			uport="5000"
		else
			tport=`netstat -anlt | awk '{print $4}' | sed -e '1,2d' | awk -F : '{print $NF}' | sort -n | uniq | grep "$uport"`
			if [[ ! -z ${tport} ]];then
				echo -e "\e[1;31mEl numero de puerto ya existe! Aplique el numero de puerto predeterminado 5000$"
				unset uport
				uport="5000"
			fi
		fi
	else
		echo -e "\e[1;37mPor favor, ingrese un número. Aplique el número de puerto predeterminado 5000"
		uport="5000"
	fi
fi
if [[ -z "${un}" ]];then
	un="admin"
fi
if [[ -z "${pw}" ]];then
	pw="admin"
fi
sed -i "s/%%username%%/${un}/g" /usr/local/V2ray.Fun/panel.config
sed -i "s/%%passwd%%/${pw}/g" /usr/local/V2ray.Fun/panel.config
sed -i "s/%%port%%/${uport}/g" /usr/local/V2ray.Fun/panel.config
chmod 777 /etc/v2ray/config.json
supervisord -c /etc/supervisor/supervisord.conf
echo "supervisord -c /etc/supervisor/supervisord.conf">>/etc/rc.local
chmod +x /etc/rc.local
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "La instalacion ah sido exitosa!"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "\e[1;37mPuerto del panel:\e[1;33m ${uport}"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "\e[1;37mNombre de usuario:\e[1;33m ${un}"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "\e[1;37mContrasena:\e[1;33m ${pw}"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo -e "\e[1;37mAcceso al panel: http://$IP:${uport}"
echo -e "\e[1;37mO use la direccion de su dominio mas el puerto"
echo -e "\e[1;31m   ──── ❖ ── ✦ ── ❖ ────        \e[0m"
echo ''
echo "Gracias por utilizar v2ray "

#清理垃圾文件
rm -rf /root/config.json
rm -rf /root/install-debian.sh
