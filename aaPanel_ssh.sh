#!/bin/bash

#+----------------ГЕНЕРАЦИЯ ЛОГА-----------------------+OK"
SCRIPT=$(basename "$0")
LOG="${SCRIPT%.sh}.log"
exec &> >(tee -a "$LOG")
echo "[$(date)] ==== Начало выполнения..."
#+----------------ГЕНЕРАЦИЯ ЛОГА-----------------------+OK"

Principal() {
	cd /tmp/ || exit 1
	clear
	dir="Текущая директория      : $(pwd)"
	hostname="Имя хоста          : $(hostname --fqdn)"
	ip="IP                       : $(wget -qO - icanhazip.com)"
	versaoso="Версия ОС          : $(lsb_release -d | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')"
	release="Релиз               : $(lsb_release -r | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')"
	codename="Кодовое имя        : $(lsb_release -c | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')"
	kernel="Ядро                 : $(uname -r)"
	arquitetura="Архитектура     : $(uname -m)"
	echo
	echo "+--------------------------------------------------+"
	echo "|           Утилита для aaPanel                    |"
	echo "+--------------------------------------------------+"
	echo "| Ограниченные ssh пользователи          v1.1      |"
	echo "+--------------------------------------------------+"
	echo "| Написано:                                        |"
	echo "| Тиаго Кастро - www.hostlp.cloud                  |"
	echo "| Переписал и оптимизировал                        |"
	echo "| Эрлан Капаров - erlan.me                         |"
	echo "| Репозиторий                                      |"
	echo "| https://github.com/NooBiToo/aaPanel_ssh          |"
	echo "+--------------------------------------------------+"
	echo
	echo "$dir"
	echo "+--------------------------------------------------+"
	echo "$hostname"
	echo "+--------------------------------------------------+"
	echo "$ip"
	echo "+--------------------------------------------------+"
	echo "$versaoso"
	echo "+--------------------------------------------------+"
	echo "$release"
	echo "+--------------------------------------------------+"
	echo "$codename"
	echo "+--------------------------------------------------+"
	echo "$kernel"
	echo "+--------------------------------------------------+"
	echo "$arquitetura"
	echo "+--------------------------------------------------+"
	echo
	echo
	echo "Нажмите <ENTER> для продолжения..."
	read
	echo "Опции:"
	echo
	echo "1. Создать пользователя"
	echo "2. Удалить пользователя"
	echo
	echo "3. Выйти"
	echo
	echo
	echo -n "Введите желаемую опцию => "
	read -r opcao
	echo
	case $opcao in
	1) cu ;;
	2) ru ;;
	3) exit ;;
	*)
		echo "Неизвестная опция."
		echo
		Principal
		;;
	esac
}

