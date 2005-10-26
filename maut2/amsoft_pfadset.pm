# *******************************************************************
# * Name             : amsoft_pfadset.pm                            *
# * Erstellt am      : 04.06.2003 Peter Harrendorf                  *
# * Letzte Aenderung : 04.06.2003 Peter Harrendorf                  *
# * Beschreibung     : Modul zum Setzen von Modulpfaden aus         *
# *                    Datei .perlpfadconf                          *
# *******************************************************************

# Aufruf in jedem relevanten perl-Script
# BEGIN
# {
#   use amsoft_pfadset;
#   $programmpfad = perlmodul_pfad_set($such_tiefe, $pfad);
# }
# 
# Funktionen : perlmodul_pfad_set()
#              perlmodul_aktpfad()
#              perlmodul_aktname()
#
# Die Funktion perlmodul_aktpfad() liefert den absoluten Pfad des
# Perlscripts
#
# Die Funktion perlmodul_pfad_set() hat zwei Funktionen
# 1.Sie ermittelt den absoluten Pfad des Perlscripts und gibt diesen
#   zurueck.
# 2.Sie sucht in diesem Pfad nach einer Datei .perlpfadconf oder 
#   _perlpfadcomf und erweitert den Suchpfad des Perl-Interpreters um
#   die darin stehenden Eintraege
#   Wird im Pfad des Scripts diese Datei nicht gefunden, sucht sie in
#   den darueberliegenden Verzeichnissen bis eine Datei .perlpfadconf
#   gefunden wird.
#   Wird keine Datei gefunden, wird der Suchpfad um /max-x/perl/stmodul
#   erweitert.
#
#   Parameter : $such_tiefe = 1 : es wird nur im aktuellen Pfad gesucht
#               $pfad           : festgelegter Suchpfad 


require 5.000;
require Exporter;

use strict;

package amsoft_pfadset;

use FindBin qw($Bin $Script);
use File::Find;

use vars qw(
  @ISA
  @EXPORT
  $Bin
);

@ISA    = qw(Exporter);
@EXPORT = qw(perlmodul_pfad_set 
             perlmodul_aktpfad
	     perlmodul_aktname);

sub perlmodul_aktpfad
{
  my $prog_pfad      = "";

  $prog_pfad = $Bin;
  if(!defined($prog_pfad) or 
    length($prog_pfad) == 0 or 
    $prog_pfad eq ".")
  {
    $prog_pfad = ".";
  }

  $prog_pfad = $prog_pfad . "/";

  return $prog_pfad;
}

sub perlmodul_aktname
{
  my $script_name    = "";

  $script_name = $Script;

  return $script_name;
}

sub perlmodul_pfad_set
{
  my $such_tiefe     = shift;
  my $perl_conf_pfad = shift;
  my $prog_pfad      = "";
  my $such_pfad      = "";
  my $perl_conf      = "";
  my $open_conf      = "0";
  my $zeile          = "";
  my $stpfad         = 0;
  my @pfar           = ();
  my @pfars          = ();
  my $i              = 0;
  my $j              = 0;
  my $l              = 0;
  my $c_fd           = "";
  my $suche          = 0;
  my $laufwerk       = "";

  $prog_pfad = $Bin;
  if(!defined($prog_pfad) or 
    length($prog_pfad) == 0 or 
    $prog_pfad eq ".")
  {
    $prog_pfad = ".";
  }

  $prog_pfad = $prog_pfad . "/";
 
  $c_fd = ".perlpfadconf";
  suche_nochmal:

  if (defined($perl_conf_pfad) and length($perl_conf_pfad) > 0)
  {
    $perl_conf = $perl_conf_pfad . $c_fd;
  }
  else
  {
    if (defined($such_tiefe) and $such_tiefe == 1)
    {
      $perl_conf = $prog_pfad . $c_fd;
    }
    else
    {
      $such_pfad = $prog_pfad;

      @pfar = split(/\//, $such_pfad);

      $l = $#pfar;

      for ($i=0;$i<=$l;$i++)
      {
	$pfar[$i] = $pfar[$i] . "/";
      }

      for ($j=0;$j<=$l;$j++)
      {
	$pfars[$j] = "";
	for ($i=0;$i<=$#pfar;$i++)
	{
	  $pfars[$j] = $pfars[$j] . $pfar[$i];
	}
	pop @pfar;
      }

      for ($j=0;$j<=$#pfars;$j++)
      {
	$perl_conf = $pfars[$j] . $c_fd;

	$open_conf = "0";
	open PERLCONF, "<$perl_conf"
	  or $open_conf = "1";

	if ($open_conf eq "0")
	{
	  close PERLCONF;
	  last;
	}
      }	
    }
  }

  $open_conf = "0";
  open PERLCONF, "<$perl_conf"
    or $open_conf = "1";
  
  if ($suche == 0 and $open_conf == 1)
  {
    $c_fd  = "_perlpfadconf";
    $suche = 1;
    goto suche_nochmal;
  }

  if ($open_conf eq "0")
  {
    while(<PERLCONF>)
    {
      chomp;
      $zeile = $_;
      next if (/^#.*/);
      if ($stpfad == 0)
      {
        if ($zeile =~ /\/max-x\/perl\/stmodul/)
	{
	  $stpfad = 1;
	  $zeile =~ /^([A-Z]{1}:)/;
	  $laufwerk = $1;
	}
      }
      chop($zeile);
      if (-d $zeile)
      {
	unshift(@INC,$zeile);
      }
    }

    close PERLCONF;
  }

  if ($open_conf eq "1" or $stpfad == 0)
  {
    $zeile = "/max-x/perl/stmodul/";
    if (-d $zeile)
    {
      unshift(@INC,$zeile);
      $stpfad = 1;
    }
  }

  if ($stpfad == 1)
  {
    my $direntrie = "";
    my $dir       = "";
    my $diropen   = "";

    if (defined($laufwerk) and length($laufwerk) > 0)
    {
      $diropen = $laufwerk . "/max-x/perl/stmodul/";
    }
    else
    {
      $diropen = "/max-x/perl/stmodul/";
    }

    File::Find::find(\&rd, $diropen);
    #opendir(DIR, $diropen);
    #my @entries = readdir(DIR);

    #foreach $direntrie (@entries)
    #{
    #  next if ($direntrie eq ".");
    #  next if ($direntrie eq "..");
    #  $dir = $diropen . $direntrie . "/";
    #  if (-d $dir)
    #  {
#	unshift(@INC,$dir);
    #     }
    #}

    #closedir(DIR);
  }

  return $prog_pfad;
}

# Verzeichnisse finden --------------------------------------------------------
sub rd
{
  my $file = $_;

  my $el;
  my $gef = 0;

  my $dir = $File::Find::dir;
  if (-d $dir)
  {
    $gef = 0;
    foreach $el (@INC)
    {
      if ($dir eq $el)
      {
	$gef = 1;
	last;
      }
    } 
   
    if ($gef == 0)
    { 
      unshift(@INC, $dir);
    }
  }
}

1;
