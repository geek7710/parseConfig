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
    $device_pattern,
    @device_match,
    $parse_external_file,
);

# defining some global variables
$customer_name = `ls /home/cvs/customers/`;
$customer_name =~ s/\s+$//;

# script arguments
GetOptions('d|device_pattern=s' => \$device_pattern,
           'l|list'             => \$filtered_list,
           'p|parse=s'            => \$parse_external_file,
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

sub parse_external_file {
    my $external_file = shift;
    open(FH, "<", $external_file) 
    or die "Could not open file '$external_file' OR file does not exist\nERROR: $!";
    while (<FH>) {
        print "$_";
    }
    close FH;
}

sub create_file {

    my $filename = $customer_name."_filteredList.txt";
    open(FH, '>', $filename) 
    or die "I could not create file '$filename': $!";

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
}
if ($device_pattern && $filtered_list) {
    create_file();
}
if ($parse_external_file) {
    parse_external_file($parse_external_file);
}

__END__
This script was created with the intention to run on certain devices without
having to parse the 1000+ device we are managin. By reducing the amount of 
devices, the results come back faster and we just focus on the devices we 
want to audit.