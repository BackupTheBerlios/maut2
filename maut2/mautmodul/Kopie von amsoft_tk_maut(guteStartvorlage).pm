# *******************************************************************
# * Name             : amsoft_tk_maut.pm                            *
# * Erstellt am      : 21.01.2005 Thomas Weise                      *
# * Letzte Aenderung : 21.01.2005 Thomas Weise                      *
# * Beschreibung     : Maut                                         *
# *******************************************************************

require 5.000;
use strict;

package amsoft_tk_maut;

use Tk;
use Tk::DialogBox;
#use Tk::Menu;
#use Tk::ErrorDialog;
use Tk::ToolBar;
#use Tk::Tree;
#use Tk::ItemStyle;
#use Tk::Autoscroll;
#use Tk::DateEntry;
#use Tk::BrowseEntry;
#use Tk::TextUndo;
#use Tk::Balloon;
#use Tk::HList;

sub new
{
  my $classname = shift;
  my %params    = @_;

  my $self      = {};

  $self->{'-pwidget'}   = $params{-pwidget};

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

  $button_01 = $fra_butt->ToolButton(-text      => 'Leerbtn1',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->btn_01();},
                                   -width     => 8,
                                   )->pack(-side   => 'left',
                                           -fill   => 'both',
                                           -expand => 1,);

  $button_02 = $fra_butt->ToolButton(-text      => 'Leerbtn2',
                                   -type      => 'Button',
                                   -underline => 0,
                                   -command   => sub { $self->btn_02();},
                                   -width     => 8,
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

  my $frame;

  $frame  = $self->{'-fra_oben_li'};
}

# Frame oben rechts ------------------------------------------------------------
sub fra_oben_re
{
  my $self = shift;

  my $frame;

  $frame  = $self->{'-fra_oben_re'};
}

# Frame unten ------------------------------------------------------------------
sub fra_unten
{
	my $self = shift;

  my $frame;

	$frame = $self->{'-fra_unten'};
}

# Buttonfunktion 01 ------------------------------------------------------------
sub btn_01
{
	my $self = shift;
	print "in btn_01\n";
}

# Buttonfunktion 02 ------------------------------------------------------------
sub btn_02
{
	my $self = shift;
	print "in btn_02\n";
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
