
## Sample Service Script for Amazon Linux AMI
Sample System V init script (service script) for startup services on [Amazon Linux AMI].  Alternative to ' linux daemons' which AWS Linux AMI does not support.

Original script is taken from [wyhasany's script]

And:
- Modified and improved for running on Amazon's RHEL-compatible Linux Image
- Added Environment Variables configuration at startup to enable different configurations at the runtime (for stages like 'Dev', 'Prod'...)

Look at [LSB init scripts] / System V init scripts for more information.

## Usage


Download the script ExampleService.sh

Some example values and implementation is provided in the script. For now, on run it writes Environment Values to the log file


Edit the script by replacing the fields in between the `<Edit Following Fields>` tag with your of values:
* Modify the LSB header. Change `ExampleService` with your name and change default configuration if you wish
* `SERVICE_NAME` = Your service's name
* `SCRIPT` = Your script to run on service start
* `RUNAS` = User to run the `SCRIPT` as
* `PidFileLocation` = Location of PIDFILE to store
* `LogFileLocation` = Location of LOGFILE to store
* Optionally customize Environment Values according to the Runtime as its explained in the script

Start and test your service:

**Install the service to `/etc/init.d` with install command**
```sh
# sh {YOUR_SCRIPT_NAME} install
sh ExampleService.sh install
```
It configures the service to `chkconfig`.  If you don't want to run at boot-time then delete it from `chkconfig`
```sh
# chkconfig --del {YOUR_SERVICE_NAME}
chkconfig --del ExampleService
```

**Start the service**

```sh
service ExampleService start
```

**Start the service with custom Environment Variables.**

If you define Environment Variables for ,say, 'Dev' in the script like;

 `EnvironmentVariables_Dev=( "ConnString:DevString" "ASPNETCORE_ENVIRONMENT:Dev" )
`

then start the service with `--environment` option
```sh
service ExampleService --environment Dev start
```
**Other commands**

` start , stop , status , restart , install , uninstall`

Usage: 
  `service ExampleService --environment Dev {optional} start | stop | status | restart | install | uninstall`

[Amazon Linux AMI]: https://aws.amazon.com/amazon-linux-ami/
[wyhasany's script]: https://github.com/wyhasany/sample-service-script
[LSB init scripts]: https://wiki.debian.org/LSBInitScripts

