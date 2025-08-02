#!/bin/bash

HOME_SCRIPT=$(cd $(dirname $0) && pwd);

# инклюдим логирование
source $HOME_SCRIPT/env.sh

#########################################################
#	Проверка существования запуска этого скрипта	    #
#########################################################
PID_NUM=$$
pid_time=7200
pid_file=/run/app.pid

bash $HOME_SCRIPT/pid.sh $PID_NUM $pid_file $pid_time

function send_to_slack {
    url="https://hooks.slack.com/services/${SLACK_TOKEN}"
    username=bot
    curl \
        -s \
        -m 5 \
        --data-urlencode \
        "payload={\"channel\": \"${to//\"/\\\"}\", \"username\": \"${username//\"/\\\"}\",\"attachments\":[{\"color\": \"${color}\", \"text\": \"${message//\"/\\\"}\",}]}" \
        $url
}

for i in $(docker stack ls --format "{{.Name}}"); do 
    # echo stack name == $i
    for service_name in $(docker stack services $i -q); do
        # определяемм имя сервиса
        SVC_NAME=$(docker service inspect $service_name --format "{{.Spec.Name}}")

        # ищем роллбечные сервисы
        check=$(docker service inspect --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{else}}completed{{end}}' $service_name | grep rollback | wc -l )
        if [ "$check" == 1 ]; then
            SVC_STATUS=$(docker service inspect $service_name --format '{{.Spec.Name}} {{.UpdateStatus.State}}' )
            
            echo "------> $service_name - ERROR - ${SVC_STATUS}"
            
            to=${SLACK_CHANNEL}
            message="❌ *Rollback detected!*
                *Stack:* $i
                *Task:* $SVC_NAME ($service_name)
                *Status:* ${SVC_STATUS}
                "
            send_to_slack        
        fi

        EXCLUDE_APP_1="jitsu_syncctl wg_app airflow_redis"

        if ! grep -q "$SVC_NAME" <<< "$EXCLUDE_APP_1"; then
            SVC_ENV_STATUS=$(
                docker service inspect "$service_name" \
                | jq '.[0].Spec.TaskTemplate.ContainerSpec.Env' \
                | sed -e 's/[][]//g' -e 's/^ *"//' -e 's/",*$//' \
                | awk -F= 'NF == 1 || $2 == ""' \
                | egrep -v "^$"
            )

            if [[ "$SVC_ENV_STATUS" != "null" && -n "$SVC_ENV_STATUS" ]]; then
                echo "------> $service_name - ${SVC_NAME} - ENV ERROR - $SVC_ENV_STATUS"

                to=${SLACK_CHANNEL}
                message="🚨 *Empty ENV detected!*
                    *Stack:* $i
                    *Task:* $SVC_NAME ($service_name)
                    *Empty ENV:*
                \`\`\`
                $SVC_ENV_STATUS
                \`\`\`
                    "
                send_to_slack
            fi
        fi

        EXCLUDE_APP="leviafun_app"
        if [ "$( echo $EXCLUDE_APP | grep $SVC_NAME | wc -l)" == "0" ] ; then
            if [ "$(docker service inspect $service_name --format '{{.Spec.Mode.Global}}')" == "<nil>" ] ; then
                
                # echo "stack $i - srv $SVC_NAME ($service_name)"
                
                check_svc_replicas=$(docker service inspect $service_name --format '{{.Spec.Mode.Replicated.Replicas}}')
                check_svc_running=$(docker service ps $service_name | grep Running |  wc -l)
                
                # echo "$check_svc_running of $check_svc_replicas"

                if [ "$check_svc_running" -ne "$check_svc_replicas" ] || [ "$check_svc_running" -lt "$check_svc_replicas" ]; then 
                    if [ "$check_svc_running" -gt "$check_svc_replicas" ] ; then
                        echo "ВОЗМОЖНЫЙ АПДЕЙТ $SVC_NAME"
                        
                        # начинаем считать
                        echo "update $SVC_NAME" >> /tmp/$SVC_NAME
                    else
                        # начинаем считать
                        echo "alert $SVC_NAME" >> /tmp/$SVC_NAME
                        
                        if [ "$(cat /tmp/$SVC_NAME | wc -l)" -gt "3" ]; then
                            echo "------> $service_name -$(docker service inspect $service_name --format "{{.Spec.Name}}") - Replicas ERROR - runnig $check_svc_running of $check_svc_replicas"
                            
                            to=${SLACK_CHANNEL}
                            message="🧨 *Replica count mismatch!*
                                *Stack:* $i
                                *Task:* $SVC_NAME ($service_name)
                                *Running:* $check_svc_running / *Expected:* $check_svc_replicas
                                "
                            send_to_slack
                        fi
                    fi
                else
                    # cтираем все данные
                    > /tmp/$SVC_NAME  
                fi
            fi
        fi
    done
done

exit
