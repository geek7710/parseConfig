#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use Getopt::Long qw(:config no_ignore_case bundling);

# declaring global variables
my (
    $devicePattern,
    $customer_name,
    @devices,
    $mainDirectory,
    $base_dir,
    $device_count,
    $filtered_list,
    $opt_help,
    $parse_externalList,
    $device_pattern,
    @device_match,
);

# defining some global variables
$customer_name = `ls /home/cvs/customers/`;
$customer_name =~ s/\s+$//;

# script arguments
GetOptions('d|device_pattern=s' => \$device_pattern,
           'l|list'             => \$filtered_list,
           'p|parse'            => \$parse_externalList,
           'help|?|h'           => sub { help(); },
        ) or die help();

# path in the BMN, where configuration files are stored
$base_dir = "/home/cvs/customers/".$customer_name."/Network-Configs/configs/";
$mainDirectory = "ls /home/cvs/customers/".$customer_name."/Network-Configs/configs/";
@devices = `$mainDirectory`;

# Help information
sub help {
    print "This is helping...\n";
}

sub print_device_pattern {
    my $configName;
    foreach $configName (@devices) {
        if ($configName =~ /$device_pattern/gi) {
            $configName =~ s/,v$//;
            push(@device_match, $configName);
            $device_count++;
        }
    }
    print "\nLISTING CONFIGURATIONS...\n\n";
    print "@device_match\n";
    printf "I FOUND: %d DEVICES\n",$device_count;
}

sub parse_list {
    my $external_list = $_;
    open(FH, "<", $external_list) or die "I cannot open: $external_list: $!";
}

sub create_file {
    my $filename = $customer_name."_filteredList.txt";
    open(FH, '>', $filename) or die "Could not open file '$filename': $!";
    foreach my $config (@device_match) {
        print FH $config;
    }
    close FH;
    print "\n$filename HAS BEEN CREATED...\n\n";
}
# set the search according to device_pattern entered, if no patter was entered
# then parse the whole directory content
if ($device_pattern) {
    print_device_pattern();
} else {
    help;
}
if ($device_pattern && $filtered_list) {
    create_file();
}
if ($parse_externalList) {
    parse_list();
}

__END__
This script was created with the intention to run on certain devices without
having to parse the 1000+ device we are managin. By reducing the amount of 
devices, the results come back faster and we just focus on the devices we 
want to audit.