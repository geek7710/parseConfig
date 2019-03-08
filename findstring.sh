#!/bin/bash

version=3.0

#Record time for performance measurement.
#starttime=$(date +%s%3N)

#Initialize variables.
max_threads=20  #The number threads used by xargs for the workers.
batchsize=40    #The number of files processed by the workers per batch.
                #A larger batch size makes the main routine more efficient,
                #but delays the initial output to the screen.
basedir="/home/cvs/customers"   #The root directory for the configuration files.
path=$basedir                   #The path gets adjusted depending on user input.
#Following are the variables that contain the command line arguments.
countsw=""
detailsw=""
DETAILsw=""
groupsw=""
grouparg=""
tabsw=""
casesw=""
nomatchsw=""
aftersw=""
beforesw=""
contextsw=""
maxsw=""
onlysw=""
stanzasw=""
Stanzasw=""
formatsw=" -F"  #Set the default format to 'txt', which means human readable.
formatarg=" txt"
customer=""
custsw=""
custarg=""
filesw=""
betweensw=""
filearg=""
orig_filearg=""
#End of command line argument variables.
Esw=""
doctored_regexp=""
matchdesc=""
header=""
details=""
count=0
firstline="Y"
lastcustline="zzzzzzzzzz"
pid=$$

#Set variables based on command line input.
#Get the regexp(s) from the command line.
in_regexp=${!#}

#echo "debug: args=$args, $@" >&2

#If no arguments were entered, turn ON the help switch.
if [ $# -eq 0 ]
then
        helpsw="-h"
fi

#Process the switches.
while getopts ":A:B:b:C:c:DdF:f:g:hikLm:noSsvwx" option $args
do
        case "${option}" in
                d ) detailsw=" -d"
                ;;
                A ) aftersw=" -A"
                    afterarg=" $OPTARG"
                    detailsw=" -d"
                ;;
                B ) beforesw=" -B"
                    beforearg=" $OPTARG"
                    detailsw=" -d"
                ;;
                b ) betweensw=" -b"
                    betweenarg="${OPTARG}"
                ;;
                C ) contextsw=" -C"
                    contextarg=" $OPTARG"
                    detailsw=" -d"
                ;;
                c ) custsw=" -c"
                    custarg=$OPTARG
                ;;
                D ) DETAILsw=" -D"
                    detailsw=" -d"
                ;;
                f ) filesw=" -f"
                    orig_filearg=$OPTARG
                    filearg="$orig_filearg"
                    if [ "$orig_filearg" == "-" ]
                    then
                                        orig_filearg="STDIN"
                    fi
                ;;
                F ) formatsw=" -F"
                    formatarg=" $OPTARG"
                ;;
                g ) groupsw=" -g"
                                #Doctor the argument a bit to make it very unlikely we'll get
                                #a match with real text when doing the sed later.
                          grouparg=`echo "${OPTARG}" | sed -r -e 's/(\\\\[1-9])/__\1/g'`
                    detailsw=" -d"
                ;;
                h ) helpsw="-h"
                ;;
                i ) casesw=" -i"
                ;;
                k ) countsw=" -k"
                    detailsw=""
                    DETAILsw=""
                ;;
                L ) nomatchsw=" -L"
                    matchdesc=" do not"
                    detailsw=""
                    DETAILsw=""
                ;;
                m ) maxsw=" -m"
                    maxarg=" $OPTARG"
                    detailsw=" -d"
                ;;
                n ) numsw=" -n"
                    detailsw=" -d"
                ;;
                o ) onlysw=" -o"
                    detailsw=" -d"
                ;;
                s ) stanzasw=" -s"
                    detailsw=" -d"
                ;;
                S ) Stanzasw=" -S"
                    detailsw=" -d"
                ;;
                v ) echo ""
                    echo "$0 version: $version"
                    echo ""
                    exit
                ;;
                * ) echo "" >&2
                    echo "Invalid command line option '$OPTARG'." >&2
                    helpsw="-h"
        esac
