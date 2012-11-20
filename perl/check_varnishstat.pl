
#! /usr/bin/perl -w

use strict;
use Getopt::Long;
use vars qw($PROGNAME);

my ($opt_e, $opt_c, $opt_f, $opt_w, $opt_h, $opt_V, $opt_v);
my ($result, @status_old, @status_new, $content_new, $line_new, @value_new, $olddata_file, $line_old, @value_old, $value_div, $output);
my (@criticals, @warnings, $value_crit, $value_warn, $critical_errout, $warning_errout);

$PROGNAME="check_varnishstat";
my $HOSTNAME=`hostname`;
chomp($HOSTNAME);
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

$opt_w = undef;
$opt_c = undef;
$opt_f = undef;
$critical_errout = "";
$warning_errout = "";


Getopt::Long::Configure('bundling');
GetOptions(
        "V"   => \$opt_V, "version"     => \$opt_V,
        "v"   => \$opt_v, "verbose"     => \$opt_v,
        "h"   => \$opt_h, "help"        => \$opt_h,
        "f=s" => \$opt_f, "fields=s"    => \$opt_f,
        "w=s" => \$opt_w, "warning=s"   => \$opt_w,
        "c=s" => \$opt_c, "critical=s"  => \$opt_c) or die "Incorrect usage!\n";

sub print_usage {
        print "Usage:\n";
        print "  $PROGNAME [-w <value>] [-c <value>] -f <field,field,field>\n";
        print "  $PROGNAME [-h | --help]\n";
        print "  $PROGNAME [-v | --verbose]\n";
        print "  $PROGNAME [-V | --version]\n";
}

sub print_help {
        print "Copyright (c) 2003 Steven Grimm\n\n";
        print_usage();
        print "\n";
        print "\n";
}

sub print_debug {
        print "Hostname = $HOSTNAME\n";
        print "fields = $opt_f\n";
        print "warnings = $opt_w\n";
        print "criticals = $opt_c\n";
        print "--- OLD VALUES ---\n";
        print @status_old;
        print "--- NEW VALUES ---\n";
        print @status_new;
}


if ($opt_V) {
        print "$PROGNAME, v1.0 2012/11/11 Gianni Carafa\n";
        exit $ERRORS{'OK'};
}

if ($opt_h) {
        print_help();
        exit $ERRORS{'OK'};
}

if ( !$opt_w || !$opt_c || !$opt_f) {
        print_usage();
        exit;
}

@status_new = qx(varnishstat -1 -f $opt_f);

$olddata_file="/tmp/varnishstatplugin_$HOSTNAME.txt";
open(DAT, $olddata_file);
@status_old=<DAT>;

@criticals = split (/,/, $opt_c);
@warnings = split (/,/, $opt_w);


if($opt_v) {
        print_debug();
}


foreach $line_new ( @status_new ){
        $line_old = shift(@status_old);
        $value_crit = shift(@criticals);
        $value_warn = shift (@warnings);

        #$value_crit + 0;
        #$value_warn + 0;

        @value_old = split (/\s+/, $line_old);
        @value_new = split(/\s+/,$line_new);

        $value_div =  $value_new[1]-$value_old[1];
        $content_new .= "$value_new[0] $value_new[1] \n";
        $output .= "$value_new[0] $value_new[1] $value_div | ";

        if ($value_div > $value_crit){
                $critical_errout .= "$value_new[0] $value_div > $value_crit";
        }elsif( $value_div > $value_warn) {
                $warning_errout .= "$value_new[0] $value_div > $value_warn";
        }

}

open (VALUESFILE, ">/tmp/varnishstatplugin_$HOSTNAME.txt");
print VALUESFILE $content_new;
close VALUESFILE;



if (length($critical_errout) > 0){
        $result = "CRITICAL";
        $output .= "CRITICALS: $critical_errout";
}elsif (length($warning_errout) > 0){
        $result = "WARNING";
        $output .= "WARNINGS: $warning_errout";
}else{
        $result = "OK";
}




print "$result $output";
exit $ERRORS{$result};

