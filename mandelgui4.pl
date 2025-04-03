#! /usr/bin/perl -w
#

## Code is GPLed, original script by Marko Riedel,
## markoriedelde@gmail.com

use strict;
use warnings;
use Tk;

use Math::BigFloat;

require Tk::ErrorDialog;

my $convertbin = '/usr/bin/convert';

my ($imgwidth, $imgheight) = (250, 250);

my $mainwin = tkinit(-title => 'Mandelbrot Explorer');
$mainwin->minsize(200, 200);

my $mandelcanvas = $mainwin->Canvas(
    -width => $imgwidth, -height => $imgheight);

my @defaults = 
    map { Math::BigFloat->new($_); }
    (-1.5,0.5,-1,1);

my $rmin = Math::BigFloat->new(shift || $defaults[0]);
my $rmax = Math::BigFloat->new(shift || $defaults[1]);
my $imin = Math::BigFloat->new(shift || $defaults[2]);
my $imax = Math::BigFloat->new(shift || $defaults[3]);

die "empty real range" if $rmin->bge($rmax);
die "empty imag range" if $imin->bge($imax);

my @photodata = (undef);
my $quadIndex = -1;

my $precision = 64;

my $precMenuItems = [
    [Button => '64 bits', -state => 'disabled',
     -command => sub {
	setPrecision(64);
     }],
    [Button => '128 bits', -state => 'normal',
     -command => sub {
	setPrecision(128);
     }],
    [Button => '256 bits',  -state => 'normal',
     -command => sub {
	setPrecision(256);
     }],
    [Button => '512 bits',  -state => 'normal', 
     -command => sub {
	setPrecision(512);
     }],
    [Button => '1024 bits',  -state => 'normal',
     -command => sub {
	setPrecision(1024);
     }]
    ];

my $precbtn = 
    $mainwin->Menubutton(-menuitems => $precMenuItems,
			 -tearoff => 0, -relief => 'raised',
			 -text => 'Precision');


sub setPrecision { 
    my $np = shift || 64; $precision = $np; 

    $photodata[$quadIndex] = undef;
    reload('no');

    for(my $pidx=0; $pidx < 5; $pidx++){
	my $precMenu = $precbtn->menu;
	
	if($precMenu->entrycget($pidx, '-label') 
	   =~ /^$precision/){
	    $precMenu->entryconfigure
		($pidx,-state => 'disabled');
	}
	else{
	    $precMenu->entryconfigure
		($pidx,-state => 'normal');
	}	    
    }
}

my @history = ();

sub setQuad {
    my $all = scalar(@history);
    
    $quadIndex++;
    
    if($quadIndex == $all){    
	push @history, [ @_ ];
	push @photodata, undef;
    }
    else{
	$history[$quadIndex] = [ @_ ];
	$photodata[$quadIndex] = undef;
    }
}

sub getQuad {
    return @{ $history[$quadIndex] };
}

setQuad($rmin, $rmax, $imin, $imax);

my $dist = 5;

sub specstr {
    my ($rsmin, $rsmax, $ismin, $ismax) =
	($rmin->bstr(), $rmax->bstr(),
	 $imin->bstr(), $imax->bstr());
    my ($rlmin, $rlmax, $ilmin, $ilmax) =
	map length, ($rsmin, $rsmax, $ismin, $ismax);
    
    my ($prefix, $preflen);
    
    if("$rsmin|$rsmax" =~ /(\S+).+\|\1.+/){
	$prefix = $1; $preflen = length($prefix);
	$rlmin = ($preflen+$dist <= $rlmin ?
		  $preflen+$dist : $rlmin);
	$rlmax = ($preflen+$dist <= $rlmax ?
		  $preflen+$dist : $rlmax);

	$rsmin = substr $rsmin, 0, $rlmin;
	$rsmax = substr $rsmax, 0, $rlmax;	
    }

    
    if("$ismin|$ismax" =~ /(\S+).+\|\1.+/){
	$prefix = $1; $preflen = length($prefix);
	$ilmin = ($preflen+$dist <= $ilmin ?
		  $preflen+$dist : $ilmin);
	$ilmax = ($preflen+$dist <= $ilmax ?
		  $preflen+$dist : $ilmax);

	$ismin = substr $ismin, 0, $ilmin;
	$ismax = substr $ismax, 0, $ilmax;	
    }

    return "$rsmin $rsmax $ismin $ismax";
}

