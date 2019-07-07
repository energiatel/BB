#!/bin/bash

MAIN_DIR="/root/projects"
COMMON_FILES="/root/common_files"

mkdir -p $COMMON_FILES
mv /root/fdns $COMMON_FILES/ 2>/dev/null

mkdir -p $MAIN_DIR
echo "Usage $0 ProjectName"

echo "Insert name project"

read project_name
mkdir -p "$MAIN_DIR/$project_name"
echo "$MAIN_DIR/project_name created"
echo "PROJECT_NAME=$project_name" > $MAIN_DIR/$project_name/Description
echo "Created Description file"

echo "Insert project URL"
read project_url
echo "PROJECT_URL=$project_url" >> $MAIN_DIR/$project_name/Description

mkdir -p "$MAIN_DIR/$project_name/subdomains"
echo "Created $MAIN_DIR/$project_name/subdomains directory"
mkdir -p "$MAIN_DIR/$project_name/takeover"
echo "Created $MAIN_DIR/$project_name/takeover directory"

echo "Insert domain"
read domain
echo "SUBDOMAIN=$domain" >> $MAIN_DIR/$project_name/Description

echo "Insert out of scope subdomain"
read out_of_scope_domain
echo "SUBDOMAIN_OUT_OF_SCOPE=$out_of_scope_domain" >> $MAIN_DIR/$project_name/Description

