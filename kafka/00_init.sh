#!/bin/bash

if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env created from .env.example"
else
  echo ".env already exists; leaving it unchanged"
fi
