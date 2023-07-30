#!/usr/bin/env bash

zellij attach "$(basename "$PWD")" || zellij --session "$(basename "$PWD")"