sub getphotodata {
    my $spec = specstr();
    
    my $cmd =
	sprintf "./mandelcmp5 $imgwidth $imgheight "
	. "$spec $precision "
	. "| $convertbin PPM:- GIF:-";

    open IMG, '-|', $cmd;
    my $buf = my $data = '';
    $data .= $buf while read(IMG, $buf, 1<<16);
    close IMG;

    print STDERR "$spec\n";
    
    return $data;
}

my $boundary =
    $mandelcanvas->createRectangle(1,1,$imgwidth-1,$imgheight-1);

my ($mandelimage, $mandelimgid);

sub reload {
    my $isinitial = shift;

    if($isinitial eq 'no'){
	$mainwin->configure(-cursor => 'watch');
	$mainwin->update;
    }    

    if(defined($mandelimgid)){
	$mandelcanvas->delete($mandelimgid);
	$mandelimage->delete();
    }

    my $all = scalar(@history);

    if($quadIndex < $all && defined($photodata[$quadIndex])){
	$mandelimage = 
	    $mandelcanvas->Photo(-format => 'gif', 
				 -data => $photodata[$quadIndex]);
    }
    else{
	my $data = getphotodata();
	$mandelimage = 
	    $mandelcanvas->Photo(-format => 'gif', 
				 -data => $data);
	$photodata[$quadIndex] = $data;
    }
    
    $mandelimgid =
	$mandelcanvas->createImage($imgwidth/2, $imgheight/2,
				   -image => $mandelimage);

    $mandelcanvas->raise($boundary, $mandelimgid);

    if($isinitial eq 'no'){
	$mainwin->configure(-cursor => '');
	$mainwin->update;
    }
}

reload('yes');	


my ($undobtn, $redobtn);

sub clearHistory {
	splice @history, 0, $quadIndex;
	splice @photodata, 0, $quadIndex;
	$quadIndex = 0;
}    

my $resetbtn = $mainwin->Button(
    -text => 'Reset', -command => sub { 
	($rmin, $rmax, $imin, $imax) = @defaults;
	$photodata[$quadIndex] = undef;

	setQuad(@defaults);
	reload('no');

	clearHistory();

	$undobtn->configure(-state => 'disabled');
	$redobtn->configure(-state => 'disabled');
    });


$undobtn = $mainwin->Button(
    -text => 'Undo', -state => 'disabled',
    -command => sub {
	if($quadIndex > -1){
	    $quadIndex--;
	    
	    ($rmin, $rmax, $imin, $imax) = getQuad();
	    reload('no');

	    $redobtn->configure(-state => 'normal');
	}

	$undobtn->configure(-state => 'disabled')
	    if $quadIndex == 0;
    });


$redobtn = $mainwin->Button(
    -text => 'Redo', -state => 'disabled',
    -command => sub {
	my $all = scalar(@history);
	if($quadIndex < $all-1 ){
	    $quadIndex++;

	    ($rmin, $rmax, $imin, $imax) = getQuad();
	    reload('no');
	    $undobtn->configure(-state => 'normal')
	}

	$redobtn->configure(-state => 'disabled')
	    if $quadIndex == $all-1;
    });

