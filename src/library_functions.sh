#!/bin/bash

#arg1 is property file, arg2 is property name
read_property() {
  cat "$1" | grep "$2" | cut  -d "=" -f2 | xargs
}