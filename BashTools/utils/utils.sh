#!/bin/bash


function log_status(){
    if [ $# -lt 2 ]
    then
	echo "Usage: log_status status \"message\" "
	exit 1
    fi

    printf "%s status %i\n" $2 $1 >> $WORKFLOW_LOG_FILE
    
}

export -f log_status


function check_status(){
    if [ $# -lt 1 ]
    then
	echo "Usage: check_status status"
	exit 1
    fi


    if [ ! -z "$2" ]
    then
	log_status $1 "$2"
    fi

    
    if [ $1 -ne 0 ]
    then
	exit 1
    fi

}

export -f check_status
