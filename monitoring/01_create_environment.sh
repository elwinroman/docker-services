#!/bin/bash

docker network inspect monitoring >/dev/null 2>&1 || docker network create monitoring
