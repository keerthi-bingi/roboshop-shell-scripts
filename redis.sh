#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="/var/log/shell-script/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}


dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "Disabling Latest redis Server"

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "Enabling redis 7"

dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "Installing redis 7"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"

sed -i 's/yes/no/g' /etc/redis/redis.conf
VALIDATE $? "Disabling protection Mode"

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "Enabling redis"

systemctl start redis &>>$LOGS_FILE
VALIDATE $? "Starting redis"