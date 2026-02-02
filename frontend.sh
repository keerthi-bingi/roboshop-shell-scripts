#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

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

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Nginx:1.24"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "Installing Frontend code"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Unzip Frontend code"

rm -rf /etc/nginx/nginx.conf &>>$LOGS_FILE

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying Frontend config"

systemctl enable nginx &>>$LOGS_FILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "Starting nginx"