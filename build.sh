#!/bin/bash

# Name to use
imageName=cervator/pre-cached-jenkins-agent:latest

# Accept any args passed and add them to the command
docker image build ${@} -t $imageName $(dirname -- "$0")
