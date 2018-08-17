#!/bin/bash

# todo проверку на совпадение имен проектов

# проверка прав при запуске 
ROOT_UID=0     # Только пользователь с $UID 0 имеет привилегии root
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Для работы сценария требуются права root."
  exit $E_NOTROOT
fi

project_name=$1 #название проекта, оно же имя папки
#TODO вынести
project_path="/home/fray/www/$project_name/html"

#создаем разделы проекта
mkdir -p $project_path

#получаем restore.php
cd $project_path

# проверяем второй параметр, скачиваем в цикле архив по url из второго параметра
if [ -n "$2" ]
then
  start_script="restore.php"
  backup_url=$2
  
  wget "$backup_url"

  counter=1
  while [ 1 == 1 ]
  do
      wget "$backup_url"."$counter" || break
      ((counter+=1))
  done

  # распаковываем и удаляем архивы
  find . -maxdepth 1 -name "*.tar.gz*" -type f  -exec tar vxzf {} \;
  find . -maxdepth 1 -name "*.tar.gz*" -type f -exec rm -f {} \;
else
  start_script="bitrixsetup.php"
fi

 wget "http://www.1c-bitrix.ru/download/scripts/$start_script"

#TODO вынести
#раздаем права
chmod -R 775 "$project_path"
chown -R fray:fray "$project_path"

#создаем запись в host
#TODO вынести
echo "127.0.0.1 $project_name.local" >> /etc/hosts

#создаем conf файл
#TODO вынести
echo "
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ServerName $project_name.local

	ErrorLog /home/fray/www/$project_name/error.log
	CustomLog /home/fray/www/$project_name/access.log combined

	DocumentRoot \"$project_path\"

	<Directory $project_path>
		AllowOverride All
		Require all granted
		allow from all
	</Directory>

</VirtualHost>
" >> /etc/apache2/sites-available/$project_name.conf

#применяем настройки
a2ensite $project_name.conf

#перезагружаем apache
service apache2 reload 

#TODO вынести
sudo -u fray google-chrome http://"$project_name".local/"$start_script"

exit 0 