cu() {
	echo -n "Введите имя пользователя...: "
	read -r NEW_USER_NAME
	echo -n "Введите сайт/домен........: "
	read -r DOMAIN

	NEW_GROUP_NAME=${NEW_USER_NAME}
	HOME_DIR="/home"
	HOME_AAP="/www/wwwroot"
	USER_WEB="www"
	GROUP_WEB="www"
	#++++++++++++++++++++++++++++++++++++++++++++

	echo
	echo "Настройка SSH..."
	{
		echo ""
		echo "Match Group ${NEW_GROUP_NAME}"
		echo "   ChrootDirectory ${HOME_DIR}/${NEW_USER_NAME}"
		echo "   AuthorizedKeysFile ${HOME_DIR}/${NEW_USER_NAME}/.ssh/authorized_keys"
	} >>/etc/ssh/sshd_config
	echo "+-------------------------------------------------+OK"

	echo
	echo "Перезапуск SSH..."
	systemctl restart sshd
	echo "+-------------------------------------------------+OK"

	echo
	echo "Добавление пользователя..."
	useradd ${NEW_USER_NAME} 2>/dev/null
	usermod -aG www,${NEW_GROUP_NAME} -d ${HOME_DIR}/${NEW_USER_NAME} ${NEW_USER_NAME}
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN}
	echo "+-------------------------------------------------+OK"

	echo
	echo "Введите пароль...<--"
	passwd ${NEW_USER_NAME}
	echo "+-------------------------------------------------+OK"

	echo
	echo "Установка приложений для пользователя..."
	sudo apt-get install -y openssh-client wget vim nano zip unzip tar findutils iputils-ping bind9-utils rsync git htop
	\cp -v /bin/{htop,clear} ${HOME_DIR}/${NEW_USER_NAME}/bin/
	echo "+-------------------------------------------------+OK"


	echo
	echo "Добавление в fstab..."
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}/proc
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}/dev
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN}
	[ ! -e "/www/wwwroot/doka" ] && mkdir -p /www/wwwroot/doka
	{
		echo ""
		echo "#${NEW_USER_NAME}"
		echo "none ${HOME_DIR}/${NEW_USER_NAME}/proc proc defaults 0 0"
		echo "/dev ${HOME_DIR}/${NEW_USER_NAME}/dev none bind 0 0"
		echo "${HOME_AAP}/${DOMAIN} ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN} none bind 0 0"
	} >>/etc/fstab

	mount -a
	echo "+-------------------------------------------------+OK"


	echo
	echo "Настройка прав доступа к папке aaPanel..."
	chown ${USER_WEB}:${GROUP_WEB} ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN} -R 2>/dev/null
	chmod 775 ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN} -R 2>/dev/null
	NEW_WEB_ID=$(id -u ${USER_WEB})
	NEW_WEB_GROUP_ID=$(id -g ${GROUP_WEB})
	chroot ${HOME_DIR}/${NEW_USER_NAME} /bin/bash -c 'useradd -u '${NEW_WEB_ID}' '${USER_WEB}' -s /sbin/nologin' 2>/dev/null
	chroot ${HOME_DIR}/${NEW_USER_NAME} /bin/bash -c 'groupadd -g '${NEW_WEB_GROUP_ID}' '${GROUP_WEB}'' 2>/dev/null
	echo "+-------------------------------------------------+OK"

	echo
	echo "Заключение пользователя в группу..."
	NEW_USER_ID=$(id -u ${NEW_USER_NAME})
	NEW_USER_GROUP_ID=$(id -g ${NEW_GROUP_NAME})
	chroot ${HOME_DIR}/${NEW_USER_NAME} /bin/bash -c 'useradd -u '${NEW_USER_ID}' '${NEW_USER_NAME}'' 2>/dev/null
	chroot ${HOME_DIR}/${NEW_USER_NAME} /bin/bash -c 'groupadd -g '${NEW_USER_GROUP_ID}' '${NEW_GROUP_NAME}'' 2>/dev/null
	chroot ${HOME_DIR}/${NEW_USER_NAME} /bin/bash -c 'usermod -aG '${GROUP_WEB}' '${NEW_USER_NAME}'' 2>/dev/null
	ln -s ${HOME_AAP}/${DOMAIN} ${HOME_DIR}/${NEW_USER_NAME}/${DOMAIN}
	echo "+-------------------------------------------------+OK"

	echo
	echo "Настройка SSH ключа..."
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}/.ssh
	ssh-keygen -f ${HOME_DIR}/${NEW_USER_NAME}/.ssh/id_rsa -C "${NEW_USER_NAME}"
	cp -f ${HOME_DIR}/${NEW_USER_NAME}/.ssh/id_rsa.pub ${HOME_DIR}/${NEW_USER_NAME}/.ssh/authorized_keys
	chown -R ${NEW_USER_NAME}:${NEW_USER_NAME} ${HOME_DIR}/${NEW_USER_NAME}/.ssh
	chmod 700 ${HOME_DIR}/${NEW_USER_NAME}/.ssh
	chmod 600 ${HOME_DIR}/${NEW_USER_NAME}/.ssh/id_rsa
	chmod 644 ${HOME_DIR}/${NEW_USER_NAME}/.ssh/id_rsa.pub
	chmod 600 ${HOME_DIR}/${NEW_USER_NAME}/.ssh/authorized_keys
	echo
	cat ${HOME_DIR}/${NEW_USER_NAME}/.ssh/id_rsa
	echo
	echo "+-------------------------------------------------+OK"

	echo
	echo "Добавление DNS для пользователя..."
	mkdir -p ${HOME_DIR}/${NEW_USER_NAME}/etc
	{
		echo "nameserver 1.1.1.1"
		echo "nameserver 8.8.8.8"
		echo "nameserver 9.9.9.9"
	} >>${HOME_DIR}/${NEW_USER_NAME}/etc/resolv.conf
	echo "+-------------------------------------------------+OK"

	echo
	echo "Пользователь --> "${NEW_USER_NAME}""
	echo "Группа       --> "${NEW_GROUP_NAME}""
	echo
	echo "СОЗДАНЫ"
	echo "+-------------------------------------------------+OK"
	echo
	echo "Нажмите любую клавишу для продолжения..."
	read msg
	Principal
	}

	#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

	ru() {

	echo -n "Введите имя пользователя...: "
	read NEW_USER_NAME
	echo -n "Введите сайт/домен......: "
	read DOMAIN

	NEW_GROUP_NAME=${NEW_USER_NAME}
	HOME_DIR="/home"
	HOME_AAP="/www/wwwroot"
	#++++++++++++++++++++++++++++++++++++++++++++

	echo
	echo "Демонтаж пользовательских устройств..."
	umount ${HOME_DIR}/${NEW_USER_NAME}/proc
	umount ${HOME_DIR}/${NEW_USER_NAME}/dev
	umount ${HOME_DIR}/${NEW_USER_NAME}${HOME_AAP}/${DOMAIN}
	echo "+-------------------------------------------------+OK"

	echo
	echo "Удаление записей пользователей в fstab..."
	sed -i '/'${NEW_USER_NAME}'/d' /etc/fstab
	sed -i '/^$/d' /etc/fstab
	echo "+-------------------------------------------------+OK"

	echo
	echo "Удаление записей пользователей в ssh..."
	sed -i '/'${NEW_USER_NAME}'/d' /etc/ssh/sshd_config
	sed -i '/^$/d' /etc/ssh/sshd_config
	echo "+-------------------------------------------------+OK"

	echo
	echo "Перемещение домашней папки пользователя..."
	\mv -f ${HOME_DIR}/${NEW_USER_NAME} ${HOME_DIR}/${NEW_USER_NAME}.$(date "+%H:%M-%Y-%m-%d")
	echo "+-------------------------------------------------+OK"

	echo
	echo "Удаление пользователей и групп..."
	userdel ${NEW_USER_NAME}
	groupdel ${NEW_GROUP_NAME}
	echo "+-------------------------------------------------+OK"

	echo
	echo "Пользователь --> "${NEW_USER_NAME}""
	echo "Группа   --> "${NEW_GROUP_NAME}""
	echo
	echo "УДАЛЕНО"
	echo "+-------------------------------------------------+OK"

	echo
	echo "Нажмите любую клавишу, чтобы продолжить..."
	read msg
	Principal
	}

Principal

echo "[$(date)] ==== Конец..."