done

#Display help if requested or there was an invalid entry.
if [ $helpsw ]
then
        echo ""
        echo "This script searches network device configurations for strings of characters."
        echo "It uses some of the same switches as grep as well as some unique to its purpose."
        echo ""
        echo "Usage: $0 [options] 'regexp[&regexp...]'"
        echo ""
        echo "'regexp' is the regular expression to use for the search."
        echo "         Multiple regexps separated by an ampersand indicate that all regexps must"
        echo "         be matched within a configuration in order for there to be a match."
        echo ""
        echo "Options:"
        echo "-A num    Show 'num' lines after the matching line(s)"
        echo "-B num    Show 'num' lines before the matching line(s)"
        echo "-b arg    Show lines between the -b arg and regexp, including the matching line(s)"
        echo "-C num    Show 'num' lines before and after the matching line(s)"
        echo "-c cust   Search this customer's configs only"
        echo "-d        Show details; i.e. the actual matching lines"
        echo "-D        Show details AND show devices that do not have matching lines"
        echo "-f file   Search these config files only (can use regexp or a file name"
        echo "            that contains a list of files)"
        echo "-F format Output in the specified format:"
        echo "            txt  = human readable text (default)"
        echo "            list = list of device names only"
        echo "            tab  = tab delimited"
        echo "            tab1 = same as tab delimited, but one output line per occurence"
        echo "            csv  = comma separated values"
        echo "            csv1 = same as comma separated, but one output line per occurence"
        echo "            ran  = RANCID clogin commands" 
        echo "            mcd  = mc-diff input" 
        echo "            yaml = YAML" 
        echo "-g arg    Show only the matching regexp groups specified by the arg"
        echo "-h        Display this help information"
        echo "-i        Case insensitive search"
        echo "-k        Show the count of matching line(s)"
        echo "-L        Return only configs that do NOT match the search criteria"
        echo "-m num    Show a maximum of 'num' matches"
        echo "-n        Show the line numbers of the matching lines"
        echo "-s        Show the stanza statements for the line(s) that match the regex."
        echo "-S        Show the lines in the stanza for the line(s) that match the regex."
        echo "-v        Show the version of this script"
        echo "-w        Match on whole words only"
        echo""
        echo "For more information, please see https://wiki.services.cdw.com/w/Findstring"
        echo""
        exit
fi

#sudo to root if file permissions require it.
if [ ! -d $basedir ]
then
        sudo $0 "$@"
        exit
fi

#Turn off the detailsw if output format is "list".
if [ "$formatarg" == " list" ]
then
        detailsw=""
fi

header="\n"
header+=$(date)
header+="\nSearch Criteria:"

if [ $detailsw ]
then
        detaildesc=" and lines"
else
        detaildesc=""
fi

if [ $custsw ]
then
        custdesc=" for customer '$custarg'"
else
        custdesc=""
fi

if [ $filesw ]
then
        if [ "$orig_filearg" == "$filearg" ]
        then
                header+=" File names$detaildesc$custdesc matching '$filearg' that$matchdesc match '$in_regexp'"
        else
                header+=" File names$detaildesc$custdesc matching the files listed in '$orig_filearg' that$matchdesc match '$in_regexp'"
        fi
else
        if [ -e "$in_regexp" ]
        then
                header+=" All files$detaildesc$custdesc that$matchdesc match matches to the regular expressions in file '$in_regexp'"
        else
                header+=" All files$detaildesc$custdesc that$matchdesc match '$in_regexp'"
        fi
fi

