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
  $self->{'-pwidget'}   = $params{-pwidget};

  #my $datei = "daten/maut_A4-9-14.txt";
  my $datei = "daten/maut_alles.txt";

  $self->{'-font1'}     = 'Helvetica -16 bold';
  $self->{'-font2'}     = 'Helvetica -14 bold';
	$self->{'-datei'}     = $datei;

  ###################################################
  ### aus der Daten-Datei ein Hasharray erstellen ###
  			# Datei in ein Array von Zeilen einlesen
  open(AAA, $datei);
  my @zeilen = <AAA>;
  close(AAA);
  			# diese Zeilen in ein Array von Hashes umwandeln
  my @daten;
  for (my $i=0; $i<=$#zeilen; $i++)
  {
    my @zeile=split(";",$zeilen[$i]);

    $daten[$i] = {};
    $daten[$i]->{'-bab'}    = $zeile[0];
    $daten[$i]->{'-k_nr1'}  = $zeile[1];
    $daten[$i]->{'-k_typ1'} = $zeile[2];
    $daten[$i]->{'-von'}    = $zeile[3];
    $daten[$i]->{'-k_nr2'}  = $zeile[4];
    $daten[$i]->{'-k_typ2'} = $zeile[5];
    $daten[$i]->{'-nach'}   = $zeile[6];
    $daten[$i]->{'-km'}     = $zeile[7];
    $daten[$i]->{'-status'} = $zeile[8];
    $daten[$i]->{'-lfdnr'}  = $i;
  }
        # eine Referenz aus diesem Array erzeugen und �bergeben
  my $ref_daten = \@daten;
  $self->{'-ref_daten'} = $ref_daten;

  ##################################################
  ### ein Array der Autobahnnummern erstellen ######
  my @babnummern;
  my $puffer = "";
  			# nur Nummern einlesen, die nicht doppelt sind
  for (my $i=0; $i<=$#zeilen; $i++)
  {
    my @zeile=split(";",$zeilen[$i]);
    my $arsch = $zeile[0];
    if ($puffer ne $arsch)
    {
      push(@babnummern, $arsch);
    }
    $puffer = $zeile[0];
  }
        # eine Referenz aus diesem Array erzeugen und �bergeben
  my $ref_babnummern = \@babnummern;
  $self->{'-ref_babnummern'} = $ref_babnummern;

  #################################################
  ### ein Hash-Array f�r die (Strecken-)Pfade #####
  my @pfade;
  for (my $i=0; $i<1; $i++)
  {
    $pfade[$i] = {};
    $pfade[$i]->{'-pfadnr'} = "AAA";
    $pfade[$i]->{'-pfad1'}  = "BBB";
    $pfade[$i]->{'-pfad2'}  = "CCC";
    $pfade[$i]->{'-pfadkm'} = "DDD";
  }
        # eine Referenz aus diesem Array erzeugen und �bergeben
  my $ref_pfade = \@pfade;
  $self->{'-ref_pfade'} = $ref_pfade;

  #################################################
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
  			# !!! wieder �ndern !!!
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
  			# Men�
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

  			# Frame - oben (f�r links und rechts)
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

  $button_01 = $fra_butt->ToolButton(-text      => 'Listboxen f�llen',
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

# Men�leiste Datei -------------------------------------------------------------
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

# Men�leiste Hilfe -------------------------------------------------------------
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

  			# FRAME nur f�r Label
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

  			# FRAME f�r Listbox
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

  			# FRAME f�r Anzeige des vom Benutzer ausgesuchten Startpunktes
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

  $lbl_oben_li_3 = $fra_oben_li_3->Label(-text   => "Bitte einen Startpunkt ausw�hlen",
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

  			# FRAME nur f�r Label
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

				# FRAME f�r Listbox
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

  			# FRAME f�r Anzeige des vom Benutzer ausgesuchten Startpunktes
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

  $lbl_oben_re_3 = $fra_oben_re_3->Label(-text   => "bitte einen Zielpunkt ausw�hlen",
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

  			# FRAME f�r Ausgabe der Kilometer
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

  $lbl_unten_1 = $fra_unten_1->Label(-text   => "bitte einen Start- und Zielpunkt ausw�hlen",
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

	my $von_auswahl  = $self->{'-von_auswahl'};
	my $nach_auswahl = $self->{'-nach_auswahl'};

  $self->get_strecke($von_auswahl, $nach_auswahl);
}

# TEST #####
sub hashdesd
{
  my $self = shift;
  my $ref_daten = $self->{'-ref_daten'};

  print "################## in hashdesd: ########################\n";
  print "###$$ref_daten[1]{'-bab'}################################################## \n";
  print "###$$ref_daten[1]{'-k_nr1'}################################################# \n";
  print "###$$ref_daten[1]{'-k_typ1'}################################################# \n";
  print "###$$ref_daten[1]{'-von'}### \n";
  print "###$$ref_daten[1]{'-k_nr2'}################################################# \n";
  print "###$$ref_daten[1]{'-k_typ2'}################################################# \n";
  print "###$$ref_daten[1]{'-nach'}### \n";
  print "###$$ref_daten[1]{'-km'}################################################# \n";
  print "###$$ref_daten[1]{'-status'}################################################### \n";
  print "###$$ref_daten[1]{'-lfdnr'}#################################################### \n";
}

# Listbox oben links f�llen (von) ----------------------------------------------
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

# Listbox oben rechts f�llen (nach) --------------------------------------------
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

# Sucht eine Streckenverbindung (ruft sich rekursiv selbst wieder auf) ---------
sub get_strecke
{

	my $self = shift;
  my $such_von  = $_[0];  # Such-Startpunkt der jeweiligen BAB
  my $such_nach = $_[1];  # Such-Zielpunkt der jeweiligen BAB
	my $daten      = $self->{'-ref_daten'};      # die Mauttabelle als Referenz auf ein Hash-Array
	my $babnummern = $self->{'-ref_babnummern'}; # die BAB-Nummern als Referenz auf ein Array
	my $pfade      = $self->{'-ref_pfade'};      # f�r die zu erstellenden Such-Pfade (Referenz auf ein Hash-Array)

  my $bab_such_von;   # BAB-Nummer, auf dem sich $such_von(Such-Startpunkt) befindet
  my $bab_such_nach;  # BAB-Nummer, auf dem sich $such_nach(Such-Zielpunkt) befindet
	my @uebergaenge; # Array zum Zwischenspeichern der gefundenen BAB-�berg�nge
  my $knz_treffer = 0;     # f�r Rekursionsabbruch
  my @daten = @$daten;  # !!! die Referenz dereferenzieren !!!

  			# nur weitermachen, wenn Start-und Zielpunkt eingegeben wurde
  if (!defined $such_von || !defined $such_nach)
  {
  	print "Bitte Start- und Zielpunkt eingeben\n";
  }
  else
  {
				# hole BAB-Nummer, schreibe sie nach $bab_such_von  und  $bab_such_nach
	  for (my $i=0; $i<=$#daten; $i++)
	  {
	    my $von  = $daten[$i]->{'-von'};
	    my $nach = $daten[$i]->{'-nach'};
	    my $bab  = $daten[$i]->{'-bab'};
	    if ($von eq $such_von)
	    {
	      $bab_such_von = $bab;
	    }
	    if ($nach eq $such_nach)
	    {
	      $bab_such_nach = $bab;
	    }
	  }

	  		# pr�fe, ob:
	      # $such_nach(Zielpunkt) auf bab_such_von(BAB-Nr vom Startpunkt) liegt
	      # wenn ja:   Funktionsaufruf "irgendwas Treffer oder so..."
	  for (my $i=0; $i<=$#daten; $i++)
	  {
	    my $bab  = $daten[$i]->{'-bab'};
	    my $nach = $daten[$i]->{'-nach'};
	    my $k_typ2 = $daten[$i]->{'-k_typ2'};
	    if ($bab eq $bab_such_von && $nach eq $such_nach)
	    {
      	print "Treffer auf BAB-Nr: $bab auf $i \n";
      	$knz_treffer = 1;
        ##### hier kommt dann ein Funktionsaufruf rein
        ##### nur so geht's aus der Rekursion raus...
	    }
	  }

        # wenn noch kein Treffer gelandet wurde:
	  		# hole alle �berg�nge von dieser BAB,
	  		# zwischenspeichern nach @uebergaenge
	  if ($knz_treffer == 0)
	  {
      for (my $i=0; $i<=$#daten; $i++)
      {
        my $bab    = $daten[$i]->{'-bab'};
        my $nach   = $daten[$i]->{'-nach'};
        my $k_typ2 = $daten[$i]->{'-k_typ2'};
        if ($bab eq $bab_such_von && ($k_typ2 eq "AK  " || $k_typ2 eq "AD  "))
        {
          push(@uebergaenge, $nach);
          #print "if knz_treffer: Uebergang: $nach \n";
        }
      }

          # und f�r jeden �bergang get_strecke !!! REKURSIV !!! aufrufen
      my $abbruch = 0;
      for (my $k; $k<=$#uebergaenge; $k++)
      #for (my $k; $k<=1; $k++)
      {
        $abbruch++;
        if ($abbruch < 2)
        {
        	print "hi in der REKURSION-Nr: $abbruch\n";
        	print "bab-------------------: $bab_such_von\n";
        	print "uebergang-------------: $uebergaenge[$k]\n";
        	print "such_nach-------------: $such_nach\n";
        	$self->get_strecke($uebergaenge[$k], $such_nach);
        }
      }
    }
	}





  # nur testausgaben
#  print "$$daten[1]{'-nach'} \n";
#  print "$$daten[1]{'-km'} gilomedor\n\n";

#  print "$$babnummern[0] \n";
#  print "$$babnummern[1] \n";
#  print "$$babnummern[2] \n\n";

#  print "$$pfade[0]{'-pfadnr'} \n";
#  print "$$pfade[0]{'-pfad1'} \n";
#  print "$$pfade[0]{'-pfad2'} \n";
#  print "$$pfade[0]{'-pfadkm'} \n";
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
