#!/usr/bin/perl -w
# **********************************************************************
# * Name             : maut.pl                                         *
# * Erstellt am      : 21.01.2005 Thomas Weise                         *
# * Letzte Aenderung : 21.01.2005 Thomas Weise                         *
# * Beschreibung     : Maut  (zum testen von amsoft_tk_maut.pm)        *
# **********************************************************************

BEGIN
{
  use amsoft_pfadset;
  perlmodul_pfad_set();
}

use strict;

use Tk;
use Tk::Menu;
use Tk::ErrorDialog;
use Tk::DialogBox;
#use Tk::Photo;
use Tk::Scrollbar;
use Tk::Message;
use Tk::LabFrame;
use Tk::Text;

#use amsoft_db;
#use amsoft_conf;
#use amsoft_tk_dialog;
#use amsoft_tk_gifconf;
#use amsoft_tk_amhead;
#use amsoft_tk_osutil;
#use amsoft_tk_bututil;

use amsoft_tk_maut2;
#use amsoft_tk_ammand;

eval { require DBD::ODBC; };

use vars qw(
  $aufruf
  $programmname
  $programmpfad
  $confdatei
  $confdateicall
  $config
  $mw
  $max_breite
  $max_hoehe
  $mw_breite
  $mw_hoehe
  $geommw

  $menu
  $menu_datei
  $menu_pmerf
  $menu_qrk
  $menu_hilfe

  $dbh

  $amhead

  $firma

  $obj
);

$programmname = "Maut";
$programmpfad = perlmodul_aktpfad();

#$confdateicall = $ARGV[0];
#if (!defined($confdateicall) or length($confdateicall) == 0)
#{
#  $confdateicall = "chrv.cfg";
#}
#
#$confdatei = $programmpfad . $confdateicall;

$mw = MainWindow->new();

#$mw->option("readfile", $programmpfad."options.opt");

#$config = amsoft_conf->new($confdatei);
#
#my $firma = "01";
#my $ammand_obj = amsoft_tk_ammand->new(-pwidget => $mw,
#                                       -config  => $config);
#$ammand_obj->eingabe(-standardfirma => "01");  # beim testen rausgenommen
#$ammand_obj->warten();
#($firma, $dbh) = $ammand_obj->get();

#zum testen
#$firma = "01";
#mysql-lokal:::
#$dbh=DBI->connect("DBI:mysql:host=localhost;database=maxx", "", "",{PrintError=>0, RaiseError=>1});

my $obj;

erfassen();
$mw->iconify();

MainLoop;

sub erfassen
{
  if (!defined($obj->{'-exists'}))
  {
    $obj = amsoft_tk_maut2->new(-pwidget   => $mw,
			#-config    => \$config,
			#													 -dbh       => $dbh,
			#	 												 -firma     => $firma,
			#	 												 -bediener  => "TW",
			#	 												 -steuer    => 1,
				 												 );

    $obj->erfassen();
  }
  else
  {
    $obj->{'-topwidget'}->raise();
    $obj->{'-topwidget'}->deiconify();
  }
}
