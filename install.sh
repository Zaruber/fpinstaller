#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Установщик FunPayCardinal для Termux"
echo "Адаптированная версия от @exfador"
echo -e "${RESET}"

# Проверка обновлений Termux
echo -e "${GREEN}Обновление пакетов Termux...${RESET}"
pkg update -y && pkg upgrade -y

# Установка необходимых пакетов
echo -e "${GREEN}Установка зависимостей...${RESET}"
pkg install -y python python-dev libxml2 libxslt openssl screen curl wget git unzip clang make

# Настройка виртуального окружения
echo -e "${GREEN}Создание виртуального окружения...${RESET}"
python -m venv $HOME/pyvenv
source $HOME/pyvenv/bin/activate

# Обновление pip
echo -e "${GREEN}Обновление pip...${RESET}"
pip install --upgrade pip

# Выбор версии FPC
echo -e "${GREEN}Получаю список версий FunPayCardinal...${RESET}"
gh_repo="sidor0912/FunPayCardinal"
releases=$(curl -sS https://api.github.com/repos/$gh_repo/releases | grep "tag_name" | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')

if [ -n "$releases" ]; then
  echo -e "${YELLOW}Доступные версии:${RESET}"
  versions=($releases)
  for i in "${!versions[@]}"; do
    echo "$i) ${versions[$i]}"
  done
  echo "latest) Последняя версия"
  
  read -p "${YELLOW}Выберите версию (номер или 'latest'): ${RESET}" version_choice
  
  if [[ "$version_choice" == "latest" || -z "$version_choice" ]]; then
    LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')
  elif [[ $version_choice =~ ^[0-9]+$ ]] && [ $version_choice -lt ${#versions[@]} ]; then
    LOCATION="https://github.com/$gh_repo/archive/refs/tags/${versions[$version_choice]}.zip"
  else
    echo -e "${RED}Неверный выбор, использую последнюю версию${RESET}"
    LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')
  fi
else
  echo -e "${RED}Не удалось получить версии, использую develop ветку${RESET}"
  LOCATION="https://github.com/$gh_repo/archive/refs/heads/develop.zip"
fi

# Скачивание и распаковка
echo -e "${GREEN}Скачивание FunPayCardinal...${RESET}"
curl -L $LOCATION -o $HOME/fpc.zip
unzip -qo $HOME/fpc.zip -d $HOME/fpc-tmp
mv $HOME/fpc-tmp/*/* $HOME/FunPayCardinal
rm -rf $HOME/fpc-tmp $HOME/fpc.zip

# Установка зависимостей Python
echo -e "${GREEN}Установка Python-зависимостей...${RESET}"
REQ_FILE="$HOME/FunPayCardinal/requirements.txt"

if [ -f "$REQ_FILE" ]; then
  pip install -r $REQ_FILE
else
  echo -e "${YELLOW}requirements.txt не найден, устанавливаю базовые зависимости...${RESET}"
  pip install requests pytelegrambotapi pyyaml aiohttp requests_toolbelt lxml bcrypt beautifulsoup4
fi

# Первоначальная настройка
echo -e "${GREEN}Первоначальная настройка...${RESET}"
LANG=en_US.UTF-8 python $HOME/FunPayCardinal/main.py

# Запуск в screen
echo -e "${GREEN}Запуск в screen сессии...${RESET}"
screen -dmS fpc bash -c "LANG=en_US.UTF-8 python $HOME/FunPayCardinal/main.py"

echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}Установка завершена!${RESET}"
echo -e "${CYAN}Для подключения к сессии: screen -r fpc${RESET}"
echo -e "${CYAN}Для выхода из screen: Ctrl+A D${RESET}"
echo -e "${CYAN}Не забудьте настроить конфигурацию бота!${RESET}"
echo -e "${CYAN}################################################################################${RESET}"