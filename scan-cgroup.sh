#!/bin/bash

function check_memstat() {
   cat $1 | while read item_line; do
      item=$(echo $item_line | awk '{ print $1 }')
      size=$(echo $item_line | awk '{ print $2 }')
      printf "%s," $size
   done
   printf "\n"
}


function check_process() {
   cat $1|while read pid; do
      cmd=$(ps uh $pid | awk '{ print $11 }')
      printf "%s;" $cmd
   done
   printf ","
}
 
function scan_files() {
   printf "%s," $1

   ls $1 |while read line; do
   target_path="$1/$line"

   if [ -r $target_path ]; then
      if [ $line == cgroup.procs ]; then
         check_process $target_path
      fi
      if [ $line == memory.stat ]; then
         check_memstat $target_path
      fi
   fi
 done
}

function scan_dir() {
   printf "%s\n" $1 >> $CGROUPS

   ls $1 |while read line; do
   target_path="$1/$line"

   if [ -d $target_path ]; then
      scan_dir $target_path
   fi
 done
}

function print_header() {
   printf "CGROUP,"
   printf "PROCESS,"

   cat "/sys/fs/cgroup/memory.stat" | while read item_line; do
      item=$(echo $item_line | awk '{ print $1 }')
      printf "%s," $item
   done
   printf "\n"
}

## MAIN
CGROUP_ROOT=/sys/fs/cgroup
CGROUPS=/tmp/cgroups.dat

echo "start"
rm -f $CGROUPS && touch $CGROUPS

# Print Header
print_header

# PASS #1
scan_dir $CGROUP_ROOT

# PASS #2
cat $CGROUPS | while read cgroup; do
   scan_files $cgroup
done

echo "end"
