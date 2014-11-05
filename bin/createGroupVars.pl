#!/usr/bin/perl

$environment = $ARGV[0];
$region = $ARGV[1];
my $foundRegion = "no";
my $foundKey = "no";
my %ips;
my $count = 0;

open INV, "<", "$ENV{'HOME'}/aws-ansible/inventory/$environment/hosts.gen" or die "Unable to open file hosts.gen\n";
while ( <INV> ) {
    chomp;
    if ( $foundRegion eq "no" ) {
        if ( /^\s*"$region"/ ) {
             $foundRegion = "yes";
        }
    }
    else {
        if ( $foundRegion eq "yes" ) {
            if ( /"(.*)"/ ) {
                $ips{"$1"} = 1;
                $count++;
            }
            else {
                $foundRegion = "done";
            } 
        }
    }
}
close INV;
print "Instance Count for region $region: $count\n";

open INV, "<", "$ENV{'HOME'}/aws-ansible/inventory/$environment/hosts.gen" or die "Unable to open file hosts.gen\n";
open KEYS, ">", "$ENV{'HOME'}/aws-ansible/bin/" . $region . "_keys.dat" or die "Unable to open file $region" . "_keys.dat\n";
open NOKEYS, ">", "$ENV{'HOME'}/scripts/data//no_" . $environment . "_" . $region . "_keys.dat" or die "Unable to open file no_$region" . "_keys.dat\n";

while ( <INV> ) {
    chomp;
    if ( /"(key_(.*))"/ ) {
        $keyname = $2;
        $group_varsFilename = $1;
        if ( -e "$ENV{'HOME'}/.ssh/$environment/$keyname.pem" ) { # if the key file exists
            $foundKey = "yes";
        }
        else {
            print NOKEYS "$keyname\n";
        }
    }
    else {
        if ( $foundKey eq "yes" ) {
            if ( /"(.*)"/ ) { # if record is an IP withing the key group
                if ( $ips{"$1"} eq 1 ) { # if the IP is part of the region
                    open GV, ">", "$ENV{'HOME'}/aws-ansible/inventory/$environment/group_vars/$group_varsFilename" or die "Unable to open output file $group_varsFilename\n";
                    print GV "---\nansible_ssh_private_key_file: $ENV{'HOME'}/.ssh/$environment/$keyname.pem\n";
                    close GV;
                    print KEYS "$keyname\n";
                    $foundKey = "end";
                }
            }
            else { # end of key group
                $foundKey = "end";
            }
        }    
    }
}
close INV;
close KEYS;
close NOKEYS;
