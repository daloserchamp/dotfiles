#!/bin/bash
archive="$1"
dest="$2"
mkdir -p "$dest"
bsdtar -xf "$archive" -C "$dest"