if [ $beforesw ]; then header+="\n Show $beforearg lines before the match."; fi
if [ $aftersw ]; then header+="\n Show $afterarg lines after the match."; fi
if [ $betweensw ]; then header+="\n Show lines between '$betweenarg' and '$in_regexp', inclusive."; fi
if [ $contextsw ]; then header+="\n Show $contextarg lines before and after the match."; fi
if [ $maxsw ]; then header+="\n Show a maximum of $maxarg matches."; fi
if [ $onlysw ]; then header+="\n Show only the matching string."; fi
if [ $stanzasw ]; then header+="\n Show the stanza heading lines for the matching lines."; fi
if [ $Stanzasw ]; then header+="\n Show all the lines in the stanza for the matching stanza heading lines."; fi
if [ $countsw ]; then header+="\n Show the count of matching lines."; fi
if [ $DETAILsw ]; then header+="\n Show device info, even if there are no matching lines."; fi
if [ $groupsw ]; then header+="\n Use regex groups to format output."; fi

#Now that we've built the header lines, output them to the right place.
if [ "$formatarg" == " txt" ]
then
        echo -e "$header"
else
        echo -e "$header" >&2
fi

#Get the list of files we want to search.
#If filearg is an existing file, we assume it contains a list of files.
#Join the lines together into one grep regexp of the form 'line1|line2|line3\etc.' and put that into filearg.
#if [[ "$filearg" != "" && ("$filearg" == "-" || -e $filearg) ]]
#then
#       filearg=$(cat $filearg | tr -s "\n" "|" | sed 's/ //g' | sed 's/^|//' | sed 's/|$//')
#fi

#Position ourselves in the directory we want to search in.
if [ ! -d $basedir/$custarg ]
then
        echo "Customer '$custarg' does not exist." >&2
        echo "" >&2
        exit
else
        path=$basedir/$custarg
fi

#binc-infra/slot3 is excluded because it is equivalent to an Attic.
#
#If a file containing a list of files is input, we split it into groups,
#because it turns out that evaluating a large regex against a large number of files takes very long time.
#It's faster to split it into multiple smaller groups.
#
#The fancy formatting for the 'find' command, the reverse sort, the unique sort, the cut, and the sort at the end lets
#us get only the most recent file for each device sorted by device name within customer.
#The printf format outputs the file name, modification time and full path name.
#The first sort orders the list by file name and modification time in reverse order.
#The second sort with the unique option gets just the first file for each file name (newest because of the previous reverse sort).
#The cut gives us the full path name, which is all we wanted in the first place.
#The final sort orders the list by device within customer, because the path starts with the customer abbreviation.
if [[ "$filearg" != "" && ("$filearg" == "-" || -e $filearg) ]]
then
        filearg=$(cat $filearg | tr -s "\n" "|" | sed 's/ //g' | sed 's/^|//' | sed 's/|$//')
        IFS='|'
        argcount=0
        files=""
        for arg in $filearg
        do
                if [ $argcount -gt 100 ]
                then
                        new_files=$(find $path -type f -printf "%f\t%T+\t%p\n" | egrep -e "$args")
                files="$files
$new_files"
                        argcount=0
                        args=""
                fi
                if [ $argcount -eq 0 ]
                then
                        args=$arg
                else
                        args="$args|$arg"
                fi
                (( argcount++ ))
        done
        new_files=$(find $path -type f -printf "%f\t%T+\t%p\n" | egrep -e "$args")
        files="$files
$new_files"
        files=$(echo $files | egrep  "configs" | egrep -v "Attic|RETIRED|CVS|binc-infra/slot3" | sort -r -k1,2 | sort -u -k1,1 | cut -f3 | sort -t/ -k5,5 -k9,9)
        unset IFS
else
        files=$(find $path -type f -printf "%f\t%T+\t%p\n" | egrep -e "$filearg" | egrep  "configs" | egrep -v "Attic|RETIRED|CVS|binc-infra/slot3" | sort -r -k1,2 | sort -u -k1,1 | cut -f3 | sort -t/ -k5,5 -k9,9)
fi
#echo "debug: files=" >&2
#echo "$files" >&2
#exit

