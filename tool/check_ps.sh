#!/bin/sh

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 1.0,"
AUTHOR="2009, Mike Adolphs (http://www.matejunkie.com/)"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

process="cron"
target="mem"

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check a specific process via ps."
    echo "You may provide any string as an argument to match a specific"
    echo "process. Please note that the output could be distorted if the"
    echo "argument matches various processes, so please make sure to use"
    echo "unique strings to match a process."
    echo ""
    echo "$PROGNAME -p firefox [-w 10] [-c 20] [-t cpu]"
    echo ""
    echo "Options:"
    echo "  -p/--process)"
    echo "     You need to provide a string for which the ps output is then"
    echo "     then \"greped\"."
    echo "  -w/--warning)"
    echo "     Defines a warning level for a target which is explained"
    echo "     below. Default is: off"
    echo "  -c/--critical)"
    echo "     Defines a critical level for a target which is explained"
    echo "     below. Default is: off"
    echo "  -t/--target)"
    echo "     A target can be defined via -t. Choose between cpu and mem."
    echo "     Default is: mem"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --process|-p)
            process=$2
            shift
            ;;
        --target|-t)
            target=$2
            shift
            ;;
        --warning|-w)
            warning=$2
            shift
            ;;
        --critical|-c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

get_wcdiff() {
    if [ ! -z "$warning" -a ! -z "$critical" ]
    then
        wclvls=1
        if [ ${warning} -gt ${critical} ]
        then
            wcdiff=1
        fi
    elif [ ! -z "$warning" -a -z "$critical" ]
    then
        wcdiff=2
    elif [ -z "$warning" -a ! -z "$critical" ]
    then
        wcdiff=3
    fi
}

val_wcdiff() {
    if [ "$wcdiff" = 1 ]
    then
        echo "Please adjust your warning/critical thresholds. The warning \
must be lower than the critical level!"
        exit $ST_UK
    elif [ "$wcdiff" = 2 ]
    then
        echo "Please also set a critical value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    elif [ "$wcdiff" = 3 ]
    then
        echo "Please also set a warning value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    fi
}

get_vals() {
    process=`echo ${process} | sed 's/^.\|[a-z][A-Z] /\[&]/g'`

    tmp_output=`ps aux | grep "$process" | grep -v $0`

    if [ -z "$tmp_output" ]
    then
        echo "CRITICAL - Process is not running!"
        exit $ST_CR
    fi

    ps_user=`echo ${tmp_output} | awk '{print $1}'`
    ps_pid=`echo ${tmp_output} | awk '{print $2}' `
    ps_cpu=`echo ${tmp_output} | awk '{print $3}'`
    ps_mem=`echo ${tmp_output} | awk '{print $4}' `
    ps_start=`echo ${tmp_output} | awk '{print $9}' `

    tmp_ps_cputime=`echo ${tmp_output} | awk '{print $10}'`
    tmp_ps_cpuhours=`echo ${tmp_ps_cputime} | awk -F \: '{print $1}'`
    tmp_ps_cpumin=`echo ${tmp_ps_cputime} | awk -F \: '{print $2}'`
    ps_cputime=`echo "scale=0; (${tmp_ps_cpuhours} * 60) + \
${tmp_ps_cpumin}" | bc -l`
}

do_wccalc() {
    if [ -n "$warning" -a -n "$critical" ]
    then
        if [ "$target" = "cpu" ]
        then
            tmp_wc_target=`echo ${ps_cpu} | awk -F \. '{print $2}'`
            if [ "$tmp_wc_target" -ge 5 ]
            then
                wc_target=`echo ${ps_cpu} | awk -F \. '{print $1}'`
                wc_target=`expr ${wc_target} + 1`
            else
                wc_target=`echo ${ps_cpu} | awk -F \. '{print $1}'`
            fi
		elif [ "$target" = "mem" ]
		then
            tmp_wc_target=`echo ${ps_mem} | awk -F \. '{print $2}'`
            if [ "$tmp_wc_target" -ge 5 ]
            then
                wc_target=`echo ${ps_mem} | awk -F \. '{print $1}'`
                wc_target=`expr ${wc_target} + 1`
            else
                wc_target=`echo ${ps_mem} | awk -F \. '{print $1}'`
            fi
        fi
    fi
}


do_output() {
	process=`echo ${process} | sed 's/\[//g' |  sed 's/\]//g'`
	output="Process: ${process}, User: ${ps_user}, CPU: ${ps_cpu}%, \
RAM: ${ps_mem}%, Start: ${ps_start}, CPU Time: ${ps_cputime} min"
}

do_perfdata() {
	perfdata="'cpu'=${ps_cpu} 'memory'=${ps_mem} 'cputime'=${ps_cputime}"
}

# Here we go!
get_wcdiff
val_wcdiff

get_vals
do_wccalc
do_output
do_perfdata

if [ -n "$warning" -a -n "$critical" ]
then
    if [ "$wc_target" -ge "$warning" -a "$wc_target" -lt "$critical" ]
    then
        echo "WARNING - ${output} | ${perfdata}"
	exit $ST_WR
    elif [ "$wc_target" -ge "$critical" ]
    then
        echo "CRITICAL - ${output} | ${perfdata}"
	exit $ST_CR
    else
        echo "OK - ${output} | ${perfdata} ]"
	exit $ST_OK
    fi
else
    echo "OK - ${output} | ${perfdata}"
    exit $ST_OK
fi