my $savebtn = $mainwin->Button(
    -text => 'Save', -command => sub {
	my @ext = (
	    ["All Source Files", [qw/*.pl *.c/]],
	    ["Image Files", [qw/.gif .png .jpg/]],
	    ["All files", ['*']]);

	my $answer = $mainwin->getSaveFile(
	    -filetypes => \@ext, 
	    -defaultextension => '.gif');

	if(defined($answer) and length($answer)>0){
	    $mandelimage->write($answer, -format => 'gif');
	}
    });

my $expandbtn = $mainwin->Button(
    -text => 'Expand', -command => sub {
	my ($cwidth, $cheight) =
	    ($mainwin->width, 
	     $mainwin->height-$resetbtn->height);
	my $dim = ($cwidth < $cheight ? $cwidth : $cheight);
	return if $dim < 200;

	$photodata[$quadIndex] = undef;
	
	$imgwidth = $dim; $imgheight = $dim;
	reload('no');

	$mandelcanvas->configure(
	    -width => $dim, -height => $dim);
	$mandelcanvas->delete($boundary);
	$boundary =
	    $mandelcanvas->createRectangle
	    (1,1,$imgwidth-1,$imgheight-1);

	clearHistory();

	$undobtn->configure(-state => 'disabled');
	$redobtn->configure(-state => 'disabled')
    });

my $quitbtn = $mainwin->Button(
    -text => 'Quit',
    -command => sub { $mainwin->destroy(); });

$mandelcanvas->pack(-side => 'bottom');

$quitbtn->pack(-side => 'left', -anchor => 'nw');
$savebtn->pack(-side => 'left', -anchor => 'nw');

$precbtn->pack(-side => 'left', -anchor => 'nw');

$resetbtn->pack(-side => 'left', -anchor => 'nw');
$redobtn->pack(-side => 'left', -anchor => 'nw');
$undobtn->pack(-side => 'left', -anchor => 'nw');
$expandbtn->pack(-side => 'left', -anchor => 'nw');

my ($downX, $downY) = (0, 0);
my ($upX, $upY) = (0, 0);
my ($x1, $y1, $x2, $y2);

my @selCirc;

sub compRect {
    my ($swidth, $sheight) =
	($upX-$downX, $upY-$downY);

    my $dim =
	sqrt($swidth*$swidth+$sheight*$sheight);

    $x1 = $downX-$dim;
    $x2 = $downX+$dim;

    $y1 = $downY-$dim;
    $y2 = $downY+$dim;
}

my $mouseDidMove = 'no';

sub mouseDown {
    my $window = shift;
    my $event = $window->XEvent;

    ($downX, $downY) = ($event->x, $event->y);
    $mouseDidMove = 'no';
}


sub mouseMoved {
    my $window = shift;
    my $event = $window->XEvent;
    
    ($upX, $upY) = ($event->x, $event->y);    

    my ($hmin, $hmax) = ($downX, $upX);
    my ($vmin, $vmax) = ($downY, $upY);

    ($hmin, $hmax) = ($upX, $downX) if $hmin > $hmax;
    ($vmin, $vmax) = ($upY, $downY) if $vmin > $vmax;

    compRect();

    foreach(my $circ=0; $circ<4; $circ++){
	$mandelcanvas->delete($selCirc[$circ]) 
	    if defined($selCirc[$circ]);
	my $selCol = ($circ % 2 > 0 ? 'black' : 'white');
	$selCirc[$circ] = 
	    $mandelcanvas->createOval($x1-$circ, $y1-$circ, 
				      $x2+$circ, $y2+$circ,
				      -outline =>  $selCol);
    }

    $mouseDidMove = 'yes';
}


sub mouseUp {
    my $window = shift;
    my $event = $window->XEvent;

    return if $mouseDidMove eq 'no';

    ($upX, $upY) = ($event->x, $event->y);    

    for(my $circ=0; $circ<4; $circ++){
	$mandelcanvas->delete($selCirc[$circ]) 
	    if defined($selCirc[$circ]);
    }

    compRect();

    my ($nrmin, $nrmax, $nimin, $nimax);
    
    my $zranger = Math::BigFloat->new($rmax);
    $zranger->bsub($rmin);

    $nrmin = $zranger->copy(); 
    $nrmin->bmul(Math::BigFloat->new($x1/$imgwidth));
    $nrmin->badd($rmin);

    $nrmax = $zranger->copy(); 
    $nrmax->bmul(Math::BigFloat->new($x2/$imgwidth));
    $nrmax->badd($rmin);

    
    my $zrangei = Math::BigFloat->new($imax);
    $zrangei->bsub($imin);

    $nimin = $zrangei->copy(); 
    $nimin->bmul(Math::BigFloat->new(1-$y2/$imgheight));
    $nimin->badd($imin);

    $nimax = $zrangei->copy(); 
    $nimax->bmul(Math::BigFloat->new(1-$y1/$imgheight));
    $nimax->badd($imin);
    
    setQuad($nrmin, $nrmax, $nimin, $nimax);
    ($rmin, $rmax, $imin, $imax) = getQuad();
    reload('no');
    
    splice @history, $quadIndex+1;
    splice @photodata, $quadIndex+1;    
    
    $undobtn->configure(-state => 'normal');
    $redobtn->configure(-state => 'disabled');    
}


$mandelcanvas->Tk::bind('<ButtonPress-1>', \&mouseDown);
$mandelcanvas->Tk::bind('<ButtonRelease-1>', \&mouseUp);
$mandelcanvas->Tk::bind('<B1-Motion>', \&mouseMoved);			


$mainwin->MainLoop;


		    
