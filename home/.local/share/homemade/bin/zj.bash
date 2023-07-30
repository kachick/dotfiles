#!/usr/bin/env bash

name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name"
