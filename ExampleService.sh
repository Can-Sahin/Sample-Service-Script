#!/bin/sh

### BEGIN INIT INFO
# Provides:          ExampleService
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       ExampleService System V init script
### END INIT INFO


# <Edit Following Fields>

# Name of your service
SERVICE_NAME="ExampleService"

# Script to run on service startup
SCRIPT="printenv" # will print Environment Variables to the log file
# Or for example run dotnet console application like
# SCRIPT="/usr/local/bin/dotnet /home/ec2-user/MyExampleDotnetApplication/MyExampleDotnetApplication.dll"

# User to run the SCRIPT as. Running as a user is preferable. So that its aws profiles can be used in your application to access AWS Services
RUNAS=ec2-user

# Select where to store Pid and Log files
PidFileLocation=~/ # Home directory
LogFileLocation=~/ # Home directory

# <Optional configuration>
# Configure Environment Variables according to the RunTimeEnvironment which will be set with --environment cli option
  
  # Source the custom-made environment variables, pick any source file you want
  [ -f /etc/environment ] && . /etc/environment
  # Add for example 'SystemVInitScriptDefaultRuntimeEnvironment=Dev' in your /etc/environment file to set default in this machine
  DefaultRuntimeEnvironment=$SystemVInitScriptDefaultRuntimeEnvironment

  # Declare a default RunTimeEnvironment or leave empty or get the default value from /etc/environment
  RunTimeEnvironment=$DefaultRuntimeEnvironment

  # Define environment variables for each RunTimeEnvironment
  # Format: EnvironmentVariables_{RunTimeEnvironment}
  EnvironmentVariables_Dev=( "ConnString:DevString" "ASPNETCORE_ENVIRONMENT:Dev" )
  
  EnvironmentVariables_Prod=( "ConnString:ProdString" )
# </Optional configuration>

# </Edit Following Fields>


NAME=$SERVICE_NAME
case "$1" in
  --environment)
    RunTimeEnvironment=$2
    shift
    shift
    ;;
  *)
    ;;
esac
echo "RunTimeEnvironment -> $RunTimeEnvironment"

# Set Environment Variables and the Name according to the RunTimeEnvironment
EnvironmentVariables=()
if [ ! -z "$RunTimeEnvironment" ]; then
    NAME="${SERVICE_NAME}_$RunTimeEnvironment"
    Env=$RunTimeEnvironment
    eval varAlias=( '"${EnvironmentVariables_'${Env}'[@]}"' )
    EnvironmentVariables=( "${varAlias[@]}" )
fi

PIDFILE=$PidFileLocation$NAME.pid
LOGFILE=$LogFileLocation$NAME.log
LOCKFILE=/var/lock/subsys/$NAME 

start() {
  if [ -f $PIDFILE ] && [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE); then
    echo 'Service already running' >&2
    return 1
  fi
  echo "Starting service $NAME ..."

  # Prepare the Environment Variables to export when running the command
  setEnvironmentVariablesCMD=""
  if [ ${#EnvironmentVariables[@]} -gt 0 ]; then
    for env in "${EnvironmentVariables[@]}" ; do
        KEY="${env%%:*}"
        VALUE="${env#*:}"
        #echo "Environment Variable: $KEY=$VALUE"
        setEnvironmentVariablesCMD+="export $KEY=$VALUE;"
    done
  fi
  local CMD="$setEnvironmentVariablesCMD $SCRIPT &> \"$LOGFILE\" & echo \$!"
  # ~/.aws/credentials cannot be resolved at runtime with 'su -c ...'
  sudo /sbin/runuser $RUNAS -s /bin/bash -c "$CMD" > "$PIDFILE"
  
  sleep 2
  PID=$(cat $PIDFILE)

  if pgrep -u $RUNAS -f $SERVICE_NAME > /dev/null
  then
    echo "$NAME is now running, the PID is $PID"
    sudo touch $LOCKFILE
  else
    echo ''
    echo "Error! Could not start $NAME!"
  fi
}

stop() {
  sudo rm -f LOCKFILE
  if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
    echo 'Service not running' >&2
    return 1
  fi
  echo 'Stopping service…' >&2
  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"

  echo 'Service stopped' >&2
}

uninstall() {
  echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
  local SURE
  read SURE
  if [ "$SURE" = "yes" ]; then
    stop
    rm -f "$PIDFILE"
    echo "Notice: log file was not removed: $LOGFILE" >&2
    sudo chkconfig --del $SERVICE_NAME
    # update-rc.d -f $NAME remove
    sudo rm -fv "$0"
  fi
}
install() {
  stop
  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  echo "Installing to /etc/init.d/$SERVICE_NAME"
  sudo cp $DIR/$SERVICE_NAME.sh /etc/init.d/$SERVICE_NAME
  sudo chmod +x /etc/init.d/$SERVICE_NAME
  sudo chkconfig --add $SERVICE_NAME
  printChkConfigStatus
}

status() {
    printf "%-50s" "Checking $SERVICE_NAME..."
    if [ -f $PIDFILE ] && [ -s $PIDFILE ]; then
        PID=$(cat $PIDFILE)
            if [ -z "$(ps axf | grep ${PID} | grep -v grep)" ]; then
                printf "%s\n" "The process appears to be dead but pidfile still exists"
            else    
                echo "Running, the PID is $PID"
            fi
    else
        printf "%s\n" "Service not running"
    fi
    printChkConfigStatus
}
printChkConfigStatus(){
    (chkconfig $SERVICE_NAME && echo "$SERVICE_NAME is configured for startup") || echo "$SERVICE_NAME is NOT configured for startup"
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: 'service $SERVICE_NAME --environment Dev {optional} start | stop | status | restart | install | uninstall}"
esac