if [ $betweensw ]
then
        #Set the beforesw and beforearg.
        #This allows us to do a normal 'before' search to get things started.
        beforesw=" -B"
        beforearg=" 100000"
        #Set the -E switch so that we can pass the doctored in_regexp to the worker routine.
        Esw=" -E "
        doctored_regexp="$in_regexp"
        #Tweak the in_regexp and betweenarg reqexp's to make "^" searches work, if needed.
        caretcount=$(echo "$betweenarg" | grep -c "^\^")
        if [ $caretcount -gt 0 ]
        then
                betweenarg=$(echo "$betweenarg" | sed -e "s/.\(.*\)/^[0-9]*-\1/")       #Replace the "^" with a regexp that matches line numbers.
        fi
        caretcount=$(echo "$in_regexp" | grep -c "^\^")
        if [ $caretcount -gt 0 ]
        then
                doctored_regexp=$(echo "$in_regexp" | sed -e "s/.\(.*\)/^[0-9]*:\1/")   #Replace the "^" with a regexp that matches line numbers.
        fi
fi

i=0

#Following block is used for debugging.
#echo "aftersw=$aftersw afterarg=$afterarg" >&2
#echo "betweensw=$betweensw betweenarg=$betweenarg" >&2
#echo "beforesw=$cwbeforesw beforearg=$beforearg" >&2
#echo "contextsw=$contextsw contextarg=$contextarg" >&2
#echo "detailsw=$detailsw" >&2
#echo "DETAILsw=$DETAILsw" >&2
#echo "formatsw=$formatsw formatarg=$formatarg" >&2
#echo "groupsw=$groupsw grouparg=$grouparg" >&2
#echo "numsw=$numsw" >&2
#echo "casesw=$casesw" >&2
#echo "nomatchsw=$nomatchsw" >&2
#echo "maxsw=$maxsw maxarg=$maxarg" >&2
#echo "onlysw=$onlysw" >&2
#echo "pid=$pid" >&2
#echo "stanzasw=$stanzasw" >&2
#echo "Stanzasw=$Stanzasw" >&2
#echo "in_regexp=$in_regexp" >&2
#echo "doctored_regexp=$doctored_regexp" >&2

#Export all of the variables that will be passed via xargs. This is required.
export afterarg
export aftersw
export beforearg
export beforesw
export betweenarg
export betweensw
export casesw
export contextarg
export contextsw
export countsw
export detailsw
export DETAILsw
export doctored_regexp
export Esw
export formatarg
export formatsw
export grouparg
export groupsw
export in_regexp
export nomatchsw
export maxsw
export maxarg
export numsw
export onlysw
export pid
export stanzasw
export Stanzasw

#These counters are used to count files.
#i - Counts the total number of files processed.
#ii - Counts the number of files added to the current batch.
#filecount - The total number of files. i is compared to this to determine when we've reached the end.
i=ii=0
filecount=$(echo "$files" | wc -l)

#Record time for performance measurement.
#tmp_starttimestamp=$(date +%s%3N)

#Delete any old temporary findstring files that might be hanging out there, just to be a good linux citizen.
find /tmp -name "findstring_*" -mmin +5 -delete 2> /dev/null

#Output YAML opening lines.
if [ "$formatarg" == " yaml" ]
then
        echo "---"
        echo "customers:"
fi

