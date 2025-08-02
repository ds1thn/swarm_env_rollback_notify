#!/bin/bash

HOME_SCRIPT=$(cd "$(dirname "$0")" && pwd)

source "$HOME_SCRIPT/env.sh"

# PID процесса
ARG=$1

if [[ -z "$ARG" ]]; then 
    echp "PID == Номер процесса не передан"
    exit 0
fi

# Файл PID
pid_file=$2
if [[ -z "$pid_file" ]]; then
    echo "PID == Файл PID не задан"
    exit 0
fi

# Время жизни процесса (по умолчанию 4 часа = 14400 секунд)
pid_time=${3:-14400}

if [[ -e "$pid_file" ]]; then 
    echo "PID == Скрипт уже запущен, номер процесса: $(cat "$pid_file")"

    if [[ ! -e "/proc/$(cat "$pid_file")" || ! -e "/proc/$(cat "$pid_file")/exe" ]]; then
        echo "PID == Процесс отсутствует, создаем новый PID-файл с номером $ARG"
        echo "$ARG" > "$pid_file"
    else
        echo "PID == Приложение уже работает (PID: $(cat "$pid_file")), прерываем повторный запуск"
        kill -9 "$ARG"
        exit
    fi
else
    echo "PID == Процесс уникален, создаем PID-файл с номером $ARG"
    echo "$ARG" > "$pid_file"
fi

exit 0
