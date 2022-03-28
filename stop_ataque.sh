#!/bin/bash

ps -aux | grep 'for i in `seq 1 10' | awk '{print $2}' | sudo xargs kill -9