#Loop through all the files and assemble batches of files to be multi-threaded processed using xargs.
#This allows us to do multi-threading and still display the first results before all work is done.
for file in $files
do
        batch="$batch$file "    #Add the current file to the batch.
        (( i++ ))       #Increment the file counters.
        (( ii++ ))
        if [ $i -gt $batchsize ] || [ $ii -eq $filecount ]      #Have we reached our batch size or the total number of files?
        then    #Yes, so invoke the worker routine using xargs with the batch of files and save the results in 'details'.
                #Record times for performance measurement.
                #tmp_endtimestamp=$(date +%s%3N)
                #tmp_lapsetimestamp=$((tmp_endtimestamp-tmp_starttimestamp))
                #main_lapsetimestamp=$((main_lapsetimestamp+tmp_lapsetimestamp))
                #tmp_starttimestamp=$tmp_endtimestamp
                #Invoke multiple instances of the findstring_worker script using xargs.
                #Pass the arguments plus this script's PID so that they can write their output to unique, identifiable file names.
                ############### Multi-threading starts here ##################
                echo "$batch" | xargs -n1 -P$max_threads sh -c '/opt/bin/findstring_worker -p $pid$countsw$detailsw$DETAILsw$groupsw"$grouparg"$numsw$stanzasw$Stanzasw$casesw$nomatchsw$onlysw$maxsw$maxarg$aftersw$afterarg$beforesw$beforearg$contextsw$contextarg$formatsw$formatarg$betweensw"$betweenarg"$Esw"$doctored_regexp" -e "$in_regexp" $0 > /dev/null'
                ################ Multi-threading ends here ###################
                #Capture the output of the findstring_workers, if any, and then delete it.
                details=""
                details=$(cat /tmp/findstring_$pid.* 2> /dev/null)
                rm -f /tmp/findstring_$pid.* &> /dev/null
                #Record times for  performance measurement.
                #tmp_endtimestamp=$(date +%s%3N)
                #tmp_lapsetimestamp=$((tmp_endtimestamp-tmp_starttimestamp))
                #worker_lapsetimestamp=$((worker_lapsetimestamp+tmp_lapsetimestamp))
                #tmp_starttimestamp=$tmp_endtimestamp

                #Reset the batch related variables.
                i=0
                batch=""

                #echo "debug: details=$details" >&2
                if [ "$details" != "" ] #we have a match.
                then
                        #The output from the worker routines is pretty much ready for output...
                        if [[ "$formatarg" == " txt" || "$formatarg" == " yaml" ]]
                        then    #...but the human readable text format requires some special jujitsu
                                #to keep the "Customer: xxxx" lines from repeating.
                                #We do it this way to avoid a for loop with break processing, which is much slower.
                                #Do a unique sort of the details and save them.
                                details=$(echo -e "$details" | sort -t$'\t' -u -k1,2 -k3,3n)
                                #Delete any customer lines that match the last ones from the previous set of details and output them.
                                echo -e "$details" | grep -v "$lastcustline" | cut -f4-
                                #Save the last customer lines for matching with the next set of details.
                                lastcustline=$(echo -e "$details" | grep -B1 "Customer:" | tail -n2)
                        else
                                #Just sort by customer, device and sequence number
                                #and then strip off customer, device and sequence number before output.
                                echo -e "$details" | sort -t$'\t' -k1,2 -k3,3n | cut -f4-
                        fi
                fi
        fi
done

#Output YAML closing lines.
if [ "$formatarg" == " yaml" ]
then
        echo "..."
fi

#Record time for performance measurement and output the performance numbers.
#endtime=$(date +%s%3N)
#lapsetimestamp=$((endtime-starttime))
#lapsetime=$(bc<<<"scale=2;$lapsetimestamp/1000")
#echo -e "\nQuery completed in $lapsetime seconds." >&2
#worker_time=$(bc<<<"scale=3;$worker_lapsetimestamp/1000")
#main_time=$(bc<<<"scale=3;$main_lapsetimestamp/1000")
#worker_time_percent=$(bc<<<"scale=2;$worker_lapsetimestamp/$lapsetimestamp*100")
#main_time_percent=$(bc<<<"scale=2;$main_lapsetimestamp/$lapsetimestamp*100")
#echo "Main routine time: $main_time ($main_time_percent%)" >&2
#echo "Worker time: $worker_time ($worker_time_percent%)" >&2

[h-custmgmt-msp-2 migboni 15:04:02]~ $ 