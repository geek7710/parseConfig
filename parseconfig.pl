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
    @ConfigList_unfiltered,
    $mainDirectory,
    $base_dir,
    $device_count,
    $filtered_list,
    $device_pattern,
    @config_match,
    @config_all_list,
    $parse_external_file,
    $config_list_file,
    $list_dir_pattern,
    $list_directory,
    @configList_filtered,
);

# defining some global variables
$customer_name = `ls /home/cvs/customers/`;
$customer_name =~ s/\s+$//;

# script arguments
GetOptions('r|regex=s'          => \$device_pattern,
           'c|create'           => \$filtered_list,
           'p|parse=s'          => \$parse_external_file,
           'f|file=s'           => \$config_list_file,
           'l|list'             => \$list_dir_pattern,
           '-a|all'             => \$list_directory,
           'help|?|h'           => sub { help(); },
        ) or die help();

# path in the BMN, where configuration files are stored
$base_dir = "/home/cvs/customers/".$customer_name."/Network-Configs/configs/";
$mainDirectory = "ls /home/cvs/customers/".$customer_name."/Network-Configs/configs/";
@ConfigList_unfiltered = `$mainDirectory | grep -v 'Attic'`;

# Help information
sub help {
    print "\n=============================================\n";
    print "USAGE:\n";
    print "\n* List device configuration(s) only, test regular expression\n";
    print "  $0 -r|--regex <regex> -l|--list\n";
    print "\n* List all confirations stored in config directory\n";
    print "  $0 -a|--all\n";
    print "\n* Create a file with a list of configurations, generated after regular expression\n";
    print "  $0 -r|--regex <regex> --create|-c\n";
    print "\n* Parse configuration from file, the file must include objects\n";
    print "    that have the exact name as configurations stored by rancid\n";
    print "  $0 -f|--file <file_name> -p|--parse [regex1] [regex2] [regex(n)]\n";
    print "\n=============================================\n\n";
}

sub print_pattern_match {
    # initializing local variables to this function
    my $configName;
    my $device_count;
    if ($device_pattern) {
        foreach $configName (@ConfigList_unfiltered) {
            if ($configName =~ /$device_pattern/gi) {
                # remove ',v' from the end of the config file
                $configName =~ s/,v$//;
                push(@config_match, $configName);
                $device_count++;
            }
        }
    }
    if ($device_count > 0){
        print "\nLISTING CONFIGURATIONS...\n\n";
        for my $line (@config_match) {
            printf " %s",$line;
        }
        printf "\nYOUR PATTERN MATCHES: %d CONFIGURATION FILES\n",$device_count;
    } else {
        print "\nUNFORTUNATELY YOUR PATTERN DIDNT MATCH ANY FILE\n";
    }
}

sub print_all {
    my $configName;
    my $device_count;
    while (<@ConfigList_unfiltered>) {
        $_ =~ s/,v$//;
        push(@config_all_list, $_);
        $device_count ++;
    }
    printf "\nLISTING CONFIGURATIONS...\n\n";
    for my $line (@config_all_list) {
        printf "%s",$line;
    }
    printf "\nYOUR PATTERN MATCHES: %d CONFIGURATION FILES\n",$device_count;
}

sub parse_external_file {
    my $filename = shift;
    open(FH, "<", $filename)
    or die "Could not open file $filename OR file does not exist\nERROR: $!";
    while (<FH>) {
        print "$_";
    }
    close FH;
}

sub print_to_file {
    #initializing local variables
    my @list_to_print;
    my $filename = $customer_name."_filteredList.txt";
    open(FH, '>', $filename) 
    or die "I could not create file '$filename': $!";
    if (@config_match) {
        @list_to_print = @config_match;
    } else {
        @list_to_print = @ConfigList_unfiltered;
    }
    foreach my $config (@list_to_print) {
        print FH $config;
    }
    close FH;
    print "\n$filename HAS BEEN CREATED...\n\n";
}

sub open_config_list {
    # declaring local variables
    my $config;
    open($config, '<', $config_list_file) or
    die "Cannot open $config_list_file file: $!";
    while (<$config>) {
        print $_;
    }
}

sub open_config{
    # open configuration file for reading
    
}

# set the search according to device_pattern entered, if no patter was entered
# then parse the whole directory content
if ($device_pattern && $list_dir_pattern) {
    print_pattern_match();
} elsif ($device_pattern && $filtered_list) {
    print_to_file();
} elsif ($parse_external_file) {
    parse_external_file($parse_external_file);
} elsif ($config_list_file) {
    open_config_list();
} elsif ($list_directory && $filtered_list) {
    print_to_file();
}
elsif($list_directory) {
    print_all();
} else {
    help();
}


__END__
This script was created with the intention to run on certain devices without
having to parse the 1000+ device we are managin. By reducing the amount of 
devices, the results come back faster and we just focus on the devices we 
want to audit.