# *******************************************************************
# * Name             : amsoft_tk_maut.pm                            *
# * Erstellt am      : 21.01.2005 Thomas Weise                      *
# * Letzte Aenderung : 21.01.2005 Thomas Weise                      *
# * Beschreibung     : Maut                                         *
# *******************************************************************

require 5.000;
require Exporter;

use strict;

package amsoft_tk_maut;

use vars qw(
  @ISA
  @EXPORT
  );

@ISA    = qw(Exporter);
@EXPORT = qw(
	    );

use Tk;
use POSIX qw(strftime floor);

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

use amsoft_string;        # Modul zur Stringbearbeitung
use amsoft_tk_dialog;     # Modul für Dialoge / Messageboxen
use amsoft_tk_amdate;     # Modul für Datumsfunktionen
use amsoft_tk_ipruef;     # Modul für Eingabeprüfungen
use amsoft_tk_fontholen;  # holt Fonts aus Konfigurationsdatei
use amsoft_tk_amhead;     # Modul für Bildschirmaufteilung (helpzeile)
use amsoft_tk_osutil;     # Modul für OS-Funktionen
use amsoft_tk_gifconf;    # Modul zum Konfigurieren von gif's

use amsoft_tk_eslfho;   # laufende Nummer holen
use amsoft_tk_dst101;   # Artikelstamm VK
use amsoft_tk_dkl101;   # Kundenstamm-Hauptdaten
use amsoft_tk_chps00;   # Produktspezifikation Hauptsatz

use amsoft_tk_espsta;   # erweiterte Artikelsuche
use amsoft_tk_amcpae;   # Artikeleingabe
use amsoft_tk_chpssu;   # Spezifikationssuche
use amsoft_tk_chpsen;   # Spezifikationseingabe
use amsoft_tk_ampst1;   # erweiterte Kundensuche
use amsoft_tk_amcpke;   # Kunden- / Lieferanteneingabe
use amsoft_tk_chcppe;   # Produkteingabe
use amsoft_tk_chpsta;   # Produktsuche
use amsoft_tk_chtxsu;   # Textsuche
use amsoft_tk_chtxen;   # Texteingabe

#use amsoft_tk_chpav;    # AV-Methoden bearbeiten (TW)

use vars qw(
);

sub new
{
  my $classname = shift;
  my %params    = @_;

  my $self      = {};
  my $daten     = {};

  $self->{'-pwidget'}   = $params{-pwidget};
  $self->{'-config'}    = $params{-config};
  $self->{'-dbh'}       = $params{-dbh};
  $self->{'-firma' }    = $params{-firma};
  $self->{'-bediener' } = $params{-bediener};
  $self->{'-steuer' }   = $params{-steuer};

  $self->{'-font1'} = 'Helvetica -16 bold';
  $self->{'-font2'} = 'Helvetica -14 bold';

  $self->{'-exists'}  = 1;

  bless ($self, $classname);

  return $self;
}

