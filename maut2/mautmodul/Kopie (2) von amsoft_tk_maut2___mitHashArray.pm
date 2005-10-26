# *******************************************************************
# * Name             : amsoft_tk_maut.pm                            *
# * Erstellt am      : 21.01.2005 Thomas Weise                      *
# * Letzte Aenderung : 21.01.2005 Thomas Weise                      *
# * Beschreibung     : Maut                                         *
# *******************************************************************

require 5.000;
use strict;

package amsoft_tk_maut2;

use Tk;
use Tk::DialogBox;
use Tk::Menu;
use Tk::ErrorDialog;
use Tk::ToolBar;
use Tk::Tree;
use Tk::ItemStyle;
use Tk::Autoscroll;
use Tk::DateEntry;
use Tk::BrowseEntry;
use Tk::TextUndo;
use Tk::Balloon;
use Tk::HList;
use Tk::Scrollbar;

sub new
{
  my $classname = shift;
  my %params = @_;
  my $self   = {};

  			# Name der Datei mit der Mauttabelle
  my $datei = "daten/maut_A4-9-14.txt";
  #my $datei = "daten/maut_alles.txt";

  $self->{'-pwidget'}   = $params{-pwidget};
  $self->{'-font1'}     = 'Helvetica -16 bold';
  $self->{'-font2'}     = 'Helvetica -14 bold';
	$self->{'-datei'}     = $datei;

  			# Datei in ein Array von Zeilen einlesen
  open(AAA, $datei);
  my @zeilen = <AAA>;
  close(AAA);
  			# diese Zeilen in ein Array von Hashes umwandeln
  my @data;
  for (my $i=0; $i<=$#zeilen; $i++)
  {
    my @zeile=split(";",$zeilen[$i]);

    $data[$i] = {};
    $data[$i]->{'-bab'}    = $zeile[0];
    $data[$i]->{'-k_nr1'}  = $zeile[1];
    $data[$i]->{'-k_typ1'} = $zeile[2];
    $data[$i]->{'-von'}    = $zeile[3];
    $data[$i]->{'-k_nr2'}  = $zeile[4];
    $data[$i]->{'-k_typ2'} = $zeile[5];
    $data[$i]->{'-nach'}   = $zeile[6];
    $data[$i]->{'-km'}     = $zeile[7];
    $data[$i]->{'-status'} = $zeile[8];
    $data[$i]->{'-lfdnr'}  = $i;
  }
  			# eine Referenz aus dieses Hash-Array erzeugen und übergeben
  my $daten = \@data;
  $self->{'-daten'} = $daten;

#  print "$data[0]->{'-bab'} \n";
#  print "$data[0]->{'-k_nr1'} \n";
#  print "$data[0]->{'-k_typ1'} \n";
#  print "$data[0]->{'-von'} \n";
#  print "$data[0]->{'-k_nr2'} \n";
#  print "$data[0]->{'-k_typ2'} \n";
#  print "$data[0]->{'-nach'} \n";
#  print "$data[0]->{'-km'} \n";
#  print "$data[0]->{'-status'} \n";
#  print "$data[0]->{'-lfdnr'} \n";

  bless ($self, $classname);
  return $self;
}

# Erfassen ---------------------------------------------------------------------
sub erfassen
{
  my $self = shift;

  my $mw;
  my $top;

  my $menu;
  my $frame;
  my 		$fra_butt;
  my 				$frametb;
  my 		$fra_oben;
  my 				$fra_oben_li;
  my 				$fra_oben_re;
  my 		$fra_unten;

  my $amhead_obj;
  my $helpball;
  my $helpzeile;

  $mw        = $self->{'-pwidget'};

  			# Toplevel
  $top = $mw->Toplevel();
  #$top->withdraw();
  #amsoft_tk_osutil->maximize(-widget => $top);
  #$top->raise();
  $top->withdraw();
  $top->raise();
  $top->deiconify();
  $top->minsize(790,550);
  $top->maxsize(790,550);
  			# !!! wieder ändern !!!
  #$top->protocol('WM_DELETE_WINDOW', sub { $self->ende();});  #zum testen raus
  $top->protocol('WM_DELETE_WINDOW', sub { $mw->destroy();});
  $top->title("Maut");
  $self->{'-topwidget'}     = $top;

  ######## OBJEKTE ############
  			# Bildschirmaufteilung (helpzeile)
#  $amhead_obj = amsoft_tk_amhead->new(-pwidget => $top,
#                                     -config  => $config,
#																		  -knz     => 3);

#  $self->{'-amhead_obj'}    = $amhead_obj;
# $self->{'-wertt'}         = "";

#  $self->{'-lba_fuell'}     = 0;

  $helpball = $top->Balloon(Name => 'ball1'); #das war drin
  #$helpball = $top->Balloon(-class => 'Ball11');
  $self->{'-helpball'} = $helpball;


  ######## FRAMES ###########
  			# Menü
  $menu = $top->Menu();
  $top->configure(-menu => $menu);
  $self->{'-menu'} = $menu;
  $self->menu_datei();
  $self->menu_hilfe();

  			# Helpzeile
#  ($helpzeile) = $amhead_obj->help_zeile(-text2 => "Firma : ".$firma,
#				     												 		 -text3 => "Bediener : ".$bediener);
#  $self->{'-helpzeile'} = $helpzeile;

  			# Frame - Hauptframe
  $frame = $top->Frame(-relief => 'ridge',
	               			 -bd     => 2
	              			 )->pack(-side   => 'top',
		              						 -expand => 'yes',
		              						 -fill   => 'both');
  $self->{'-topframe'}      = $frame;

  			# Frame - Buttonframe mit Toolbar
  $fra_butt = $frame->Frame(-relief => 'ridge',
                            -bd     => 0,
                            )->pack(-side   => 'top',
                                    -anchor => 'nw',
                                    -fill   => 'x');
  $frametb = $fra_butt->ToolBar(-movable       => 1,
                                -cursorcontrol => 0,
                                -side          => 'top',
                                )->pack();
  $self->{'-fra_butt'} = $frametb;
  $self->fra_butt();
  #$self->{'-fra_butt'}->packForget();    # auskommentieren um Buttonframe anzuzeigen

  			# Frame - oben (für links und rechts)
  $fra_oben = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $self->{'-fra_oben'} = $fra_oben;

  			# Frame - oben links
  $fra_oben_li = $fra_oben->Frame(-relief => 'ridge',
                             			-bd     => 2,
		            						 			)->pack(-side   => 'left',
																		 			-anchor => 'nw',
				    												 			-expand => 0,
				 														 			-fill   => 'both');
  $self->{'-fra_oben_li'} = $fra_oben_li;
  $self->fra_oben_li();

  			# Frame - oben rechts
  $fra_oben_re = $fra_oben->Frame(-relief => 'ridge',
                             			-bd     => 2,
		            									)->pack(-side   => 'left',
			  	    														-anchor => 'nw',
				    															-expand => 0,
				    															-fill   => 'both');
  $self->{'-fra_oben_re'} = $fra_oben_re;
  $self->fra_oben_re();

  			# Frame - unten
  $fra_unten = $frame->Frame(-relief => 'ridge',
          								-bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $self->{'-fra_unten'} = $fra_unten;
  $self->fra_unten();

#	$amhead_obj->help_show(-text => "Nennen Sie Produktnummer oder Suchbegriff mit F5  /  F4=Ende  /  F1=Hilfe");

}

# Buttonleiste -----------------------------------------------------------------
sub fra_butt
{
  my $self = shift;

  my $fra_butt = $self->{'-fra_butt'};

  my $button_01;
  my $button_02;

  $button_01 = $fra_butt->ToolButton(-text      => 'Listboxen füllen',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->btn_01();},
                                   -width     => 12,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $button_02 = $fra_butt->ToolButton(-text      => 'get_strecke',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->btn_02();},
                                   -width     => 12,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1);

  $self->{'-button_01'} = $button_01;
  $self->{'-button_02'} = $button_02;
  $self->{'-helpball'}->attach($button_01, -balloonmsg => "guck_01");
  $self->{'-helpball'}->attach($button_02, -balloonmsg => "guck_02");

}

# Menüleiste Datei -------------------------------------------------------------
sub menu_datei
{
  my $self = shift;

  my $menu = $self->{'-menu'};
  my $menu_datei;
  my $menu_datei_beenden;

  $menu_datei = $menu->cascade(-label     => "Datei",
                               -underline => 0,
		               						 -tearoff   => 0);

  $menu_datei_beenden = $menu_datei->command(-label     => "Beenden",
                                             -underline => 0,
		                             						 -command   => sub { $self->ende();});

  $self->{'-menu_beenden'} = $menu_datei_beenden;
}

# Menüleiste Hilfe -------------------------------------------------------------
sub menu_hilfe
{
  my $self = shift;

  my $menu = $self->{'-menu'};
  my $menu_hilfe;

  $menu_hilfe = $menu->cascade(-label     => "Hilfe",
                               -underline => 0,
		               						 -tearoff   => 0);
}

# Frame oben links -------------------------------------------------------------
sub fra_oben_li
{
  my $self = shift;

  my $frame = $self->{'-fra_oben_li'};
  my 	$fra_oben_li_1;
  my 	$fra_oben_li_2;
  my 	$fra_oben_li_3;
  my $lb;
  my $lbl_oben_li_3;
  my $lbhbg = "SteelBlue1";
  my $font1 = $self->{'-font1'};
  my $font2 = $self->{'-font2'};

  			# FRAME nur für Label
  $fra_oben_li_1 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');

  $fra_oben_li_1->Label(-text   => "Startpunkt aussuchen",
		    					 	 -width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 's',
		    					 	 -font   => $font1,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

  			# FRAME für Listbox
  $fra_oben_li_2 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $lb = $fra_oben_li_2->Scrolled("HList",
                          -scrollbars         => 'e',
			  									#-command            => sub { $self->lb_spez_auswahl();},
			  									-browsecmd          => sub { $self->lb_von_browse();},
                          -selectmode         => 'browse',
                          -selectbackground   => 'SlateBlue2',
                          -selectforeground   => 'white',
			  									-selectborderwidth  => 1,
                          -background         => 'white',
			  									-highlightthickness => 0,
			  									-columns            => 2,
			  									-header             => 1,
			  									-itemtype           => 'text',
			  									#-font               => $self->{'-listfont'},
			  									-takefocus          => 1
			  									)->pack(-expand => 1,
			  													-fill => 'both',
			  													-side => "left",
			  													-anchor => "nw");

  $lb->bind('<MouseWheel>' => [sub { $_[0]->yview('scroll', -($_[1] / 120) * 1, 'units')},  Ev('D')]);
  Tk::Autoscroll::Init($lb);

  $lb->columnWidth(0, -char => 12);
  $lb->columnWidth(1, -char => 30);

  $lb->headerCreate(0, -text => "Autobahn-Nr", -headerbackground => $lbhbg);
  $lb->headerCreate(1, -text => "Autobahn-Auffahrt", -headerbackground => $lbhbg);

  $self->{'-lb_von'} = $lb;
  $frame  = $self->{'-fra_oben_li'};

  			# FRAME für Anzeige des vom Benutzer ausgesuchten Startpunktes
  $fra_oben_li_3 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');

  $fra_oben_li_3->Label(-text   => "Startpunkt:   ",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 -font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

  $lbl_oben_li_3 = $fra_oben_li_3->Label(-text   => "Bitte einen Startpunkt auswählen",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 #-font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

	$self->{'-lbl_oben_li_3'} = $lbl_oben_li_3;
}

# Frame oben rechts ------------------------------------------------------------
sub fra_oben_re
{
  my $self = shift;

  my $frame;
  my $fra_oben_re_1;
  my $fra_oben_re_2;
  my $fra_oben_re_3;
  my $lb;
  my $lbl_oben_re_3;
  my $lbhbg = "SteelBlue1";
  my $font1 = $self->{'-font1'};
  my $font2 = $self->{'-font2'};

  $frame = $self->{'-fra_oben_re'};

  			# FRAME nur für Label
  $fra_oben_re_1 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');

  $fra_oben_re_1->Label(-text   => "Zielpunkt aussuchen",
		    					 	 -width  => 38,
		    					 	 #-justify => 'center',
		    					 	 -anchor => 's',
		    					 	 -font   => $font1,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

				# FRAME für Listbox
	$fra_oben_re_2 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $lb = $fra_oben_re_2->Scrolled("HList",
                          -scrollbars         => 'e',
			  									#-command            => sub { $self->lb_spez_auswahl();},
			  									-browsecmd          => sub { $self->lb_nach_browse();},
                          -selectmode         => 'browse',
                          -selectbackground   => 'SlateBlue2',
                          -selectforeground   => 'white',
			  									-selectborderwidth  => 1,
                          -background         => 'white',
			  									-highlightthickness => 0,
			  									-columns            => 2,
			  									-header             => 1,
			  									-itemtype           => 'text',
			  									#-font               => $self->{'-listfont'},
			  									-takefocus          => 1
			  									)->pack(-expand => 1,
			  													-fill => 'both',
			  													-side => "left",
			  													-anchor => "nw");

  $lb->bind('<MouseWheel>' => [sub { $_[0]->yview('scroll', -($_[1] / 120) * 1, 'units')},  Ev('D')]);
  Tk::Autoscroll::Init($lb);

  #$self->{'-e_crnr'}->focus();
  #$self->helbzeile();

  $lb->columnWidth(0, -char => 12);
  $lb->columnWidth(1, -char => 30);

  $lb->headerCreate(0, -text => "Autobahn Abfahrt", -headerbackground => $lbhbg);
  $lb->headerCreate(1, -text => "Autobahn Nummer", -headerbackground => $lbhbg);

  $self->{'-lb_nach'} = $lb;
  $frame  = $self->{'-fra_oben_re'};

  			# FRAME für Anzeige des vom Benutzer ausgesuchten Startpunktes
  $fra_oben_re_3 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');

  $fra_oben_re_3->Label(-text   => "Zielpunkt:   ",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 -font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

  $lbl_oben_re_3 = $fra_oben_re_3->Label(-text   => "bitte einen Zielpunkt auswählen",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 #-font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

	$self->{'-lbl_oben_re_3'} = $lbl_oben_re_3;
}

# Frame unten ------------------------------------------------------------------
sub fra_unten
{
	my $self = shift;

	my $frame = $self->{'-fra_unten'};
  my $fra_unten_1;

  my $font1 = $self->{'-font1'};
  my $font2 = $self->{'-font2'};
  my $lbl_unten_1;

  			# FRAME für Ausgabe der Kilometer
  $fra_unten_1 = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');


  $fra_unten_1->Label(-text   => "Gesamtkilometer:   ",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 -font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

  $lbl_unten_1 = $fra_unten_1->Label(-text   => "bitte einen Start- und Zielpunkt auswählen",
		    					 	 #-width  => 38,
		    					 	 -justify => 'center',
		    					 	 -anchor => 'w',
		    					 	 #-font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

	$self->{'-lbl_unten_1'} = $lbl_unten_1;
}

# Buttonfunktion 01 ------------------------------------------------------------
sub btn_01
{
	my $self = shift;

	$self->lb_von_fuellen();
	$self->lb_nach_fuellen();
}

# Buttonfunktion 02 ------------------------------------------------------------
sub btn_02
{
	my $self = shift;

	#my $von_auswahl  = $self->{'-von_auswahl'};
	#my $nach_auswahl = $self->{'-nach_auswahl'};

  $self->hashdesd();
}

# TEST #####
sub hashdesd
{
  my $self = shift;
  my $daten = $self->{'-daten'};

  print "################## in hashdesd: ########################\n";
  print "###$$daten[1]{'-bab'}################################################## \n";
  print "###$$daten[1]{'-k_nr1'}################################################# \n";
  print "###$$daten[1]{'-k_typ1'}################################################# \n";
  print "###$$daten[1]{'-von'}### \n";
  print "###$$daten[1]{'-k_nr2'}################################################# \n";
  print "###$$daten[1]{'-k_typ2'}################################################# \n";
  print "###$$daten[1]{'-nach'}### \n";
  print "###$$daten[1]{'-km'}################################################# \n";
  print "###$$daten[1]{'-status'}################################################### \n";
  print "###$$daten[1]{'-lfdnr'}#################################################### \n";
}

# Listbox oben links füllen (von) ----------------------------------------------
sub lb_von_fuellen
{
	my $self = shift;

	my $lb    = $self->{'-lb_von'};
	my $datei = $self->{'-datei'};

	my $lb_data;
	my $count = 0;

  			# Datei auslesen nach @zeilen
	open(AAA, $datei);
	my @zeilen = <AAA>;
	close(AAA);

	for (my $i=0; $i<=$#zeilen; $i++)
	{
  	my @zeile=split(";",$zeilen[$i]);

    my $bab    = $zeile[0];
    #my $k_nr1  = $zeile[1];
    #my $k_typ1 = $zeile[2];
    my $von    = $zeile[3];
    #my $k_nr2  = $zeile[4];
    #my $k_typ2 = $zeile[5];
    #my $nach   = $zeile[6];
    #my $km     = $zeile[7];
    #my $status = $zeile[8];

    $lb_data = {};
    $lb_data->{'-count'}  = $count;
    $lb_data->{'-bab'}    = $bab;
    #$lb_data->{'-k_nr1'}  = $k_nr1;
    #$lb_data->{'-k_typ1'} = $k_typ1;
    $lb_data->{'-von'}    = $von;
    #$lb_data->{'-k_nr2'}  = $k_nr2;
    #$lb_data->{'-k_typ2'} = $k_typ2;
    #$lb_data->{'-nach'}   = $nach;
    #$lb_data->{'-km'}     = $km;
    #$lb_data->{'-status'} = $status;

    $lb->add($count, -data => $lb_data);
    $lb->itemCreate($count, 0, -text => $bab);
    $lb->itemCreate($count, 1, -text => $von);

    $count++;
	}
}

# Listbox oben links browse (von) ----------------------------------------------
sub lb_von_browse
{
  my $self   = shift;
  my %params = @_;

	$self->set_von_auswahl();
  #print "in lb_von_browse...\n";
}

# setze Auswahl "VON" ----------------------------------------------------------
sub set_von_auswahl
{
	my $self = shift;

  my $lb            = $self->{'-lb_von'};
  my $lbl_oben_li_3 = $self->{'-lbl_oben_li_3'};
  my @ausl = ();
  my ($bab, $von);

  my $count = 0;
  @ausl = $lb->selectionGet();
  if ($#ausl < 0)
  {
    return;
  }

  $count = $ausl[0];
  $bab = $lb->infoData($count)->{'-bab'};
  $von = $lb->infoData($count)->{'-von'};

  $lbl_oben_li_3->configure(-text => $von);
  #print "in set_von_auswahl...\n";

  $self->{'-von_auswahl'} = $von;
  return $von;
}

# setze Auswahl "NACH" ---------------------------------------------------------
sub set_nach_auswahl
{
	my $self = shift;

  my $lb            = $self->{'-lb_nach'};
  my $lbl_oben_re_3 = $self->{'-lbl_oben_re_3'};
  my @ausl = ();
  my ($bab, $nach);

  my $count = 0;
  @ausl = $lb->selectionGet();
  if ($#ausl < 0)
  {
    return;
  }

  $count = $ausl[0];
  $bab  = $lb->infoData($count)->{'-bab'};
  $nach = $lb->infoData($count)->{'-nach'};

  $lbl_oben_re_3->configure(-text => $nach);
   #print "in set_nach_auswahl:nach_auswahl=$nach\n";

  $self->{'-nach_auswahl'} = $nach;
  return $nach;
}

# Listbox oben rechts füllen (nach) --------------------------------------------
sub lb_nach_fuellen
{
	my $self = shift;

	my $lb    = $self->{'-lb_nach'};
	my $datei = $self->{'-datei'};

	my @zeilen;    # alles aus der Datei ausgelesene
	my $lb_data;
	my $count = 0;

  			# Datei auslesen nach @zeilen
	open(AAA, $datei);
	@zeilen = <AAA>;
	close(AAA);

	for (my $i=0; $i<=$#zeilen; $i++)
	{
  	my @zeile=split(";",$zeilen[$i]);

    my $bab    = $zeile[0];
    #my $k_nr1  = $zeile[1];
    #my $k_typ1 = $zeile[2];
    #my $von    = $zeile[3];
    #my $k_nr2  = $zeile[4];
    #my $k_typ2 = $zeile[5];
    my $nach   = $zeile[6];
    #my $km     = $zeile[7];
    #my $status = $zeile[8];

    $lb_data = {};
    $lb_data->{'-count'}  = $count;
    $lb_data->{'-bab'}    = $bab;
    #$lb_data->{'-k_nr1'}  = $k_nr1;
    #$lb_data->{'-k_typ1'} = $k_typ1;
    #$lb_data->{'-von'}    = $von;
    #$lb_data->{'-k_nr2'}  = $k_nr2;
    #$lb_data->{'-k_typ2'} = $k_typ2;
    $lb_data->{'-nach'}   = $nach;
    #$lb_data->{'-km'}     = $km;
    #$lb_data->{'-status'} = $status;

    $lb->add($count, -data => $lb_data);
    $lb->itemCreate($count, 0, -text => $bab);
    $lb->itemCreate($count, 1, -text => $nach);

    $count++;
	}
}

# Listbox oben rechts browse (nach) --------------------------------------------
sub lb_nach_browse
{
  my $self   = shift;
  my %params = @_;

  $self->set_nach_auswahl();
  #print "in lb_nach_browse...\n";
}

# Sucht eine Streckenverbindung vom Start- zum Zielpunkt -----------------------
sub get_strecke
{
	# Argumente: Startpunkt ($von_auswahl)
	#            Zielpunkt  ($nach_auswahl)
	# return: mal sehn...
	# Ablauf:
  			# 1.hole bab zu ausgewähltem Startpunkt
  			# 2.prüfe, ob zu dieser bab der ausgewählte Zielpunkt gehört
	my $self = shift;

	my $von_auswahl  = $_[0];
	my $nach_auswahl = $_[1];
  my $bab_start;   # Nummer der Bundesautobahn des Startpunktes
  my $bab_alt;     #
  my @bab_neu;     #
  my $nach;        # ist der Zielpunkt auf dieser bab?
  my @uebergaenge; # Array von Autobahnübergängen einer Autobahn

  #######
  			# 1.hole bab zu ausgewähltem Startpunkt
	$bab_start = $self->get_bab_von();
	print "in get_strecke: Startpunkt: $von_auswahl\n";
	print "in get_strecke: Zielpunkt : $nach_auswahl\n";
	print "in get_strecke: Start-BAB : $bab_start\n";

  			# 2.prüfe, ob zu dieser bab der ausgewählte Zielpunkt gehört
  			#   wenn nicht, dann geht in else die rekursive Suche los...
  $nach = $self->is_nach($bab_start);
  if ($nach ne 0)
  {
    print "in get_strecke: gefunden  : $nach\n";
    print "---------------------------\n";
  }
  else
  {
    print "in get_strecke: Zielpunkt liegt nicht auf der BAB:$bab_start\n";
        # also: Zielpunkt liegt nicht auf dieser Autobahn, deshalb:
        # alle Autobahnübergänge dieser Autobahn holen(wenn k_typ2 AD oder AK ist)
    $bab_alt = $bab_start;
    @uebergaenge = $self->get_k_typ2($bab_alt);
    print "in get_strecke: uebergaenge: @uebergaenge\n";
        # und die Anschluss-Autobahnen dazu ermitteln ..................
    for (my $i=0; $i<=$#uebergaenge; $i++)
    {
      my $puffer = $self->get_bab_nach($uebergaenge[$i], $bab_alt);
      print "in get_strecke: puffer-$i: $puffer\n";
      print "--------------------------\n";

      #my $puffer = $self->get_bab_nach($uebergaenge[$i], $bab_alt);
      #push(@bab_neu, $puffer);
    }


  }
}

# Beenden ----------------------------------------------------------------------
sub ende
{
  my $self    = shift;
  my %params = @_;

  my $antwort;
  my $knz = $params{-knz};
print "in ende - mach doch selbst aus!!!";
}




1;
