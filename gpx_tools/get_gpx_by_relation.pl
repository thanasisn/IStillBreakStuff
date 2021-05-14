#!/usr/bin/perl -w

#### Get a gpx file from openstreetmap relation id

use LWP::Simple;
use XML::Tiny qw(parsefile);
use IO::Scalar;

# Which relations do you want to map?
@relations=(9327,9333,34610,47904);
$fn='test.gpx';

# European long distance path E6 - part Greece
@relations=(3924352);
$fn='E6 test.gpx';

# European long distance path E4 - part Greece
@relations=(2376427);
$fn='E4 test.gpx';


@waylist=();
%lat=(); %lon=();

# -----------------------------------------
# Which ways are included in the relations?

foreach $relation (@relations) {

    # Read relation

    print "Reading $relation\n";
    $rel=get("http://www.openstreetmap.org/api/0.6/relation/$relation");
    $XMLFILE=new IO::Scalar \$rel;
    $xml=parsefile($XMLFILE);
    $first=@{$xml}[0];          # get first element of array
    $members=$first->{'content'}[0]->{'content'};
    close $XMLFILE;

    # Parse members

    foreach $member (@{$members}) {
        next unless ($member->{'name'} eq 'member');
        next unless ($member->{'attrib'}->{'type'} eq 'way');
        push @waylist,$member->{'attrib'}->{'ref'};
    }
}

# -----------------------------------------
# Download ways, lats and longs from server

@polylines=();
$maxlon=-180; $minlon=180;
$maxlat= -90; $minlat= 90;
$s=0;
foreach $wayid (@waylist) {
    print "Reading way $s of $#waylist\n";
    $way=get("http://www.openstreetmap.org/api/0.6/way/$wayid/full");
    $XMLFILE=new IO::Scalar \$way;
    $xml=parsefile($XMLFILE);
    $first=@{$xml}[0];

    foreach $t (@{$first->{'content'}}) {
        if ($t->{'name'} eq 'node') {
            $id=$t->{'attrib'}->{'id'};
            $lat{$id}=$t->{'attrib'}->{'lat'};
            $lon{$id}=$t->{'attrib'}->{'lon'};
            if ($lat{$id}>$maxlat) { $maxlat=$lat{$id}; }
            if ($lon{$id}>$maxlon) { $maxlon=$lon{$id}; }
            if ($lat{$id}<$minlat) { $minlat=$lat{$id}; }
            if ($lon{$id}<$minlon) { $minlon=$lon{$id}; }
        } elsif ($t->{'name'} eq 'way') {
            $polyline="<trkseg>\n";
            foreach $nd (@{$t->{'content'}}) {
                next unless ($nd->{'name'} eq 'nd');
                $id=$nd->{'attrib'}->{'ref'};
                $polyline.="<trkpt lat='$lat{$id}' lon='$lon{$id}' />\n";
            }
            $polyline.="</trkseg>\n";
            push @polylines,$polyline;
        }
    }
    close $XMLFILE;
    $s++;
}

# --------------
# Write GPX file

print "Writing GPX file\n";
open (OUTFILE, ">$fn") or die "Can't open $fn for writing: $!\n";
print OUTFILE <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<gpx
 version="1.0"
creator="GPSBabel - http://www.gpsbabel.org"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.topografix.com/GPX/1/0"
xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
<bounds minlat="$minlat" minlon="$minlon" maxlat="$maxlat" maxlon="$maxlon"/>
<trk>
@polylines
</trk>
</gpx>
EOF

close OUTFILE;