# Erfassen ---------------------------------------------------------------------
sub erfassen
{
  my $self = shift;

  my $mw;
  my $config;
  my $dbh;
  my $firma;
  my $bediener;
  my $top;

  my $menu;

  my $frame;
  my 		$fra_butt;
  my 				$frametb;
  my 		$fra_spez;
  my 				$fra_spez_li;
  my 				$fra_spez_re;
  my 		$fra_av;
  my 				$fra_av_lbox;

  my $fontob;
  my $listfont;
  my $datakt_obj;
  my $datumf_obj;
  my $datumo_obj;
  my $datum_obj;

  my $mb_ok;
  my $me_ok;
  my $mb_yn;
  my $mb_yna;
  my $st_yn;

  my $amhead_obj;
  my $eslfho_obj;
  my $dst101_obj;
  my $dkl101_obj;
  my $chps00_obj;

  my $espsta_obj;
  my $amcpae_obj;
  my $chpssu_obj;
  my $chpsen_obj;
  my $ampst1_obj;
  my $amcpke_obj;
  my $chcppe_obj;
  my $chpsta_obj;
  my $chtxsu_obj;
  my $chtxen_obj;
  my $chpav_obj;  # Fenster zum Bearbeiten der AV-Methoden
	my $chptx_obj;  # Suchwidget für Textsuche

  my $antwort;
  my $helpball;
  my $helpzeile;
  my $aktjahr;
  my $aktdat;
  my $aktkw;


  $mw        = $self->{'-pwidget'};
  $config    = $self->{'-config'};
  $dbh       = $self->{'-dbh'};
  $firma     = $self->{'-firma'};
  $bediener  = $self->{'-bediener'};

  $top = $mw->Toplevel();
  $top->withdraw();
  amsoft_tk_osutil->maximize(-widget => $top);
  $top->raise();

  $datakt_obj = amsoft_tk_amdate->new(-outformat => 1);
  $aktdat  = $datakt_obj->aktdat();
  ($aktkw) = $datakt_obj->aktkw();
  $aktjahr = $datakt_obj->aktjahr();

  $datum_obj = amsoft_tk_amdate->new(-outformat => 3);

  $datumf_obj = amsoft_tk_amdate->new(-informat  => 2,
                                      -outformat => 1);

  $datumo_obj = amsoft_tk_amdate->new(-informat  => 1,
                                      -outformat => 2);

  			# !!! wieder ändern !!!
  #$top->protocol('WM_DELETE_WINDOW', sub { $self->ende();});  #zum testen raus
  $top->protocol('WM_DELETE_WINDOW', sub { $mw->destroy();});

  $top->title("Produktspezifikationen erfassen / ändern");

  $fontob   = amsoft_tk_fontholen->new(-config => $config);
  $listfont = $fontob->get_all(-type => 'L', -fontname => 'LISTFONT');
  $self->{'-listfont'} = $listfont;

  $mb_ok  = amsoft_tk_dialog->new(-pwidget => $top, -art => 'mbok');
  $me_ok  = amsoft_tk_dialog->new(-pwidget => $top, -art => 'meok');
  $mb_yn  = amsoft_tk_dialog->new(-pwidget => $top, -art => 'mbyn');
  $mb_yna = amsoft_tk_dialog->new(-pwidget => $top, -art => 'mbyna');
  $st_yn  = amsoft_tk_dialog->new(-pwidget => $top, -art => 'styn');

  ######## OBJEKTE ############
  			# Artikelstamm
  $dst101_obj = amsoft_tk_dst101->new(-config  => $config,
                                      -dbh     => $dbh);
  			# Kundenstamm
  $dkl101_obj = amsoft_tk_dkl101->new(-config  => $config,
                                      -dbh     => $dbh,);
  			# Produktspezifikation
  $chps00_obj = amsoft_tk_chps00->new(-config  => $config,
                                      -dbh     => $dbh);
  			# laufende Nummer holen
  $eslfho_obj = amsoft_tk_eslfho->new(-config => $config,
                                      -dbh    => $dbh);
  			# Bildschirmaufteilung (helpzeile)
  $amhead_obj = amsoft_tk_amhead->new(-pwidget => $top,
                                     -config  => $config,
																		  -knz     => 3);
  			# erweiterte Artikelsuche
  $espsta_obj = amsoft_tk_espsta->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# Artikeleingabe
  $amcpae_obj = amsoft_tk_amcpae->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# erweiterte Spezifikationssuche
  $chpssu_obj = amsoft_tk_chpssu->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# Spezifikationseingabe
  $chpsen_obj = amsoft_tk_chpsen->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# erweiterte Kundensuche
  $ampst1_obj = amsoft_tk_ampst1->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# Kunden- und Lieferanteneingabe
  $amcpke_obj = amsoft_tk_amcpke->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# Produkteingabe
  $chcppe_obj = amsoft_tk_chcppe->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# erweiterte Produktsuche
  $chpsta_obj = amsoft_tk_chpsta->new(-pwidget => $top,
                                      -dbh     => $dbh,
                                      -config  => $config);
  			# Textsuche
  $chtxsu_obj = amsoft_tk_chtxsu->new(-pwidget => $top,
                                      -config  => $config,
                                      -dbh     => $dbh);
				# Texteingabe
  $chtxen_obj = amsoft_tk_chtxen->new(-pwidget => $top,
                                      -config  => $config,
                                      -dbh     => $dbh);

#        # AV-Methoden bearbeiten
#  $chpav_obj  = amsoft_tk_chpav->new(-pwidget => $top,
#                                     -dbh     => $dbh,
#                                     -config  => $config);
#        # Such-Widget für Textsuche
#  $chptx_obj = amsoft_tk_chptx->new(-config  => $config,
#                                    -pwidget => $top,
#                                    -dbh     => $dbh);

  $self->{'-topwidget'}     = $top;
  $self->{'-ob_mbok'}       = $mb_ok;
  $self->{'-ob_meok'}       = $me_ok;
  $self->{'-ob_mbyn'}       = $mb_yn;
  $self->{'-ob_mbyna'}      = $mb_yna;
  $self->{'-ob_styn'}       = $st_yn;
  $self->{'-amhead_obj'}    = $amhead_obj;
  $self->{'-datakt_obj'}    = $datakt_obj;
  $self->{'-datumf_obj'}    = $datumf_obj;
  $self->{'-datumo_obj'}    = $datumo_obj;
  $self->{'-datum_obj'}     = $datum_obj;

  $self->{'-eslfho_obj'}    = $eslfho_obj;
  $self->{'-dst101_obj'}    = $dst101_obj;  # Artikelstamm
  $self->{'-dkl101_obj'}    = $dkl101_obj;  # Kundenstamm
  $self->{'-chps00_obj'}    = $chps00_obj;  # Produktspezifikation

  $self->{'-espsta_obj'}    = $espsta_obj;  # Artikelsuche
  $self->{'-amcpae_obj'}    = $amcpae_obj;  # Artikeleingabe
  $self->{'-chpssu_obj'}    = $chpssu_obj;  # Spezifikationssuche
  $self->{'-chpsen_obj'}    = $chpsen_obj;  # Spezifikationseingabe
  $self->{'-ampst1_obj'}    = $ampst1_obj;  # Kundensuche
  $self->{'-amcpke_obj'}    = $amcpke_obj;  # Kunden- und Lieferanteneingabe
  $self->{'-chcppe_obj'}    = $chcppe_obj;  # Produkteingabe
  $self->{'-chpsta_obj'}    = $chpsta_obj;  # Produktsuche
  $self->{'-chtxsu_obj'}    = $chtxsu_obj;  # Textsuche
  $self->{'-chtxen_obj'}    = $chtxen_obj;  # Texteingabe
  $self->{'-wertt'}         = "";

  $self->{'-lba_fuell'}     = 0;

  #$helpball = $top->Balloon(Name => 'ball1'); #das war drin
  $helpball = $top->Balloon(-class => 'Ball11');
  $self->{'-helpball'} = $helpball;


  ######## FRAMES ###########
  			# Menü
  $menu = $top->Menu();
  $top->configure(-menu => $menu);
  $self->{'-menu'} = $menu;
  $self->menu_datei();
  $self->menu_hilfe();

  			# Helpzeile
  ($helpzeile) = $amhead_obj->help_zeile(-text2 => "Firma : ".$firma,
				     												 		 -text3 => "Bediener : ".$bediener);
  $self->{'-helpzeile'} = $helpzeile;

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
  $self->{'-fra_butt'}->packForget();    # auskommentieren um Buttonframe anzuzeigen

  			# Frame - oben (für links und rechts)
  $fra_spez = $frame->Frame(-relief => 'ridge',
                           -bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $self->{'-fra_spez'} = $fra_spez;

  			# Frame - Spezifikationen links (mit Listbox)
  $fra_spez_li = $fra_spez->Frame(-relief => 'ridge',
                             			-bd     => 2,
		            						 			)->pack(-side   => 'left',
																		 			-anchor => 'nw',
				    												 			-expand => 0,
				 														 			-fill   => 'both');
  $self->{'-fra_spez_li'} = $fra_spez_li;
  $self->fra_spez_li();

  			# Frame - Spezifikationen rechts (Anzeige der Daten)
  $fra_spez_re = $fra_spez->Frame(-relief => 'ridge',
                             			-bd     => 2,
		            									)->pack(-side   => 'left',
			  	    														-anchor => 'nw',
				    															-expand => 0,
				    															-fill   => 'both');
  $self->{'-fra_spez_re'} = $fra_spez_re;
  $self->fra_spez_re();

  			# Frame - unten (AV-Methoden mit Listbox)
  $fra_av = $frame->Frame(-relief => 'ridge',
          								-bd     => 0,
		          						 )->pack(-side   => 'top',
				  												 -anchor => 'nw',
				  												 -expand => 0,
				  												 -fill   => 'both');
  $self->{'-fra_av'} = $fra_av;
  $self->fra_av();

	$amhead_obj->help_show(-text => "Nennen Sie Produktnummer oder Suchbegriff mit F5  /  F4=Ende  /  F1=Hilfe");

  			# Subroutinen aufrufen
  $self->ablauf(-knz => "start");

				# bind
	$top->bind('<KeyPress-F1>',   sub { $self->key_f1(); } );
	$top->bind('<KeyPress-F5>',   sub { $self->key_f5(); } );

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

# Buttonleiste -----------------------------------------------------------------
sub fra_butt
{
  my $self = shift;

  my $fra_butt = $self->{'-fra_butt'};

  my $button_an;
  my $button_nl;

  $button_an = $fra_butt->ToolButton(-text      => 'Leerbtn1',
                                   -type      => 'Button',
                                   -underline => 0,
                                   #-command   => sub { $self->lb_spez_fuellen();},
                                   -width     => 8,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $button_nl = $fra_butt->ToolButton(-text      => 'Leerbtn2',
                                   -type      => 'Button',
                                   -underline => 0,
                                   #-command   => sub { $self->ablauf(-knz => "start");},
                                   -width     => 8,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1);

  $self->{'-button_an'} = $button_an;
  $self->{'-button_nl'} = $button_nl;
#  $self->{'-helpball'}->attach($button_an, -balloonmsg => "Produktnummer eingeben");
#  $self->{'-helpball'}->attach($button_nl, -balloonmsg => "Neues Produkt bearbeiten");

}

# Frame Spezifikation-Listbox (oben links) -------------------------------------
sub fra_spez_li
{
  my $self = shift;

  my $lb;
  my $frame;
  my $frame1;
  my $frame2;

  my $e_crnr;
  my $btn_crnr_such;
  my $btn_crnr_reset;

  my $l_label = 17;
  my $lbhbg = "SteelBlue1";

  $frame  = $self->{'-fra_spez_li'};
  my $font2  = $self->{'-font2'};

  $frame1 = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x', -pady => 5);
  $frame2 = $frame->Frame()->pack(-side => 'bottom', -anchor => 'nw', -fill => 'both', -expand => 1);
  $frame1->Label(-text   => "Produktnummer: ",
								 -anchor => 'w',
		 						 -padx   => 2,
		 						 -font   => $font2,
                 )->pack(-side => 'left');

	$e_crnr  = $frame1->Entry(-textvariable => \$self->{'-crnr'},
             								-width        => 20,
             								#-justify      => 'right',
			       								-validate     => 'key',
			       								-vcmd         => \&amtk_crnr_ip,
                            )->pack(-side   => 'left',
			              								-anchor => 'nw');
	$self->{'-e_crnr'} = $e_crnr;

  $btn_crnr_such = $frame1->Button(-text      => '?',
                                   -image     => 'viewmag16',
                                   -takefocus => 0,
				  												 -command   => sub
				{
        	$self->spez_anzeige_leeren();
          $self->crnr_suche();
				  $self->lb_spez_fuellen();
				  $self->crnr_ein();
				},
                                 	 )->pack(-side   => 'left',
			                 										 -anchor => 'nw');
  $self->{'-btn_crnr_such'} = $btn_crnr_such;

  $btn_crnr_reset = $frame1->Button(-text      => '?',
                                   -image     => 'actreload16',
                                   -takefocus => 0,
				  												 -command   => sub
				{
          $self->ablauf(-knz => "start");
				},
                                 	 )->pack(-side   => 'left',
			                 										 -anchor => 'nw');
  $self->{'-btn_crnr_reset'} = $btn_crnr_reset;

  $frame1->Label(-textvariable => \$self->{'-crnr_name1'},
  							 -width        => 30,
                 )->pack(-side   => 'left',
			           				 -anchor => 'nw');

  $lb = $frame2->Scrolled("HList",
                          -scrollbars         => 'e',
			  									#-command            => sub { $self->lb_spez_auswahl();},
			  									-browsecmd          => sub { $self->lb_spez_browse();},
                          -selectmode         => 'browse',
                          -selectbackground   => 'SlateBlue2',
                          -selectforeground   => 'white',
			  									-selectborderwidth  => 1,
                          -background         => 'white',
			  									-highlightthickness => 0,
			  									-columns            => 4,
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

  $self->{'-lb_spez'} = $lb;

  $self->{'-e_crnr'}->focus();
  $self->helbzeile();

  $lb->columnWidth(0, -char => 9);
  $lb->columnWidth(1, -char => 38);
  $lb->columnWidth(2, -char => 4);
  $lb->columnWidth(3, -char => 10);

  $lb->headerCreate(0, -text => "Spez.-Nr.", -headerbackground => $lbhbg);
  $lb->headerCreate(1, -text => "Spezifikation-Name", -headerbackground => $lbhbg);
  $lb->headerCreate(2, -text => "ID", -headerbackground => $lbhbg);
  $lb->headerCreate(3, -text => "Datum", -headerbackground => $lbhbg);

  $e_crnr->bind("<KeyPress-Return>",  sub { $self->crnr_ein();});
  $e_crnr->bind("<KeyPress-Tab>",     sub { $self->crnr_ein();});
  $e_crnr->bind("<FocusIn>",          sub { $self->crnr_in();});

}

# Frame Spezifikation-Eingabe (oben rechts) ------------------------------------
sub fra_spez_re
{
  my $self = shift;

  my $frame;
  my $fra_butt;

  my $e_crnr_name1;
  my $e_cpspe;
  my $e_txlfd;
  my $e_cpspe_name1;
  my $e_cparnr;
  my $e_k0;
  my $e_k0_name1;
  my $e_speh;

  my $btn_spez_spei;
  my $btn_spez_neu;
  my $btn_spez_stor;
  my $btn_spez_such_spez;
  my $btn_spez_such_k0;

  my $btn_cpspe_such;
  my $btn_txlfd_such;
  my $btn_cparnr_such;
  my $btn_k0_such;
	my $rbtn_sphkz1;
	my $rbtn_sphkz2;
	my $rbtn_spina1;
	my $rbtn_spina2;
	my $rbtn_spsta1;
	my $rbtn_spsta2;

	my $frametb;     # für ToolButton

  my $l_label  = 11;
  my $l_label2 = 16;
  my $font;
  my $font2 = $self->{'-font2'};

  $frame  = $self->{'-fra_spez_re'};

  my $fra_spez_re_butt = $frame->Frame(-relief => 'ridge', -bd => 1)->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_crnr   = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_cpspe  = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_cparnr = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  #my $fra_txlfd  = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_k0     = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_ursprl = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
  my $fra_rest   = $frame->Frame()->pack(-side => 'top', -anchor => 'nw', -fill => 'x');
	my $fra_rest_l = $fra_rest->Frame()->pack(-side => 'left');
	my $fra_rest_r = $fra_rest->Frame()->pack(-side => 'left');
  my $fra_spsta  = $fra_rest_r->Frame(-relief=>'sunken', -bd=>2)->pack(-side => 'left', -anchor => 'nw', -fill => 'x');
  my $fra_sphkz  = $fra_rest_r->Frame(-relief=>'sunken', -bd=>2)->pack(-side => 'left', -anchor => 'nw', -fill => 'x');
  my $fra_spina  = $fra_rest_r->Frame(-relief=>'sunken', -bd=>2)->pack(-side => 'left', -anchor => 'nw', -fill => 'x');
  my $fra_speh   = $fra_rest_r->Frame(-relief=>'sunken', -bd=>2)->pack(-side => 'left', -anchor => 'nw', -fill => 'x');

  $self->{'-fra_spez_re_butt'} = $fra_spez_re_butt;
  $self->{'-fra_crnr'}         = $fra_crnr;
  $self->{'-fra_cpspe'}        = $fra_cpspe;
  $self->{'-fra_cparnr'}       = $fra_cparnr;
  #$self->{'-fra_txlfd'}        = $fra_txlfd;
  $self->{'-fra_k0'}           = $fra_k0;
  $self->{'-fra_speh'}         = $fra_speh;
  $self->{'-fra_sphkz'}        = $fra_sphkz;
  $self->{'-fra_spina'}        = $fra_spina;
  $self->{'-fra_spsta'}        = $fra_spsta;

  			# Buttons
  $frametb = $fra_spez_re_butt->ToolBar(-movable       => 1,
                              	-cursorcontrol => 0,
                              	-side          => 'top',
                              	)->pack();

  $btn_spez_spei = $frametb->ToolButton(-text      => 'Speichern',
  																 -type      => 'Button',
																	 -underline => 0,
																	 -command   => sub { $self->spez_speichern();},
																	 -width     => 12,
																	 )->pack(-side   => 'left',
																	 				 -fill   => 'both',
																					 -expand => 1,);

  $btn_spez_neu = $frametb->ToolButton(-text      => 'Neu',
  																 -type      => 'Button',
																	 -underline => 0,
																	 -command   => sub { $self->ablauf(-knz => "spezneu");},
																	 -width     => 12,
																	 )->pack(-side   => 'left',
																	 				 -fill   => 'both',
																					 -expand => 1,);

  $btn_spez_stor = $frametb->ToolButton(-text      => 'Storno',
                                   -type      => 'Button',
                                   -underline => 1,
                                   -command   => sub { $self->spez_storno();},
                                   -width     => 12,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $btn_spez_such_spez = $frametb->ToolButton(-text      => 'Spezifikationssuche',
                                   -type      => 'Button',
                                   -underline => 1,
                                   -command   => sub
			{
				$self->cpspe_suche();
				$self->db_chps00_select();
				$self->spez_anzeige_fuellen();
				$self->lb_av_fuellen();
			},
                                   -width     => 20,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $btn_spez_such_k0 = $frametb->ToolButton(-text      => 'Kundensuche',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->k0_suche();},
                                   -width     => 16,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

				# Zeile Produktnummer
  my $fra_crnr_l  = $fra_crnr->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_crnr_r  = $fra_crnr->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_crnr_r1 = $fra_crnr_r->Frame()->pack(-side => 'top', -anchor => 'nw');
  my $fra_crnr_r2 = $fra_crnr_r->Frame()->pack(-side => 'top', -anchor => 'nw');

  $fra_crnr_l->Label(-text   => "Produkt:",
		    					 	 -width  => $l_label,
		    					 	 -anchor => 'e',
		    					 	 -font   => $font2,
                   	 )->pack(-side   => 'left',
		           						   -anchor => 'nw');

  $fra_crnr_r1->Entry(-textvariable => \$self->{'-crnr'},
  										-width        => 20,
  										-class        => 'Roe',
			       					-validate     => 'key',
			       					-vcmd         => \&amtk_crnr_ip
                      )->pack(-side   => 'left',
			              					-anchor => 'nw');

  $fra_crnr_r1->Entry(-textvariable => \$self->{'-crnr_name1'},
  								 		-width        => 49,
	   	    				 		-class        => 'Roe',
                   		)->pack(-side   => 'right',
		           		 				 		-anchor => 'e',);

				# Zeile Spezifikationsnummer
  my $fra_cpspe_l  = $fra_cpspe->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_cpspe_r  = $fra_cpspe->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_cpspe_r1 = $fra_cpspe_r->Frame()->pack(-side => 'top', -anchor => 'nw');
  my $fra_cpspe_r2 = $fra_cpspe_r->Frame()->pack(-side => 'top', -anchor => 'nw');
  my $fra_cpspe_r3 = $fra_cpspe_r->Frame()->pack(-side => 'top', -anchor => 'nw');

  $fra_cpspe_l->Label(-text   => "Spezifikation:",
		       						-width  => $l_label,
		       						-anchor => 'e',
		       						-font   => $font2,
                      )->pack(-side   => 'top',
		              						-anchor => 'nw');

  $e_cpspe = $fra_cpspe_r1->Entry(-textvariable => \$self->{'-cpspe'},
                                  -width        => 20,
                                  #-class        => 'Roe_w',
                                  -relief       => 'groove',
                                  -validate     => 'key',
                                  -vcmd         => \&amtk_cpspe_ip
                                  )->pack(-side   => 'left',
                                          -anchor => 'nw');
  $font = $e_cpspe->cget(-font);

  $btn_cpspe_such = $fra_cpspe_r1->Button(-text      => '?',
                                      		-image     => 'viewmag16',
                                      		-takefocus => 0,
				      														-command   => sub
			{
				$self->cpspe_suche();
				$self->db_chps00_select();
				$self->spez_anzeige_fuellen();
				$self->lb_av_fuellen();
			},
                                     			)->pack(-side   => 'left',
			                     												-anchor => 'nw');

  $e_cpspe_name1 = $fra_cpspe_r1->Entry(-textvariable => \$self->{'-cpspe_name1'},
  								 		-width        => 49,
	   	    				 		-class        => 'Roe',
                   		)->pack(-side   => 'right',
		           		 				 		-anchor => 'e',);

  $fra_cpspe_r3->Scrolled("TextUndo",
                                 -height     => 3,
                                 -width      => 57,
                                 #-background   => 'grey90',
                                 -scrollbars => 'e',
               #-font       => $self->{'-text_font'},
                                )->pack(-side   => 'left',
                            -anchor => 'nw');

				# Zeile Artikelnummer
  my $fra_cparnr_l  = $fra_cparnr->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_cparnr_r  = $fra_cparnr->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_cparnr_r1 = $fra_cparnr_r->Frame()->pack(-side => 'top', -anchor => 'nw');
  my $fra_cparnr_r2 = $fra_cparnr_r->Frame()->pack(-side => 'top', -anchor => 'nw');

  $fra_cparnr_l->Label(-text   => "Artikel:",
		    						 -width  => $l_label,
		    						 -anchor => 'e',
		    						 -font   => $font2,
                   	)->pack(-side   => 'left',
		           							-anchor => 'nw');

  $e_cparnr = $fra_cparnr_r1->Entry(-textvariable => \$self->{'-cparnr'},
                               	 -width        => 20,
                               	 #-class        => 'Roe_w',
                               	 -relief       => 'groove',
			       										 -validate     => 'key',
			       										 -vcmd         => \&amtk_arnr_ip
                              	 )->pack(-side   => 'left',
			              										 -anchor => 'nw');

				# Zeile Kundennummer
  my $fra_k0_l  = $fra_k0->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_k0_r  = $fra_k0->Frame()->pack(-side => 'left', -anchor => 'nw');
  my $fra_k0_r1 = $fra_k0_r->Frame()->pack(-side => 'top', -anchor => 'nw');
  my $fra_k0_r2 = $fra_k0_r->Frame()->pack(-side => 'top', -anchor => 'nw');

  $fra_k0_l->Label(-text   => "Kunde:",
									 -width  => $l_label,
		    					 -anchor => 'e',
		    					 -font   => $font2,
                   )->pack(-side   => 'left',
		           		 				 -anchor => 'nw');

  $e_k0 = $fra_k0_r1->Entry(-textvariable => \$self->{'-k0'},
          									-width        => 20,
          									#-class        => 'Roe_w',
                            -relief       => 'groove',
			       								-validate     => 'key',
			       								-vcmd         => \&amtk_k0_ip
                            )->pack(-side   => 'left',
			              								-anchor => 'nw');

  $btn_k0_such = $fra_k0_r1->Button(-text      => '?',
                 										-image     => 'viewmag16',
                                  	-takefocus => 0,
				  													-command   => sub { $self->k0_suche();},
                                 		)->pack(-side   => 'left',
			                 											-anchor => 'nw');

  $fra_k0_r1->Entry(-textvariable => \$self->{'-k0_name1'},
                    -width        => 45,
	   	    					-class        => 'Roe',
                   	)->pack(-side   => 'top',
		           							-anchor => 'nw');

			# Zeile Ursprungsland
	my $fra_ursprl_l = $fra_ursprl->Frame()->pack(-side => 'left', -anchor => 'nw');
	my $fra_ursprl_r = $fra_ursprl->Frame()->pack(-side => 'left', -anchor => 'nw');

  $fra_ursprl_l->Label(-text   => "Land:",
									 -width  => $l_label,
		    					 -anchor => 'e',
		    					 -font   => $font2,
                   )->pack(-side   => 'left',
		           		 				 -anchor => 'nw');

	$fra_ursprl_r->Entry(-textvariable => \$self->{'-ursprl'},
										#-text         => ">>> Peter fragen <<<",
                    -width        => 70,
	   	    					#-class        => 'Roe_w',
                    -relief       => 'groove',
                   	)->pack(-side   => 'top',
		           							-anchor => 'nw');

      # Zeile Rest
      # Leerframe links
  $fra_rest_l->Label(-text   => "Kennzeichen:",
  									 -width  => $l_label,
  									 -font   => $font2
  									 )->pack(-side => 'left');
			# Frame Stabilitätsprüfung
  $fra_spsta->Label(-text   => "Stabilitätsprüfung",
									 -width  => $l_label2,
		    					 -anchor => 'center',
                   )->pack(-side   => 'top',
		           		 				 -anchor => 'center');
	$rbtn_spsta1 = $fra_spsta->Radiobutton(-text     => "Ja",
								 												-variable => \$self->{'-spsta'},
								 												-value    => "J",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');
	$rbtn_spsta2 =	$fra_spsta->Radiobutton(-text     => "Nein",
								 												-variable => \$self->{'-spsta'},
								 												-value    => "N",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');

			# Frame Kennzeichen Gesamtspezifikation
  $fra_sphkz->Label(-text   => "Kennz. Gesamtspez.",
									 -width  => $l_label2,
		    					 -anchor => 'center',
                   )->pack(-side   => 'top',
		           		 				 -anchor => 'center');
	$rbtn_sphkz1 = $fra_sphkz->Radiobutton(-text     => "Ja",
								 												-variable => \$self->{'-sphkz'},
								 												-value    => "J",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');
	$rbtn_sphkz2 =	$fra_sphkz->Radiobutton(-text     => "Nein",
								 												-variable => \$self->{'-sphkz'},
								 												-value    => "N",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');

			# Frame Spezifikation inaktiv
  $fra_spina->Label(-text   => "Spezifikation inaktiv",
									 -width  => $l_label2,
		    					 -anchor => 'center',
                   )->pack(-side   => 'top',
		           		 				 -anchor => 'center');
	$rbtn_spina1 = $fra_spina->Radiobutton(-text     => "Ja",
								 												-variable => \$self->{'-spina'},
								 												-value    => "J",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');
	$rbtn_spina2 =	$fra_spina->Radiobutton(-text     => "Nein",
								 												-variable => \$self->{'-spina'},
								 												-value    => "N",
								 												-class    => 'RBU',
										 										)->pack(-side => 'left');

				# Frame Gesamtspezifikation
  $fra_speh->Label(-text   => "Gesamtspezifikation",
									 -width  => $l_label2,
		    					 -anchor => 'center',
                   )->pack(-side   => 'top',
		           		 				 -anchor => 'center');

  $e_speh = $fra_speh->Entry(-textvariable => \$self->{'-speh'},
            								 -width        => 5,
            								 -class    => 'Roe',
                             )->pack(-side   => 'top',
			              				 				 -anchor => 'center');

  $self->{'-e_crnr_name1'}   = $e_crnr_name1;
  $self->{'-e_cpspe'}        = $e_cpspe;
  $self->{'-e_txlfd'}        = $e_txlfd;
  $self->{'-e_cpspe_name1'}  = $e_cpspe_name1;
  $self->{'-e_cparnr'}       = $e_cparnr;
  $self->{'-e_k0'}           = $e_k0;
  $self->{'-e_k0_name1'}     = $e_k0_name1;
  $self->{'-e_speh'}         = $e_speh;

  $self->{'-btn_spez_spei'}  = $btn_spez_spei;
  $self->{'-btn_spez_neu'}   = $btn_spez_neu;
  $self->{'-btn_spez_stor'}  = $btn_spez_stor;

  $self->{'-btn_cpspe_such'}  = $btn_cpspe_such;
  $self->{'-btn_cparnr_such'} = $btn_cparnr_such;
  $self->{'-btn_k0_such'}     = $btn_k0_such;
  $self->{'-rbtn_sphkz1'}     = $rbtn_sphkz1;
  $self->{'-rbtn_sphkz2'}     = $rbtn_sphkz2;
  $self->{'-rbtn_spina1'}      = $rbtn_spina1;
  $self->{'-rbtn_spina2'}      = $rbtn_spina2;
  $self->{'-rbtn_spsta1'}      = $rbtn_spsta1;
  $self->{'-rbtn_spsta2'}      = $rbtn_spsta2;

  $self->{'-helpball'}->attach($btn_spez_spei, -balloonmsg => "Änderungen der Spezifikation speichern");
  $self->{'-helpball'}->attach($btn_spez_neu, -balloonmsg => "Neue Spezifikation anlegen");
  $self->{'-helpball'}->attach($btn_spez_stor, -balloonmsg => "Spezifikation stornieren");
	$self->{'-helpball'}->attach($btn_spez_such_spez, -balloonmsg => "Suche nach vorhandenen Spezifikationen");
	$self->{'-helpball'}->attach($btn_spez_such_k0, -balloonmsg => "Kundensuche");
  $self->{'-helpball'}->attach($btn_cpspe_such, -balloonmsg => "Suche nach vorhandenen Spezifikationen");
  $self->{'-helpball'}->attach($btn_k0_such,  -balloonmsg => "Kundensuche");

  			# bind
  $e_cpspe->bind("<Return>",           sub
  												{
  													#$self->lb_spez_fuellen();
                            #$self->cpspe_ein();
  												}
  							);
  $e_cpspe->bind("<KeyPress-Tab>",     sub
  												{
                            #$self->{'-e_crnr'}->after(100,sub{$self->{'-e_cpspe'}->focus});
  													#$self->lb_spez_fuellen();
  													#$self->cpspe_ein();
  												}
  							);
  $e_cpspe->bind("<Control-Key-s>",    sub
	                        {
	                          $self->cpspe_suche();
	                          $self->lb_spez_fuellen();
	                          #$self->cpspe_ein();
	                        }
  							);
  $e_cpspe->bind("<FocusIn>",          sub    { $self->cpspe_in();} );

}

# Frame AV-Methoden (unten) ----------------------------------------------------
sub fra_av
{
	my $self = shift;

	my $frame = $self->{'-fra_av'};
  my   $fra_av_lboxrahmen;
	my     $fra_av_lbox;
  my       $fra_av_butt;
	my     $fra_av_re;
	my   $fra_av_bearb;

	my $frametb;      # für ToolButton
  my $lb;
  my $btn_av_zeig;
  my $btn_av_bearb;

  my $lbhbg = "SteelBlue1";

  		# Frame für Listbox und rechten (Leer-)frame
	$fra_av_lboxrahmen = $frame->Frame(-relief => 'ridge',
	                      			 -bd     => 0,
	                     				 )->pack(-side   => 'top',
		                     							 -anchor => 'nw',
			             										 -fill   => 'both',
			 	     													 -expand => 0);

  $fra_av_lbox = $fra_av_lboxrahmen->Frame(-relief => 'ridge',
	                      			 -bd     => 2,
	                     				 )->pack(-side   => 'left',
		                     							 -anchor => 'nw',
			             										 -fill   => 'both',
			 	     													 -expand => 1);

  $fra_av_re = $fra_av_lboxrahmen->Frame(-relief => 'ridge',
                               -bd     => 0,
                               )->pack(-side   => 'left',
                                       -anchor => 'nw',
                                       -fill   => 'both',
                                       -expand => 0);

  $fra_av_bearb = $frame->Frame(-relief => 'ridge',
	                      			 -bd     => 0,
	                     				 )->pack(-side   => 'top',
		                     							 -anchor => 'nw',
			             										 -fill   => 'both',
			 	     													 -expand => 0);

  		# Listbox-Frame
  				# Buttonframe oben
  $fra_av_butt = $fra_av_lbox->Frame(-relief => 'ridge',
	                      			 -bd     => 0,
	                     				 )->pack(-side   => 'top',
		                     							 -anchor => 'nw',
			             										 -fill   => 'both',
			 	     													 -expand => 0);

  $frametb = $fra_av_butt->ToolBar(-movable       => 1,
                                -cursorcontrol => 0,
                                -side          => 'top',
                                )->pack();

  $btn_av_zeig = $frametb->ToolButton(-text      => 'Leerbutton1',
                                   -type      => 'Button',
                                   -underline => 0,
                                   #-command   => sub { $self->spez_speichern();},
                                   -width     => 18,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $btn_av_bearb = $frametb->ToolButton(-text      => 'Leerbutton2',
                                   -type      => 'Button',
                                   -underline => 0,
                                   #-command   => sub { $self->spez_speichern();},
                                   -width     => 18,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  # die Listbox
  $lb = $fra_av_lbox->Scrolled("HList",
                         			 -scrollbars         => 'ose',
			 												 -command            => sub { $self->lb_av_auswahl();},
			 												 -browsecmd          => sub { $self->lb_av_browse();},
                         			 -selectmode         => 'browse',
                         			 -selectbackground   => 'SlateBlue2',
                         			 -selectforeground   => 'white',
			 												 -selectborderwidth  => 1,
                         			 -background         => 'white',
			 												 -highlightthickness => 0,
			 												 -columns            => 8,
			 												 -header             => 1,
			 												 -itemtype           => 'text',
			 												 -font               => $self->{'-listfont'},
			 												 -takefocus          => 1,
			 												 -height             => 12,
			 												 )->pack(-expand => 1,
			 												 				 -fill => 'both',
			 												 				 -side => "left",
			 												 				 -anchor => "nw");

  $lb->bind('<MouseWheel>'    => [sub { $_[0]->yview('scroll', -($_[1] / 120) * 1, 'units')},  Ev('D')]);
  Tk::Autoscroll::Init($lb);

  $lb->columnWidth(0, -char => 14);
  $lb->columnWidth(1, -char => 34);
  $lb->columnWidth(2, -char => 7);
  $lb->columnWidth(3, -char => 12);
  $lb->columnWidth(4, -char => 12);
  $lb->columnWidth(5, -char => 9);
  $lb->columnWidth(6, -char => 7);
  $lb->columnWidth(7, -char => 11);
  #$lb->columnWidth(8, -char => 14);

  $lb->headerCreate(0, -text => "AV-Methode-Nr.", -headerbackground => $lbhbg);
  $lb->headerCreate(1, -text => "Bezeichnung", -headerbackground => $lbhbg);
  $lb->headerCreate(2, -text => "Einheit", -headerbackground => $lbhbg);
  $lb->headerCreate(3, -text => "Von", -headerbackground => $lbhbg);
  $lb->headerCreate(4, -text => "Bis", -headerbackground => $lbhbg);
  $lb->headerCreate(5, -text => "Operator", -headerbackground => $lbhbg);
  $lb->headerCreate(6, -text => "Kz. IPC", -headerbackground => $lbhbg);
  $lb->headerCreate(7, -text => "Methodenart", -headerbackground => $lbhbg);
  #$lb->headerCreate(8, -text => "", -headerbackground => $lbhbg);

  $self->{'-fra_av_lbox'}  = $fra_av_lbox;
  $self->{'-fra_av_re'}    = $fra_av_re;
  $self->{'-lb_av'}        = $lb;
  $self->{'-fra_av_bearb'} = $fra_av_bearb;

      # Leerframe (rechts neben Listbox
  $fra_av_re->Label(-width => 40)->pack(-side => 'left');

  		# Frame unten
  $self->fra_av_bearb();
}

# Frame AV-unten (Av-Methoden bearbeiten) --------------------------------------
sub fra_av_bearb
{
	my $self = shift;

  my $fra;
  my   $frame;
  my     $fra_butt;
  my     $fra_text;
  my     $fra_masseinh;
  my     $fra_operat;
  my     $fra_spezber;
  my     $fra_methart;
  my     $fra_kennzipc;
  my   $frame_re;
  my $frametb;         # für ToolButton

  my $e_txlfd_av;    # Entry lfd.Nr-Text
  my $e_text;        # Entry Text
  my $e_cpdmae;      # Entry Maßeinheit
  my $e_cpop;        # Entry Operator
	my $e_cpsbv;       # Entry Spezifikationsbereich VON
	my $e_cpsbb;       # Entry Spezifikationsbereich BIS
	my $e_cpfart;      # Entry Methodenart der Analyse
	my $e_ipcknz;      # Entry Kennzeichen IPC
  my $be_text;
  my $be_cpdmae;
  my $be_cpop;
	my $be_cpfart;
	my $be_ipcknz;

	my $btn_av_unten1;
	my $btn_av_unten2;

  my $font1;
  my $font2;
  my $chtxsu_obj;

  $fra        = $self->{'-fra_av_bearb'};
  $chtxsu_obj = $self->{'-chtxsu_obj'};
  $font1      = $self->{'-font1'};
  $font2      = $self->{'-font2'};

  $frame = $fra->Frame(-relief => 'ridge',
																		  -bd     => 2,
																	  	)->pack(-side   => 'left',
				 															 		  	-anchor => 'nw',
				 															 		  	-expand => 0,
				 															 		  	-fill   => 'both');

  $frame_re = $fra->Frame(-relief => 'sunken',
																		  -bd     => 0,
																	  	)->pack(-side   => 'left',
				 															 		  	-anchor => 'nw',
				 															 		  	-expand => 0,
				 															 		  	-fill   => 'both');

  		# Button-Frame
  $fra_butt = $frame->Frame(-relief => 'sunken',
																		  -bd     => 0,
																	  	)->pack(-side   => 'top',
				 															 		  	-anchor => 'nw',
				 															 		  	-expand => 0,
				 															 		  	-fill   => 'both');

  $frametb = $fra_butt->ToolBar(-movable       => 1,
                                -cursorcontrol => 0,
                                -side          => 'top',
                                )->pack();

  $btn_av_unten1 = $frametb->ToolButton(-text      => 'Speichern',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->av_speichern();},
                                   -width     => 18,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $btn_av_unten2 = $frametb->ToolButton(-text      => 'Neu',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->av_neu();},
                                   -width     => 18,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

			# Zeile Text
	$fra_text = $frame->Frame(-relief => 'sunken',
									 									-bd     => 0,
																	  )->pack(-side   => 'top',
				 															 		  -anchor => 'nw',
				 															 		  -expand => 0,
				 															 		  -fill   => 'both');

	$fra_text->Label(-text   => "Text",
									-anchor => 'w',
								 	-font   => $font2,
									-width  => 11,
									-padx   => 4,
								 )->pack(-side => 'left');

  $e_txlfd_av = $fra_text->Entry(-textvariable => \$self->{'-wertt'}, #??
														 #-font         => $font2,
														 -width        => 10,
														 #-class        => 'Roe_w',
                             -relief       => 'groove',
													  )->pack(-side => 'left');
	$self->{'-e_txlfd_av'} = $e_txlfd_av;

	$fra_text->Button(-text    => "?",
	  							 -image     => 'viewmag16',
									 -font    => $font2,
									 -command => sub
			{
        $self->text_anfot_suche();
        $self->text_anfot_ein();
			}
									 )->pack(-side => 'left');

	$e_text = $fra_text->Entry(-textvariable => \$self->{'-anfotext'},
														#-font         => $font2,
														-width        => 45,
														-class        => 'Roe',
													 )->pack(-side => 'left');

	# Zeile Maßeinheit
	$fra_masseinh = $frame->Frame(-relief => 'sunken',
																		 		-bd     => 0,
																	  		)->pack(-side   => 'top',
				 															 		  		-anchor => 'nw',
				 															 		  		-expand => 0,
				 															 		  		-fill   => 'both');

	$be_cpdmae = $fra_masseinh->BrowseEntry(-label    => "Maßeinheit     ",
															-autolimitheight => 1,
															-listwidth   => 50,
															-width => 8,
															#-class           => 'BrEntry',
                              -relief       => 'groove',
															-font            => $font2,
		 													-variable => \$self->{'-cpdmae'}
														 )->pack(-side => 'left',
																		 -padx => 5);
	$be_cpdmae->insert("end", "%");
	$be_cpdmae->insert("end", "BLATT");
	$be_cpdmae->insert("end", "CBM");
	$be_cpdmae->insert("end", "GR");
	$be_cpdmae->insert("end", "H");
	$be_cpdmae->insert("end", "HL");
	$be_cpdmae->insert("end", "K");
	$be_cpdmae->insert("end", "KG");
	$e_cpdmae = $be_cpdmae;

		# Zeile Operator
	$fra_operat = $frame->Frame(-relief => 'sunken',
																		  -bd     => 0,
																	  )->pack(-side   => 'top',
				 															 		  -anchor => 'nw',
				 															 		  -expand => 0,
				 															 		  -fill   => 'both');

	$be_cpop = $fra_operat->BrowseEntry(-label    => "Operator         ",
															-autolimitheight => 1,
															-listwidth   => 50,
															-width => 8,
															#-class           => 'BrEntry',
                              -relief       => 'groove',
															-font            => $font2,
		 													-variable => \$self->{'-cpop'}
														 )->pack(-side => 'left',
																		 -padx => 5);
	$be_cpop->insert("end", "<");
	$be_cpop->insert("end", "<=");
	$be_cpop->insert("end", ">");
	$be_cpop->insert("end", ">=");
	$be_cpop->insert("end", "=");
	$be_cpop->insert("end", "-");
	$be_cpop->insert("end", "ca");
  $e_cpop = $be_cpop;

			# Zeile Spezifikationsbereich
	$fra_spezber = $frame->Frame(-relief => 'sunken',
																		 	 -bd     => 0,
																	  		)->pack(-side   => 'top',
				 															 		  		-anchor => 'nw',
				 															 		  		-expand => 0,
				 															 		  		-fill   => 'both');

	$fra_spezber->Label(-text   => "Spezifikationsbereich  von",
									-anchor => 'w',
								 	-font   => $font2,
									-width  => 20,
									-padx   => 5,
								 )->pack(-side => 'left');

	$e_cpsbv = $fra_spezber->Entry(-textvariable => \$self->{'-cpsbv'},
														#-font         => $font2,
														-width        => 10,
														#-class        => 'Roe',
														-relief        => 'groove',
													 )->pack(-side => 'left');

	$fra_spezber->Label(-text   => "bis",
									-anchor => 'w',
								 	-font   => $font2,
									-width  => 2,
									-padx   => 8,
								 )->pack(-side => 'left');

	$e_cpsbb = $fra_spezber->Entry(-textvariable => \$self->{'-cpsbb'},
														#-font         => $font2,
														-width        => 10,
														#-class        => 'Roe',
														-relief       => 'groove',
													 )->pack(-side => 'left');

  		# Frame-Zeile Art der Methode für Analyse
	$fra_methart = $frame->Frame(-relief => 'sunken',
																			 -bd     => 0,
																	  	)->pack(-side   => 'top',
				 															 		  	-anchor => 'nw',
				 															 		  	-expand => 0,
				 															 		  	-fill   => 'both');

	$be_cpfart = $fra_methart->BrowseEntry(-label    => "Methodenart  ",
															-autolimitheight => 1,
															-listwidth   => 50,
															-width => 8,
															#-class           => 'BrEntry',
															-relief       => 'groove',
															-font            => $font2,
		 													-variable => \$self->{'-cpfart'}
														 )->pack(-side => 'left',
																		 -padx => 5);
	$be_cpfart->insert("end", "0");
	$be_cpfart->insert("end", "1");
	$be_cpfart->insert("end", "2");
	$be_cpfart->insert("end", "3");
	$be_cpfart->insert("end", "4");
	$be_cpfart->insert("end", "5");
	$e_cpfart = $be_cpfart;

  		# Zeile Kennzeichen IPC
	$fra_kennzipc = $frame->Frame(-relief => 'sunken',
																			 	-bd     => 0,
																	  		)->pack(-side   => 'top',
				 															 		  		-anchor => 'nw',
				 															 		  		-expand => 0,
				 															 		  		-fill   => 'both');

	$be_ipcknz = $fra_kennzipc->BrowseEntry(-label    => "Kennz. IPC      ",
															-autolimitheight => 1,
															-listwidth   => 50,
															-width => 8,
															#-class           => 'BrEntry',
															-relief       => 'groove',
															-font            => $font2,
		 													-variable => \$self->{'-ipcknz'}
														 )->pack(-side => 'left',
																		 -padx => 5);
	$be_ipcknz->insert("end", "ja");
	$be_ipcknz->insert("end", "nein");
	$e_ipcknz = $be_ipcknz;

}

# Produktsuche -----------------------------------------------------------------
sub crnr_suche
{
  my $self = shift;

  my $crnr;
  my $chpsta_obj = $self->{'-chpsta_obj'};

  if (!$chpsta_obj->exist())
  {
    $chpsta_obj->suche(-suknz => 0,
                       -such  => $self->{'-crnr'});
    $chpsta_obj->warten();
    $crnr = $chpsta_obj->get();
    if (defined($crnr))
    {
      $self->{'-crnr'} = $crnr;
      $self->crnr_ein();
    }
  }
}

# Produktnummereingabe (schreibt gleich -daten von CST101 in den Hash) ---------
sub crnr_ein
{
  my $self = shift;

  my $chcppe_obj = $self->{'-chcppe_obj'};

  $chcppe_obj->eingabe(-crnr => $self->{'-crnr'},
                       -knz  => 1);
  if ($chcppe_obj->{'-ret'} == 1)
  {
    $self->{'-crnr'}  = $chcppe_obj->{'-retcrnr'};
    $self->{'-crsu'}  = $chcppe_obj->{'-daten'}->{'CRSU'};
    $self->{'-crnr_name1'} = $chcppe_obj->{'-daten'}->{'CRHN1'};
    $self->{'-crnr_name2'} = $chcppe_obj->{'-daten'}->{'CRHN2'};
    $self->{'-e_cpspe'}->focus();
    $self->helbzeile();
  }
  else
  {
    $self->{'-ob_mbok'}->get(-title => "Achtung",
				        						 -text  => "Produktnummer $self->{'-crnr'} ist nicht in der Datenbank enthalten.",
				        						 -icon  => 'warning');

    $self->{'-crnr'}       = "";
    $self->{'-crsu'}       = "";
    $self->{'-crnr_name1'} = "";
    $self->{'-crnr_name2'} = "";
    $self->{'-e_crnr'}->focus();
    $self->{'-e_crnr'}->after(75,sub{$self->{'-e_crnr'}->focus});
    $self->helbzeile();

    return 0;
  }

  return 1;
}

# Produktnummer Focus In -------------------------------------------------------
sub crnr_in
{
  my $self = shift;

  $self->{'-crnr'} = cvs($self->{'-crnr'},3);
}

# Spezifikationssuche ---------------------------------------------------------
sub cpspe_suche
{
  my $self = shift;

  my $cpspe;
  my $chpssu_obj = $self->{'-chpssu_obj'};

  if (!$chpssu_obj->exist())
  {
    $chpssu_obj->suche(-crnr => $self->{'-crnr'}); # ??? war $self->{'arnr'}
    $chpssu_obj->warten();
    $cpspe = $chpssu_obj->get();
    if (defined($cpspe))
    {
      $self->{'-cpspe'} = $cpspe;
      $self->cpspe_ein();
    }
  }
}

# Spezifikationsnummereingabe --------------------------------------------------
sub cpspe_ein
{
  my $self = shift;

  my $chpsen_obj = $self->{'-chpsen_obj'};
  $chpsen_obj->eingabe(-crnr  => $self->{'-crnr'},
                       -cpspe => $self->{'-cpspe'});

  if ($chpsen_obj->{'-ret'} == 1)
  {
    $self->{'-cpspe'}  = $chpsen_obj->{'-retcpspe'};
    $self->{'-cpspe_name1'} = $chpsen_obj->{'-daten'}->{'SPT1'}; # war CHTX1D
    $self->{'-cpspe_name2'} = $chpsen_obj->{'-daten'}->{'SPT2'}; # war CHTX2D
  }
  else
  {
    $self->{'-ob_mbok'}->get(-title => "Achtung",
				        						 -text  => "Spezifikationsnummer $self->{'-cpspe'} ist nicht in der Datenbank enthalten.",
				        						 -icon  => 'warning');
    $self->{'-cpspe'}  = "";
    $self->{'-cpspe_name1'} = "";
    $self->{'-cpspe_name2'} = "";
    $self->{'-e_cpspe'}->after(75,sub{$self->{'-e_cpspe'}->focus});

    return 0;
  }

  return 1;
}

# Spezifikationsnummer Focus In ------------------------------------------------
sub cpspe_in
{
  my $self = shift;
  $self->{'cpspe'} = cvs($self->{'cpspe'},3);
}

# hole Spezifikationsname, der zu txlfd gehört ---------------------------------
sub cpspe_name_holen
{
	my $self   = shift;
	my %params = @_;

	my $txlfd = $params{-txlfd};
  my $cpspe_name1;                    # für return

  my $dbh  = $self->{'-dbh'};
  my ($sql, $sth);

	if (defined($dbh))
	{

    $sql = qq{ select CHTX1D
               from   CHTX01
               where  TXLFD = '$txlfd'
               };
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my @zeile = $sth->fetchrow_array())
    {
      $cpspe_name1 = $zeile[0];
    }
    $sth->finish();
	}

	return $cpspe_name1;
}

# Kundensuche ------------------------------------------------------------------
sub k0_suche
{
  my $self = shift;

  my $k0;
  my $ampst1_obj = $self->{'-ampst1_obj'};

  if (!$ampst1_obj->exist())
  {
    $ampst1_obj->suche(-suknz  => 0,
                       -ausknz => 2,
                       -such   => "");
    $ampst1_obj->warten();
    $k0 = $ampst1_obj->get();
    if (defined($k0))
    {
      $self->{'-k0'} = $k0;
      $self->k0_ein();
    }
  }
}

# Kundeneingabe ----------------------------------------------------------------
sub k0_ein
{
  my $self = shift;

  my $amcpke_obj = $self->{'-amcpke_obj'};
  $amcpke_obj->eingabe(-k0     => $self->{'-k0'},
                       -ausknz => 2,
                       -knz    => 1);
  if ($amcpke_obj->{'-ret'} == 1)
  {
    $self->{'-k0'}  = $amcpke_obj->{'-retk0'};
    $self->{'-k0_name1'}    = $amcpke_obj->{'-daten'}->{'K1'};
    $self->{'-k0_name2'}    = $amcpke_obj->{'-daten'}->{'K2'};
  }
  else
  {
    $self->{'-k0'}  = "";
    $self->{'-k0_name1'}    = "";
    $self->{'-k0_name2'}    = "";
    #$self->{'-e_k0'}->focus();
    $self->helbzeile();
    return 0;
  }

  return 1;
}

# Ursprungsland holen ----------------------------------------------------------
sub ursprl_holen
{
	my $self = shift;

	my $ursprl;                     # Ursprungsland
  my $crnr   = $self->{'-crnr'};  # Produktnummer für Suche
  my $cpspe  = $self->{'-cpspe'}; # Spezifikationsnummer für Suche
  my $dbh    = $self->{'-dbh'};
  my ($sql, $sth);

  if (defined($dbh))
  {
  	$sql = qq{ select URSPRL
  						 from   CHPS00
  						 where  CRNR  = '$crnr'
  						 and    CPSPE = '$cpspe'
  						 };
  	$sth = $dbh->prepare($sql);
  	$sth->execute();
    $ursprl = $sth->fetchrow_array();
  	$sth->finish();
  }

	$self->{'-ursprl'} = $ursprl;
}

# Texteinabe (AV-Methoden-Text (Anforderungstexteingabe)) ----------------------
sub text_anfot_ein
{
  my $self = shift;

  my $chtxen_obj = $self->{'-chtxen_obj'};
  $chtxen_obj->eingabe(-txlfd => $self->{'-wertt'},
                       -knz   => 0,
		       -txknz => $self->{'-txlfd'});

  if ($chtxen_obj->{'-ret'} == 1)
  {
    $self->{'-wertt'}    = $chtxen_obj->{'-rettxlfd'};
    $self->{'-anfotext'} = $chtxen_obj->{'-daten'}->{'CHTX1D'};
  }
  else
  {
    $self->{'-wertt'}    = "";
    $self->{'-anfotext'} = "";
    if ($chtxen_obj->{'-ret'} == 0)
    {
      #$self->{'-e_anfo'}->after(75, sub { $self->{'-e_anfo'}->focus();});
    }
  }

  return 1;
}

# Anforderungstextsuche -------------------------------------------------------
sub text_anfot_suche
{
  my $self = shift;

  my $wertt;
  my $chtxsu_obj = $self->{'-chtxsu_obj'};

  if (!$chtxsu_obj->exist())
  {
    $chtxsu_obj->suche(-txknz => $self->{'-txlfd_av'},
                       -suknz => 0);
    $chtxsu_obj->warten();
    $wertt = $chtxsu_obj->get();
    if (defined($wertt))
    {
      $self->{'-wertt'} = $wertt;
      $self->text_anfot_ein();
print"in text_anfot_suche -wertt: $self->{'-wertt'} \n";
    }
  }



}

# Suche verteilen --------------------------------------------------------------
sub suche
{
  my $self = shift;

  my $wer = $self->{'-fra_spez_re'}->focusCurrent();

  if ($wer eq $self->{'-e_arnr'})
  {
    $self->cparnr_suche();
  }

  if ($wer eq $self->{'-e_cpspe'})
  {
    $self->cpspe_suche();
  }

  if ($wer eq $self->{'-e_linr'})
  {
    $self->linr_suche();
  }
}

# Textwidget prüfen ------------------------------------------------------------
sub pruef_text
{
  my $self = shift;

  my $textwidget = $self->{'-e_albem1'};

  my $text = $textwidget->get('1.0', 'end');

  if (length($text) > 190)
  {
    $textwidget->delete('insert -1 chars');
    $self->{'-ob_mbok'}->get(-title => "Eingabe Bemerkung",
		             -text  => "Maximale Textlänge erreicht !",
		             -icon  => 'warning');
  }
}

# Listbox Spezifikationen füllen -----------------------------------------------
sub lb_spez_fuellen
{
  my $self    = shift;
  my %params  = @_;

  my $lb     = $self->{'-lb_spez'};
  my $config = $self->{'-config'};
  my $dbh    = $self->{'-dbh'};
  my ($sql, $sth);

  my $crnr   = $self->{'-crnr'};
  my $cpspe;
  my $txlfd;
  my $cpspe_name1;
  my $cpid;
  my $cpdat;
  my $lb_data;

  $lb->delete('all');
  #$self->{'-lb_av'}->delete('all');
  $lb->update();

  $self->{'-topwidget'}->configure(-cursor => 'watch');

  $sql = qq{ select CPSPE, TXLFD, CPID, CPDAT
             from CHPS00
             where CRNR = '$crnr'
             order by CPSPE
             };

  my $i = 0;
  if (defined($dbh))
  {
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my @z = $sth->fetchrow_array())
    {
      $cpspe  = $z[0];
      $txlfd  = $z[1];
      $cpid   = $z[2];
      $cpdat  = $z[3];

      $cpspe_name1 = $self->cpspe_name_holen(-txlfd => $txlfd);
      $cpdat       = $self->datum_umformen(-datum => $cpdat);

      $lb_data = {};
      $lb_data->{'i'}            = $i;
      $lb_data->{'-cpspe'}       = $cpspe;
      $lb_data->{'-cpspe_name1'} = $cpspe_name1;
      $lb_data->{'-cpid'}        = $cpid;
      $lb_data->{'-cpdat'}       = $cpdat;

      $lb->add($i, -data => $lb_data);

      $lb->itemCreate($i, 0, -text => $cpspe);
      $lb->itemCreate($i, 1, -text => $cpspe_name1);
      $lb->itemCreate($i, 2, -text => $cpid);
      $lb->itemCreate($i, 3, -text => $cpdat);

      $i++;
    }
    $sth->finish();
  }

  $self->{'-topwidget'}->configure(-cursor => 'arrow');
  $lb->focus();
  $self->helbzeile();
}

# Listbox Spezifikationen leeren -----------------------------------------------
sub lb_spez_leeren
{
  my $self = shift;

  my $lb    = $self->{'-lb_spez'};

  $lb->delete('all');
  $lb->selectionClear();
  $lb->anchorClear();
}

# Listbox Lieferung browse -----------------------------------------------------
sub lb_spez_browse
{
  my $self   = shift;
  my %params = @_;

  my $lb = $self->{'-lb_spez'};
  my $cpspe;
  my @ausl  = ();
  my $i = 0;

  @ausl = $lb->selectionGet();
  if ($#ausl < 0)
  {
    return;
  }

  $i = $ausl[0];
  $cpspe  = $lb->infoData($i)->{'-cpspe'};
  $self->{'-cpspe'} = $cpspe;

  $self->lb_av_fuellen();
	$self->db_chps00_select();
  $self->spez_anzeige_fuellen();

}

# Listbox Auswahl Spezifikation ------------------------------------------------
sub lb_spez_auswahl
{
#  my $self   = shift;
#  my %params = @_;

#  my $lb    = $self->{'-lb_spez'};
#  my $dbh   = $self->{'-dbh'};
#  my ($sql,$sth);

#  my $crnr  = $self->{'-crnr'};
#  my $cpspe;

#  my @ausl  = ();
#  my $i;

#  @ausl = $lb->selectionGet();
#  if ($#ausl < 0)
#  {
#    return;
#  }
#  $i = $ausl[0];
#  $cpspe = $lb->infoData($i)->{'-cpspe'};

#  if (defined($dbh))
#  {
#    $sql = qq{ select   CRNR,CPSPE,TXLFD,CPARNR,K0,SPEH,SPHKZ,SPINA,SPSTA
#               from     CHPS00
#               where    CRNR  = '$crnr'
#                 and    CPSPE = '$cpspe'
#              };
#    $sth = $dbh->prepare($sql);
#    $sth->execute();
#    while (my @z = $sth->fetchrow_array())
#    {
#      $self->{'-crnr'}   = $z[0];
#      $self->{'-cpspe'}  = $z[1];
#      $self->{'-txlfd'}  = $z[2];
#      $self->{'-cparnr'} = $z[3];
#      $self->{'-k0'}     = $z[4];
#      $self->{'-speh'}   = $z[5];
#      $self->{'-sphkz'}  = $z[6];
#      $self->{'-spina'}  = $z[7];
#      $self->{'-spsta'}  = $z[8];
#    }
#    $sth->finish();
#    $self->spez_anzeige_fuellen();
#  }
	#print "in lb_spez_auswahl:$self->{'-crnr'}-$self->{'-cpspe'}-$self->{'-txlfd'}-$self->{'-cparnr'}-$self->{'-k0'}-$self->{'-speh'}-$self->{'-cphkz'}-$self->{'-cpina'}-$self->{'-cpsta'}\n";

  #$self->lb_av_fuellen();
}

# Listbox AV-Methoden füllen ---------------------------------------------------
sub lb_av_fuellen
{
	my $self = shift;

  my $lb    = $self->{'-lb_av'};
  my $crnr  = $self->{'-crnr'};
  my $cpspe = $self->{'-cpspe'};
  my ($cpslfd, $txlfd_av, $cpop, $cpsbv, $cpsbb, $cpsbt, $cpdmae, $cpfart, $ipcknz);
  my $text_av;

	my $dbh = $self->{'-dbh'};
	my ($sql, $sth);

	my $lb_data;

  $lb->delete('all');
  #$self->{'-lb_av'}->delete('all');
  $lb->update();

  my $i   = 0;
	if (defined($dbh))
	{
		$sql = qq{ select   CRNR, CPSPE, CPSLFD, TXLFD, CPOP, CPSBV, CPSBB, CPSBT, CPDMAE, CPFART, IPCKNZ
							 from     CHPS01
							 where    CRNR  = '$crnr'
								 and    CPSPE = '$cpspe'
							 order by CPSLFD};
		$sth = $dbh->prepare($sql);
		$sth->execute();

		while (my @z = $sth->fetchrow_array())
		{
			$crnr     = $z[0];
			$cpspe    = $z[1];
			$cpslfd   = $z[2];
			$txlfd_av = $z[3];
			$cpop     = $z[4];
			$cpsbv    = $z[5];
			$cpsbb    = $z[6];
			$cpsbt    = $z[7];
			$cpdmae   = $z[8];
			$cpfart   = $z[9];
			$ipcknz   = $z[10];

      	# Bezeichnung für AV-Methode holen
			$self->{'-wertt'} = $txlfd_av;
			$self->text_anfot_ein();
			$text_av = $self->{'-anfotext'};

			$lb_data = {};
			$lb_data->{'i'}         = $i;
			$lb_data->{'-crnr'}     = $crnr;
			$lb_data->{'-cpspe'}    = $cpspe;
			$lb_data->{'-cpslfd'}   = $cpslfd;
			$lb_data->{'-txlfd_av'} = $txlfd_av;
			$lb_data->{'-cpop'}     = $cpop;
			$lb_data->{'-cpsbv'}    = $cpsbv;
			$lb_data->{'-cpsbb'}    = $cpsbb;
			$lb_data->{'-cpsbt'}    = $cpsbt;
			$lb_data->{'-cpdmae'}   = $cpdmae;
			$lb_data->{'-cpfart'}   = $cpfart;
			$lb_data->{'-ipcknz'}   = $ipcknz;

    	$lb->add($i, -data => $lb_data);

			$lb->itemCreate($i, 0, -text => $txlfd_av);  #??
			$lb->itemCreate($i, 1, -text => $text_av);
			$lb->itemCreate($i, 2, -text => $cpdmae);
    	$lb->itemCreate($i, 3, -text => sprintf("%10.2f", $cpsbv));
    	$lb->itemCreate($i, 4, -text => sprintf("%10.2f", $cpsbb));
    	$lb->itemCreate($i, 5, -text => "        $cpop");
    	$lb->itemCreate($i, 6, -text => "     $ipcknz");
    	$lb->itemCreate($i, 7, -text => "            $cpfart");
    	#$lb->itemCreate($i, 8, -text => $ipcknz);

			$i++;
		}
		$sth->finish();
	}
}

# Listbox Artikel browse -------------------------------------------------------
sub lb_av_browse
{
  my $self   = shift;
  my %params = @_;

  my $lb = $self->{'-lb_av'};
  #my $txlfd_av;
  my @ausl = ();
  my ($crnr, $cpspe, $cpslfd);

  my $i = 0;
  @ausl = $lb->selectionGet();
  if ($#ausl < 0)
  {
    return;
  }

  $i = $ausl[0];
  $crnr   = $lb->infoData($i)->{'-crnr'};
  $cpspe  = $lb->infoData($i)->{'-cpspe'};
  $cpslfd = $lb->infoData($i)->{'-cpslfd'};

	$self->{'-crnr'}   = $crnr;
	$self->{'-cpspe'}  = $cpspe;
	$self->{'-cpslfd'} = $cpslfd;
	$self->db_chps01_select();

			# Text zu txlfd_av holen (Bezeichnung der AV-Methode)
	$self->{'-wertt'} = $self->{'-txlfd_av'};
	$self->text_anfot_ein();

  $self->av_anzeige_fuellen();
}

# Listbox Artikel auswählen ----------------------------------------------------
sub lb_av_auswahl
{
  my $self   = shift;
  my %params = @_;

  my $lb    = $self->{'-lb_av'};

  my ($crnr, $cpspe, $cpslfd);
  my @ausl  = ();

  my $i;
  @ausl = $lb->selectionGet();
  if ($#ausl < 0)
  {
    return;
  }

  $i = $ausl[0];
  $crnr   = $lb->infoData($i)->{'-crnr'};
  $cpspe  = $lb->infoData($i)->{'-cpspe'};
  $cpslfd = $lb->infoData($i)->{'-cpslfd'};

  $self->{'-crnr'}   = $crnr;
  $self->{'-cpspe'}  = $cpspe;
  $self->{'-cpslfd'} = $cpslfd;

  $self->db_chps01_select();

#print "in lb_av_auswahl:$self->{'-crnr'}-$self->{'-cpspe'}-$self->{'-cpslfd'}-$self->{'-txlfd_av'}-$self->{'-cpop'}-$self->{'-cpsbv'}-$self->{'-cpsbb'}-$self->{'-cpsbt'}-$self->{'-cpdmae'}-$self->{'-cpfart'}-$self->{'-ipcknz'}\n";

			# Text zu txlfd_av holen (Bezeichnung der AV-Methode)
	$self->{'-wertt'} = $self->{'-txlfd_av'};
	$self->text_anfot_ein();

  $self->av_anzeige_fuellen();
}

# Listbox AV-Methoden leeren ---------------------------------------------------
sub lb_av_leeren
{
  my $self = shift;

  my $lb   = $self->{'-lb_av'};

  $lb->delete('all');
  $lb->selectionClear();
  $lb->anchorClear();
}

# Anzeigefelder leeren (Spezifikationseigenschaften) ---------------------------
sub spez_anzeige_leeren
{
  my $self = shift;

  #$self->{'-crnr'} = "";
  $self->{'-cpspe'}        = "";
  $self->{'-txlfd'}        = "";
  $self->{'-cparnr'}       = "";
  $self->{'-k0'}           = "";
  $self->{'-speh'}         = "";
  $self->{'-sphkz'}        = "";
  $self->{'-spina'}        = "";
  $self->{'-spsta'}        = "";
  $self->{'-cpspe_name1'}  = "";
  #$self->{'-cparnr_name1'} = "";
  $self->{'-k0_name1'}     = "";
}

# Anzeigefelder füllen (Spezifikationseigenschaften) ---------------------------
sub spez_anzeige_fuellen
{
	my $self = shift;

  			# fügt nur Spezifikations-Name1 und Kundenname1 ein
	$self->{'-k0_name1'}     = "";
	$self->k0_ein();
  $self->{'-cpspe_name1'}  = "";
  $self->cpspe_ein();
  $self->{'-ursprl'}       = "";
  $self->ursprl_holen();
}

# Lieferposition stornieren ----------------------------------------------------
sub spez_storno
{
  my $self = shift;
  my $antwort;

  $antwort = $self->{'-ob_mbyn'}->get(-title => "ACHTUNG - Storno",
				        -text  => "Spezifikation $self->{'-cpspe'} wird storniert",
				        -icon  => 'info');
	if ($antwort == 1)
	{
  	$self->db_chps00_delete();
	}
}

# Spezifikation speichern ------------------------------------------------------
sub spez_speichern
{
  my $self = shift;

  my $crnr   = $self->{'-crnr'};
  my $cpspe  = $self->{'-cpspe'};
  my $cpid   = $self->{'-cpid'};
  my $cpdat  = $self->{'-cpdat'};
  my $cparnr = $self->{'-e_cparnr'}->get();
  my $k0     = $self->{'-k0'};
  my $ursprl = $self->{'-ursprl'};
  my $speh   = $self->{'-speh'};
  my $sphkz  = $self->{'-sphkz'};
  my $spina  = $self->{'-spina'};
  my $spsta  = $self->{'-spsta'};

  my $dbh  = $self->{'-dbh'};
  my ($sql, $sth);
  my $antwort;

  			# prüfen, ob Produkt- und Spezifikationsnummer eingegeben ist
  if ($crnr eq "")
  {
    $self->{'-ob_mbyn'}->get(-title => "Achtung",
				        -text  => "Bitte eine Produktnummer eingeben",
				        -icon  => 'warning');
    $self->{'-e_crnr'}->focus();
    $self->helbzeile();
  }
  elsif ($cpspe eq "")
  {
    $self->{'-ob_mbyn'}->get(-title => "Achtung",
				        -text  => "Bitte eine Spezifikationsnummer eingeben",
				        -icon  => 'warning');
    $self->{'-e_cpspe'}->focus();
    $self->helbzeile();
  }
  else
  {
    print "spez_speichern: vor cpspe_ein()\n";
  	$self->cpspe_ein();
  				# Vorsichts-Abfrage
	  $antwort = $self->{'-ob_mbyn'}->get(-title => "ACHTUNG - Speichern",
	                -text  => "Änderungen der Spezifikation $self->{'-cpspe'} werden gespeichert",
	                -icon  => 'info');
	  if ($antwort == 1)
	  {
	          # prüfen, ob speichern neu, oder Datensatz aktualisieren
	    $sql = qq{ select *
	               from   CHPS00
	               where  CRNR  = '$crnr'
	               and    CPSPE = '$cpspe'
	               };
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    my $anz = 0;
	    while (my @zeile = $sth->fetchrow_array())
	    {
	      ++$anz;
	    }
	    $sth->finish();

	    if ($anz == 0)
	    {
	      $sql = qq{ insert into CHPS00
	          (CRNR, CPSPE, CPID, CPDAT, CPARNR, K0, URSPRL, SPEH, SPHKZ, SPINA, SPSTA) values
	          ('$crnr','$cpspe','$cpid','$cpdat','$cparnr','$k0','$ursprl','$speh','$sphkz','$spina','$spsta')
	                };
	      $sth = $dbh->prepare($sql);
	      $sth->execute();
	      $sth->finish();
	      print "spez_speichern: Spezif. neu angelegt ???\n";
	    }
	    else
	    {
	      $sql = qq{update CHPS00
	          set CPID   = '$cpid',
	              CPDAT  = '$cpdat',
	              CPARNR = '$cparnr',
	              K0     = '$k0',
	              URSPRL = '$ursprl',
	              SPEH   = '$speh',
	              SPHKZ  = '$sphkz',
	              SPINA  = '$spina',
	              SPSTA  = '$spsta'
	          where CRNR='$crnr'
	          and CPSPE='$cpspe'
	                 };
	      $sth = $dbh->prepare($sql);
	      $sth->execute();
	      $sth->finish();
	      print "spez_speichern: Spezif. abgeändert ???\n";
	    }
	  }
	}
}

# AV-Methoden-Anzeigeframe füllen ----------------------------------------------
sub av_anzeige_fuellen
{
	my $self = shift;

	$self->{'-cpsbv'} = sprintf("%.2f", $self->{'-cpsbv'});
	$self->{'-cpsbb'} = sprintf("%.2f", $self->{'-cpsbb'});
}

# AV-Methoden-Anzeigeframe leeren ----------------------------------------------
sub av_anzeige_leeren
{
	my $self = shift;

  $self->{'-cpslfd'}   = "";
  $self->{'-txlfd_av'} = "";
  $self->{'-cpop'}     = "";
  $self->{'-cpsbv'}    = "";
  $self->{'-cpsbb'}    = "";
  $self->{'-cpsbt'}    = "";
  $self->{'-cpdmae'}   = "";
  $self->{'-cpfart'}   = "";
  $self->{'-ipcknz'}   = "";
}

# AV-Methode speichern ---------------------------------------------------------
sub av_speichern
{
  my $self = shift;

  my $crnr     = $self->{'-crnr'};
  my $cpspe    = $self->{'-cpspe'};
  my $cpslfd   = $self->{'-cpslfd'};
  #my $txlfd_av = $self->{'-txlfd_av'};
  my $cpop     = $self->{'-cpop'};
  my $cpsbv    = $self->{'-cpsbv'};
  my $cpsbb    = $self->{'-cpsbb'};
  my $cpsbt    = $self->{'-cpsbt'};
  my $cpdmae   = $self->{'-cpdmae'};
  my $cpfart   = $self->{'-cpfart'};
  my $ipcknz   = $self->{'-ipcknz'};

  my $dbh  = $self->{'-dbh'};
  my ($sql, $sth);
  my $antwort;

  			# prüfen, ob Produkt- und Spezifikations- und lfd. Nummer da ist
  if ($crnr eq "")
  {
    $self->{'-ob_mbyn'}->get(-title => "Achtung",
				        -text  => "Bitte eine Produktnummer eingeben",
				        -icon  => 'warning');
    $self->{'-e_crnr'}->focus();
    $self->helbzeile();
  }
  elsif ($cpspe eq "")
  {
    $self->{'-ob_mbyn'}->get(-title => "Achtung",
				        -text  => "Bitte eine Spezifikationsnummer eingeben",
				        -icon  => 'warning');
    $self->{'-e_cpspe'}->focus();
    $self->helbzeile();
  }
  elsif ($cpslfd eq "")
  {
    $self->{'-ob_mbyn'}->get(-title => "Achtung",
				        -text  => "Bitte eine AV-Methode auswählen",
				        -icon  => 'warning');
  }
  else
  {
  	$self->cpspe_ein();

	  			# prüfen, ob speichern neu, oder Datensatz aktualisieren
	  $sql = qq{ select *
	             from   CHPS01
	             where  CRNR   = '$crnr'
	             and    CPSPE  = '$cpspe'
	             and    CPSLFD = '$cpslfd'
	         	};
	  $sth = $dbh->prepare($sql);
	  $sth->execute();
	  my $anz = 0;
	  while (my @zeile = $sth->fetchrow_array())
	  {
	  	++$anz;
	  }
	  $sth->finish();

      		# Neu anlegen
	  if ($anz == 0)
	  {
  				# Vorsichts-Abfrage
	  	$antwort = $self->{'-ob_mbyn'}->get(-title => "ACHTUNG - Speichern",
	                -text  => "Neue AV-Methode wird angelegt",
	                -icon  => 'info');

	    if ($antwort == 1)
      {
	      $sql = qq{ insert into CHPS01
	          (CRNR,     CPSPE,   CPSLFD,   CPOP,   CPSBV,   CPSBB,   CPSBT,   CPDMAE,   CPFART,   IPCKNZ) values
	          ('$crnr','$cpspe','$cpslfd','$cpop','$cpsbv','$cpsbb','$cpsbt','$cpdmae','$cpfart','$ipcknz')
	                };
	      $sth = $dbh->prepare($sql);
	      $sth->execute();
	      $sth->finish();
	    }
    }

      		# Datensatz aktualisieren
	  else
	  {
  				# Vorsichts-Abfrage
	  	$antwort = $self->{'-ob_mbyn'}->get(-title => "ACHTUNG - Speichern",
	                -text  => "Änderungen der AV-Methode werden gespeichert",
	                -icon  => 'info');

	    if ($antwort == 1)
	    {
	    	$sql = qq{update CHPS01
	            set CPOP   = '$cpop',
	                CPSBV  = '$cpsbv',
	                CPSBB  = '$cpsbb',
	                CPSBT  = '$cpsbt',
	                CPDMAE = '$cpdmae',
	                CPFART = '$cpfart',
	                IPCKNZ = '$ipcknz'
	            where CRNR = '$crnr'
	            and CPSPE  = '$cpspe'
	            and CPSLFD = '$cpslfd'
	                };

	      $sth = $dbh->prepare($sql);
	      $sth->execute();
	      $sth->finish();
	    }
	  }
	}
}

# AV-Methode Neu anlegen -------------------------------------------------------
sub av_neu
{
  my $self = shift;

  my $crnr   = $self->{'-crnr'};
  my $cpspe  = $self->{'-cpspe'};
  my $cpslfd = $self->{'-cpslfd'};
  my $dbh    = $self->{'-dbh'};
  my ($sql, $sth);
  my $antwort;

			 # eine sinnlose Abfrage
	$antwort = $self->{'-ob_mbok'}->get(-title => "Neue AV-Methode",
	                -text  => "Bitte die Werte für die neue\nAV-Methode eingeben",
	                -icon  => 'info');

  			# AV-Methoden-Anzeige leeren
  $self->av_anzeige_leeren();

  			# erste freie lfdNr. ermitteln
	if (defined($dbh))
	  {
	    $sql = qq{ select   CPSLFD
	               from     CHPS01
	               where    CRNR  = '$crnr'
	                 and    CPSPE = '$cpspe'
	               order by CPSLFD};
	    $sth = $dbh->prepare($sql);
	    $sth->execute();
	    my $anz = 0;
	    while (my @z = $sth->fetchrow_array())
	    {
	      ++$anz;
	      $cpslfd = $z[0];
	    }
	    $anz = $anz + 1;
	    $anz = sprintf("%010d", $anz);
	    $sth->finish();
	    $cpslfd = $anz;
	  }
	  $self->{'-cpslfd'} = $cpslfd;
	  $self->{'-e_txlfd'}->focus();
}

# Text zu txlfd_av holen aus CHPTX01 -------------------------------------------
sub text_av_holen
{
	my $self   = shift;
	my %params = @_;

  my $txlfd_av = $params{-txlfd_av};
  my $text;

  my $dbh = $self->{'-dbh'};
  my ($sql, $sth);

  if (defined($dbh))
  {
  	$sql = qq{ select CHTX1D
  						 from   CHTX01
  						 where  TXLFD = '$txlfd_av'
  						 and    TXKNZ = '00001'
  						 };
  	$sth = $dbh->prepare($sql);
  	$sth->execute();
    $text = $sth->fetchrow_array();
  	$sth->finish();
  }
	return $text;
}

# Textsuche starten ------------------------------------------------------------
sub txlfd_suche
{
	my $self = shift;

  my $crnr;
  my $chptx_obj = $self->{'-chptx_obj'};
  my $txlfd     = $self->{'-txlfd'};

  if (!$chptx_obj->exist())
  {
    $chptx_obj->suche(-kennz => "speztext",
    									-suchkrit  => "Text-Nr");
    $chptx_obj->warten();
    $txlfd = $chptx_obj->get();
    if (defined($txlfd))
    {
      $self->{'-txlfd'} = $txlfd;
    }
  }
}

# lese Spezifikationsdaten aus CHPS00 ------------------------------------------
sub db_chps00_select
{
	my $self  = shift;

	my $dbh = $self->{'-dbh'};
	my ($sql, $sth);
	my $crnr  = $self->{'-crnr'};
	my $cpspe = $self->{'-cpspe'};

  if (defined($dbh))
  {
		$sql = qq{ select   CRNR,CPSPE,TXLFD,CPARNR,K0,SPEH,SPHKZ,SPINA,SPSTA
							 from     CHPS00
							 where    CRNR  = '$crnr'
								 and    CPSPE = '$cpspe'
					 		};
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while (my @z = $sth->fetchrow_array())
		{
			$self->{'-crnr'}   = $z[0];
			$self->{'-cpspe'}  = $z[1];
			$self->{'-txlfd'}  = $z[2];
			$self->{'-cparnr'} = $z[3];
			$self->{'-k0'}     = $z[4];
			$self->{'-speh'}   = $z[5];
			$self->{'-sphkz'}  = $z[6];
			$self->{'-spina'}  = $z[7];
			$self->{'-spsta'}  = $z[8];
		}
		$sth->finish();
	}
}

# eine Spezifikation aus DB CHPS00 löschen -------------------------------------
sub db_chps00_delete
{
	my $self = shift;

  my $crnr  = $self->{'-crnr'};
  my $cpspe = $self->{'-cpspe'};
	my $dbh   = $self->{'-dbh'};
	my ($sql, $sth);

	$sql = qq{ delete from CHPS00
						 where       CRNR  = '$crnr'
						 and         CPSPE = '$cpspe'
						 };
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish();
 print "Spezifikation $cpspe gelöscht. ???\n";
}

# lese AV-Methoden-Daten aus CHPS01 --------------------------------------------
sub db_chps01_select
{
  my $self   = shift;

  my $dbh   = $self->{'-dbh'};
  my ($sql, $sth);

  my $crnr   = $self->{'-crnr'};
  my $cpspe  = $self->{'-cpspe'};
  my $cpslfd = $self->{'-cpslfd'};

  if (defined($dbh))
  {
		$sql = qq{
				select CRNR, CPSPE, CPSLFD, TXLFD, CPOP, CPSBV, CPSBB, CPSBT, CPDMAE, CPFART, IPCKNZ
				from   CHPS01
				where  CRNR   = '$crnr'
				and    CPSPE  = '$cpspe'
				and    CPSLFD = '$cpslfd'
					 		};
		$sth = $dbh->prepare($sql);
		$sth->execute();
		while (my @z = $sth->fetchrow_array())
		{
			$self->{'-crnr'}     = $z[0];
			$self->{'-cpspe'}    = $z[1];
			$self->{'-cpslfd'}   = $z[2];
			$self->{'-txlfd_av'} = $z[3];
			$self->{'-cpop'}     = $z[4];
			$self->{'-cpsbv'}    = $z[5];
			$self->{'-cpsbb'}    = $z[6];
			$self->{'-cpsbt'}    = $z[7];
			$self->{'-cpdmae'}   = $z[8];
			$self->{'-cpfart'}   = $z[9];
			$self->{'-ipcknz'}   = $z[10];
		}
		$sth->finish();

  }
}

# eine AV-Methode aus DB CHPS01 löschen ----------------------------------------
sub db_chps01_delete
{

}

# BIND für F1 ------------------------------------------------------------------
sub key_f1
{
	my $self = shift;

	my $ob_mbok = $self->{'-ob_mbok'};

	my $e_crnr   = $self->{'-e_crnr'};
	my $e_cpspe  = $self->{'-e_cpspe'};
	my $e_cparnr = $self->{'-e_cparnr'};
	my $e_txlfd  = $self->{'-e_txlfd'};
	my $e_k0     = $self->{'-e_k0'};
	my $e_speh   = $self->{'-e_speh'};
	my $rbtn_sphkz1 = $self->{'-rbtn_sphkz1'};
	my $rbtn_sphkz2 = $self->{'-rbtn_sphkz2'};
	my $rbtn_spina1 = $self->{'-rbtn_spina1'};
	my $rbtn_spina2 = $self->{'-rbtn_spina2'};
	my $rbtn_spsta1 = $self->{'-rbtn_spsta1'};
	my $rbtn_spsta2 = $self->{'-rbtn_spsta2'};

  my $wo = $self->{'-topwidget'}->focusCurrent();

  if ($wo == $e_crnr)
  {
	  $ob_mbok->get(-title => "Eingabe der Produkt-Nummer",
	                -text  => "Nennen Sie die Nummer des Produktes, für das Sie eine Spezifikation erfassen möchten.\nDurch Eingabe eines Fragezeichens starten Sie die erweiterte Produktsuche, wo Sie die Möglichkeit der Suche nach Produktnummer, Suchbegriff und Handelsname haben.\nDurch Eingabe eines Suchbegriffes und Auslösen mit der Taste F5 starten Sie sofort die Produktsuche nach einem Suchbegriff.",
	                -icon  => 'info');
	}
	if ($wo == $e_cpspe)
  {
	  $ob_mbok->get(-title => "Eingabe einer Spezifikations-Nummer",
	                -text  => "Nennen Sie hier die Spezifikationsnummer.\nDiese Nummer ist maximal 20-stellig und alphanumerisch.\nDurch Betätigen der Entertaste oder Taste F5 starten Sie die Suche nach schon für das eingegebene Produkt angelegten Spezifikationen.",
	                -icon  => 'info');
	}
	if ($wo == $e_cparnr)
  {
	  $ob_mbok->get(-title => "Eingabe der Artikel-Nummer",
	                -text  => "Nennen Sie hier eine beliebige, maximal 10-stellige Artikelnummer.\nDiese erscheint später beim Ausdruck des Analysezertifikates.",
	                -icon  => 'info');
	}
	if ($wo == $e_txlfd)
  {
	  $ob_mbok->get(-title => "Eingabe der Spezifikationstext-Nummer",
	                -text  => "Hier können Sie eine maximal 5-stellige Nummer eines Spezifikationstextes eingeben.\nDurch alleiniges Betätigen der Taste F5, der Entertaste oder Eingabe eines Fragezeichens starten Sie die erweiterte Suche nach Spezifikationstexten.\nDort haben Sie die Möglichkeit nach Textnummer, Suchbegriff oder Textzeile zu suchen.\nDurch Eingabe eines Suchbegriffes und Betätigen der Entertaste starten Sie sofort die Suche nach dem eingegebenen Suchbegriff.\nDurch Betätigen der Taste F7 gelangen Sie zur Neuanlage eines Spezifikationstextes.",
	                -icon  => 'info');
	}
  if ($wo == $e_k0)
  {
	  $ob_mbok->get(-title => "Eingabe der Kunden-Nummer",
	                -text  => "Nennen Sie hier die Kundennummer des Adresskunden.\nIst hier eine Kundennummer hinterlegt,kann diese Produktspezifikation nur von dafür berechtigten Bedienern ausgedruckt werden.",
	                -icon  => 'info');
	}
  if ($wo == $e_speh)
  {
	  $ob_mbok->get(-title => "Eingabe der Gesamtspezifikation",
	                -text  => "Hier können Sie die Nummer einer Gesamtspezifikation hinterlegen.\nBei Änderungen in der Spezifikation werden diese automatisch in die hier angegebene Gesamtspezifikation übertragen.",
	                -icon  => 'info');
	}
	if ($wo == $rbtn_sphkz1 || $wo == $rbtn_sphkz2)
  {
	  $ob_mbok->get(-title => "Kennzeichen Gesamtspezifikation",
	                -text  => "Hier können Sie festlegen, dass die Spezifikation eine Gesamtspezifikation ist.",
	                -icon  => 'info');
	}
	if ($wo == $rbtn_spina1 || $wo == $rbtn_spina2)
  {
	  $ob_mbok->get(-title => "Spezifikation inaktiv setzen",
	                -text  => "Wenn Sie hier ein ,,J`` eintragen, wird die Spezifikation inaktiv gesetzt und dadurch in der Suche nach Spezifikationen standardmäßig nicht mehr angezeigt.\nSie können dort durch Betätigen der Taste F3-W die Anzeige dieser Spezifikationen wieder einschalten.\nBei der Eingabe einer Spezifikationsnummer wird in einem Warnfenster darauf hingewiesen, wenn diese inaktiv gesetzt wurde.",
	                -icon  => 'info');
	}
	  if ($wo == $rbtn_spsta1 || $wo == $rbtn_spsta2)
  {
	  $ob_mbok->get(-title => "Stabilitätsprüfung",
	                -text  => "Über diesen Schalter können Sie festlegen, dass bei der Erfassung von Stabilitätsprüfungen nur diese Spezifikation verwendet werden kann.",
	                -icon  => 'info');
	}
}

# BIND für F5 ------------------------------------------------------------------
sub key_f5
{
	my $self = shift;

  my $e_crnr  = $self->{'-e_crnr'};
  my $e_cpspe = $self->{'-e_cpspe'};
  my $e_k0    = $self->{'-e_k0'};
	my $wo = $self->{'-topwidget'}->focusCurrent();

  if ($wo == $e_crnr)
  {
  	$self->spez_anzeige_leeren();
    $self->crnr_suche();
		$self->lb_spez_fuellen();
		$self->crnr_ein();
  }

	if ($wo == $e_cpspe)
	{
		$self->cpspe_suche();
		$self->db_chps00_select();
		$self->spez_anzeige_fuellen();
		$self->lb_av_fuellen();
		$self->{'-lb_av'}->focus();
		$self->helbzeile();
	}
	if ($wo == $e_k0)
	{
		$self->k0_suche();
	}
}

# Anzeige in der Helpzeile -----------------------------------------------------
sub helbzeile
{
	my $self   = shift;

  my $amhead_obj = $self->{'-amhead_obj'};
  my $e_crnr     = $self->{'-e_crnr'};
  my $wo = $self->{'-topwidget'}->focusCurrent();

  if (defined($wo))
  {
	  if (defined($self->{'-e_crnr'}) and $wo == $self->{'-e_crnr'})
	  {
	    $amhead_obj->help_show(-text => "Produktnummer eingeben   ---ODER---   F5=Produktsuche   ---ODER---   F1=Hilfe");
	  }
	  if (defined($self->{'-e_cpspe'}) and $wo == $self->{'-e_cpspe'})
	  {
	    $amhead_obj->help_show(-text => "Spezifikationsnummer eingeben   ---ODER---   F5=Produktsuche   ---ODER---   F1=Hilfe");
	  }
	  if (defined($self->{'-e_txlfd'}) and  $wo == $self->{'-e_txlfd'})
	  {
	    $amhead_obj->help_show(-text => "Textnummer vüf vorhandenen Text eingeben   ---ODER---   F5=Produktsuche   ---ODER---   F1=Hilfe");
	  }
	  if (defined($self->{'-e_cparnr'}) and $wo == $self->{'-e_cparnr'})
	  {
	    $amhead_obj->help_show(-text => "Irgendeine Artikelnummer eingeben   ---ODER---   F1=Hilfe");
	  }
	  if (defined($self->{'-e_k0'}) and $wo == $self->{'-e_k0'})
	  {
	    $amhead_obj->help_show(-text => "Kundennummer eingeben   ---ODER---   F5=Produktsuche   ---ODER---   F1=Hilfe");
	  }
	  if (defined($self->{'-e_speh'}) and $wo == $self->{'-e_speh'})
	  {
	    $amhead_obj->help_show(-text => "Nummer für Gesamtspezifikation eingeben, falls erforderlich   ---ODER---   F1=Hilfe");
	  }
	}
}

# Setzen Datum Von Bis --------------------------------------------------------
sub datum_umformen
{
  my $self   = shift;
  my %params = @_;

  my $datum      = $params{'-datum'};
  my $datumf_obj = $self->{'-datumf_obj'};
	my $datumausgabe;

  $datumausgabe = $self->{'-datumf_obj'}->umform(-wert => $datum);

  return $datumausgabe;
}

# Ablauf (verschiedene Programmablauf-Stellen) ---------------------------------
sub ablauf
{
	my $self   = shift;
  my %params = @_;

  my $knz = $params{-knz};
  my $lb_spez    = $self->{'-lb_spez'};
  my $amhead_obj = $self->{'-amhead_obj'};

  if ($knz eq "start")
  {
    $self->lb_spez_leeren();
    $self->lb_av_leeren();
    $self->spez_anzeige_leeren();
    $self->{'-crnr'}       = "";
    $self->{'-crnr_name1'} = "";
    $self->{'-e_crnr'}->focus();
    $self->helbzeile();
  }

  if ($knz eq "spezneu")
  {
	  $self->spez_anzeige_leeren();
	  $self->lb_av_leeren();
	  $lb_spez->selectionClear();
	  $lb_spez->anchorClear();
	  $self->{'-e_cpspe'}->focus();
	  $self->helbzeile();
  }
}

# Beenden ----------------------------------------------------------------------
sub ende
{
  my $self    = shift;
  my %params = @_;

  my $antwort;
  my $knz = $params{-knz};

  if (!defined($knz) or $knz != 1)
  {
    $knz = 0;
  }

  if ($knz == 0)
  {
    $antwort = $self->{'-ob_mbyn'}->get(-title => "Produktspezifikationen erfassen / ändern",
				        -text  => "Eingabe beenden ?",
				        -icon  => 'question');
  }
  else
  {
    $antwort = 1;
  }

  if ($antwort == 1)
  {
    $self->{'-topwidget'}->destroy();
    $self->{'-topwidget'} = undef;
    if ($self->{'-steuer'} == 1)
    {
      $self->{'-pwidget'}->destroy();
    }
    $self->{'-exists'} = undef;
  }
}

1;
