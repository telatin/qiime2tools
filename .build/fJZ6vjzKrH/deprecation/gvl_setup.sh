#!/bin/bash

set -euo pipefail

WEB_DIR='/home/researcher/public_html/';
QIIME_DIR="$WEB_DIR/qiime_2";

if [ "$EUID" -ne 0 ]; then
	echo "ERROR:"
	echo "Please, run this script as root or prepend 'sudo'.";
fi


if [ ! -d "$WEB_DIR" ]; then
	echo "ERROR:";
	echo "The expected directory [$WEB_DIR] was not found. Are you working inside a CLIMB GVL?"
fi

if [ ! -d "$QIIME_DIR" ];
then
	echo " - Creating web directory for Qiime 2 artifacts";
	mkdir -p "$QIIME_DIR"
	chown -R ubuntu:ubuntu "$QIIME_DIR"
else
	echo " - Qiime 2 output directory found: $QIIME_DIR"
fi

if [ ! -e "/home/ubuntu/web" ]; then
	echo " - Creating web directory for generic ouputs"
	mkdir -p "$WEB_DIR/ubuntu/";
	chown -R ubuntu:ubuntu "$WEB_DIR/ubuntu/"
	ln -s "$WEB_DIR/ubuntu" "$HOME/web"
else
	echo " - Generic output directory found: $HOME/web"
fi

