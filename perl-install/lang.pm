package lang; # $Id$

use diagnostics;
use strict;

#-######################################################################################
#- misc imports
#-######################################################################################
use common qw(:common :file :system);
use commands;
use log;

#-######################################################################################
#- Globals
#-######################################################################################
#- key (to be used in $LC_ALL), [0] = english name, [1] = charset encoding,
#- [2] = value for $LANG, [3] = value for LANGUAGE (a list of possible
#- languages, carefully choosen)
#-
#- when adding a new language here, also add a line in kleyboards list
my %languages = (
'en_US' => [ 'English|United States',	'iso-8859-1', 'en', 'en_US:en' ],
'en_GB' => [ 'English|United Kingdom',	'iso-8859-1', 'en', 'en_GB:en' ],
  'af'  => [ 'Afrikaans',		'iso-8859-1', 'af', 'af:en_ZA' ],
  'ar'  => [ 'Arabic',			'iso-8859-6', 'ar', 'ar' ],
  'az'  => [ 'Azeri (Latin)',		'iso-8859-9e','az', 'az:tr' ],
#-'a3'  => [ 'Azeri|Cyrillic',		'koi8-c',     'a3', 'a3' ],
  'be'  => [ 'Belarussian',		 'cp1251',    'be', 'be:be_BY.CP1251:ru_RU.CP1251' ],
#- provide aliases for some not very standard names used in po files...
  'bg'  => [ 'Bulgarian',		'cp1251',     'bg', 'bg:bg.CP1251:bg_BG.CP1251:bg_BG' ],
  'br'  => [ 'Brezhoneg',		'iso-8859-1', 'br', 'br:fr_FR:fr' ],
  'bs'  => [ 'Bosnian',			'iso-8859-2', 'bs', 'bs:hr:sr' ],
  'ca'  => [ 'Catalan',			'iso-8859-1', 'ca', 'ca:es_ES:es:fr_FR:fr' ],
  'cs'  => [ 'Czech',			'iso-8859-2', 'cs', 'cs' ],
  'cy'  => [ 'Cymraeg (Welsh)',		'iso-8859-14','cy', 'cy:en_GB:en' ],
  'da'  => [ 'Danish',			'iso-8859-1', 'da', 'da' ],		
'de_AT' => [ 'German|Austria',		'iso-8859-1', 'de', 'de_AT:de' ],
'de_BE' => [ 'German|Belgium',		'iso-8859-1', 'de', 'de_BE:de' ],
'de_CH' => [ 'German|Switzerland',	'iso-8859-1', 'de', 'de_CH:de' ],
'de_DE' => [ 'German|Germany',		'iso-8859-1', 'de', 'de_DE:de' ],
  'el'  => [ 'Greek',                   'iso-8859-7', 'el', 'el' ],
  'eo'  => [ 'Esperanto',		'iso-8859-3', 'eo', 'eo' ],
'es_AR' => [ 'Spanish|Argentina',	'iso-8859-1', 'es', 'es_AR:es_UY:es:es_ES' ],
'es_ES' => [ 'Spanish|Spain (modern sorting)',	'iso-8859-1', 'es', 'es_ES:es' ],
'es@tradicional' => [ 'Spanish|Spain (traditional sorting)', 'iso-8859-1', 'es', 'es' ],
'es_MX' => [ 'Spanish|Mexico',	'iso-8859-1', 'es', 'es_MX:es:es_ES' ],
  'et'  => [ 'Estonian',		'iso-8859-15','et', 'et' ],
  'eu'  => [ 'Euskara (Basque)',	'iso-8859-1', 'eu', 'eu:es_ES:fr_FR:es:fr' ],
  'fa'  => [ 'Farsi (Iranian)',		'isiri-3342', 'fa', 'fa' ],
  'fi'  => [ 'Finnish (Suomi)',		'iso-8859-15', 'fi', 'fi' ],
#-'fo'  => [ 'Faroese',			'iso-8859-1', 'fo', 'fo' ],
'fr_BE' => [ 'French|Belgium',		'iso-8859-1', 'fr', 'fr_BE:fr' ],
'fr_CA' => [ 'French|Canada',		'iso-8859-1', 'fr', 'fr_CA:fr' ],
'fr_CH' => [ 'French|Switzerland',	'iso-8859-1', 'fr', 'fr_CH:fr' ],
'fr_FR' => [ 'French|France',		'iso-8859-1', 'fr', 'fr_FR:fr' ],
  'ga'  => [ 'Gaeilge (Irish)',		'iso-8859-14','ga', 'ga:en_IE:en' ],
#-'gd'  => [ 'Scottish gaelic',		'iso-8859-14','gd', 'gd:en_GB:en' ],
  'gl'  => [ 'Galego (Galician)',	'iso-8859-1', 'gl', 'gl:es_ES:pt_PT:pt_BR:es:pt' ],
#-'gv'	=> [ 'Manx gaelic',		'iso-8859-14','gv', 'gv:en_GB:en' ],
#- 'iw' was the old code for hebrew language
  'he'  => [ 'Hebrew',			'iso-8859-8', 'he', 'he:iw_IL' ],
  'hr'  => [ 'Croatian',		'iso-8859-2', 'hr', 'hr' ],
  'hu'  => [ 'Hungarian', 		'iso-8859-2', 'hu', 'hu' ],
  'hy'  => [ 'Armenian',                'armscii-8',  'hy', 'hy' ],
#- 'in' was the old code for indonesian language; by putting LANGUAGE=id:in_ID
#- we catch the few catalog files still using the wrong code
  'id'  => [ 'Indonesian',		'iso-8859-1', 'id', 'id:in_ID' ],
  'is'  => [ 'Icelandic', 		'iso-8859-1', 'is', 'is' ],
'it_CH' => [ 'Italian|Switzerland',	'iso-8859-1', 'it', 'it_IT:it' ],
'it_IT' => [ 'Italian|Italy',  		'iso-8859-1', 'it', 'it_IT:it' ],
  'ja'  => [ 'Japanese',		'jisx0208',   'ja', 'ja_JP.ujis:ja' ],
  'ka'  => [ 'Georgian',                'georgian-ps','ka', 'ka' ],
  'kl'  => [ 'Greenlandic (inuit)',	'iso-8859-1', 'kl', 'kl' ],
  'ko'  => [ 'Korean',                  'ksc5601',    'ko', 'ko' ],
#-'kw'	=> [ 'Cornish gaelic',		'iso-8859-14','kw', 'kw:en_GB:en' ],
#-'lo'  => [ 'Laotian',			'mulelao-1',  'lo', 'lo' ],
  'lt'  => [ 'Lithuanian',		'iso-8859-13','lt', 'lt' ],
  'lv'  => [ 'Latvian',			'iso-8859-13','lv', 'lv' ],   
  'mi'	=> [ 'Maori',			'iso-8859-13','mi', 'mi' ],
  'mk'  => [ 'Macedonian (Cyrillic)',	'iso-8859-5', 'mk', 'mk' ],
#-'ms'  => [ 'Malay',			'iso-8859-1', 'ms', 'ms' ],
'nl_BE' => [ 'Dutch|Belgium',		'iso-8859-1', 'nl', 'nl_NL:nl' ],
'nl_NL' => [ 'Dutch|Netherlands',	'iso-8859-1', 'nl', 'nl_NL:nl' ],
# 'nb' is the new locale name in glibc 2.2
  'no'  => [ 'Norwegian|Bokmaal',	'iso-8859-1', 'no', 'no:nb:nn:no@nynorsk:no_NY' ],
# no_NY is used by KDE (but not standard); 'nn' is the new locale in glibc 2.2
  'nn'	=> [ 'Norwegian|Nynorsk','iso-8859-1', 'no', 'nn:no@nynorsk:no_NY:no:nb' ],
#-'oc'  => [ 'Occitan',			'iso-8859-1', 'oc', 'oc:fr_FR' ],
#-'pd'	=> [ 'Plauttdietsch',		'iso-8859-1', 'pd', 'pd' ],
#-'ph'  => [ 'Pilipino',		'iso-8859-1', 'ph', 'ph:tl' ],
  'pl'  => [ 'Polish',			'iso-8859-2', 'pl', 'pl' ],
#-'pp'	=> [ 'Papiamento',		'iso-8859-1', 'pp', 'pp' ],
'pt_BR' => [ 'Portuguese|Brazil',	'iso-8859-1', 'pt_BR', 'pt_BR:pt_PT:pt' ],
'pt_PT' => [ 'Portuguese|Portugal',	'iso-8859-1', 'pt', 'pt_PT:pt:pt_BR' ],
  'ro'  => [ 'Romanian',  		'iso-8859-2', 'ro', 'ro' ],
'ru_RU.KOI8-R' => [ 'Russian|KOI8-R',	'koi8-r',     'ru', 'ru_RU.KOI8-R:ru' ],
'ru_RU.CP1251' => [ 'Russian|CP1251',	'cp1251',     'ru', 'ru_RU.CP1251:ru' ],
  'sk'  => [ 'Slovak',    		'iso-8859-2', 'sk', 'sk' ],
  'sl'  => [ 'Slovenian',		'iso-8859-2', 'sl', 'sl' ],
  'sp'  => [ 'Serbian|Cyrillic',	'iso-8859-5', 'sp', 'sp:sr' ],
  'sr'  => [ 'Serbian|Latin',		'iso-8859-2', 'sr', 'sr' ],
  'sv'  => [ 'Swedish',			'iso-8859-1', 'sv', 'sv' ],
  'ta'	=> [ 'Tamil',			'tscii-0',    'ta', 'ta' ],
  'tg'	=> [ 'Tajik',			'koi8-c',     'tg', 'tg' ],
  'th'  => [ 'Thai',                    'tis620',     'th', 'th' ],
  'tr'  => [ 'Turkish',	 		'iso-8859-9', 'tr', 'tr' ],
  'tt'	=> [ 'Tatar',			'tatar-cyr',  'tg', 'tg' ],
#-'ur'	=> [ 'Urdu',			'cp1256',     'ur', 'ur' ],  
'uk_UA' => [ 'Ukrainian', 		'koi8-u',     'uk', 'uk_UA:uk' ],
  'uz'  => [ 'Uzbek',			'iso-8859-1', 'uz', 'uz' ],
  'vi'  => [ 'Vietnamese|TCVN',       'tcvn',       'vi',
					'vi_VN.TCVN:vi_VN.TCVN-5712:vi_VN.tcvn:vi' ],
'vi_VN.VISCII' => [ 'Vietnamese|VISCII','viscii',   'vi',
				        'vi_VN.VISCII:vi_VN.viscii:vi' ],
  'wa'  => [ 'Walon',     		'iso-8859-1', 'wa', 'wa:fr_BE:fr' ],
#-'yi'	=> [ 'Yiddish',			'cp1255',     'yi', 'yi' ],
'zh_TW.Big5' => [ 'Chinese|Traditional',     'Big5', 'zh_TW.Big5', 'zh_TW.Big5:zh_TW.big5:zh_TW:zh' ],
'zh_CN.GB2312' => [ 'Chinese|Simplified',	'gb2312', 'zh_CN.GB2312', 'zh_CN.GB2312:zh_CN.gb2312:zh_CN:zh' ],
);

my %xim = (
  'zh_TW.Big5' => { 
	ENC => 'big5',
	XIM => 'xcin',
	XIM_PROGRAM => 'xcin',
	XMODIFIERS => '"@im=xcin"',
	CONSOLE_NOT_LOCALIZED => 'yes',
  },
  'zh_CN.GB2312' => {
	ENC => 'gb',
	XIM => 'xcin-zh_CN.GB2312',
	XIM_PROGRAM => 'xcin',
	XMODIFIERS => '"@im=xcin-zh_CN.GB2312"',
	CONSOLE_NOT_LOCALIZED => 'yes',
  },
  'ko' => {
	ENC => 'kr',
	XIM => 'Ami',
	XIM_PROGRAM => 'ami',
	XMODIFIERS => '"@im=Ami"',
	CONSOLE_NOT_LOCALIZED => 'yes',
  },
  'ja' => {
	ENC => 'eucj',
	XIM => 'kinput2',
	XIM_PROGRAM => 'kinput2',
	XMODIFIERS => '"@im=kinput2"',
  },
  # xvnkb is not an XIM input method; but an input method of another
  # kind, only XIM_PROGRAM needs to be defined
  'vi' => {
	XIM_PROGRAM => 'xvnkb',
  },
  'vi_VN.TCVN' => {
	XIM_PROGRAM => 'xvnkb',
  },
  'vi_VN.VISCII' => {
	XIM_PROGRAM => 'xvnkb',
  },
  'vi_VN.UTF-8' => {
	XIM_PROGRAM => 'xvnkb',
  },
  # right to left languages only work properly on console
  'ar' => {
	X11_NOT_LOCALIZED => "yes",
  },
  'fa' => {
	X11_NOT_LOCALIZED => "yes",
  },
# KDE has some "mirrored" translations
#  'he' => {
#	X11_NOT_LOCALIZED => "yes",
#  },
  'ur' => {
	X11_NOT_LOCALIZED => "yes",
  },
  'yi' => {
	X11_NOT_LOCALIZED => "yes",
  },
);

sub std2 { "-*-*-medium-r-normal-*-$_[1]-*-*-*-*-*-$_[0]" }
sub std_ { std2($_[0], 10), std2($_[0], 10) }
sub std  { std2($_[0], $_[1] || 10), std2($_[0],  8) }

#- [0]: console font name; [1]: unicode map for console font
#- [2]: acm file for console font;
#- [3]: iocharset param for mount; [4]: codepage parameter for mount
#- [5]: X11 fontset
my %charsets = (
  "armscii-8"  => [ "arm8",		"armscii8.uni",	"trivial.trans",
    undef,	undef, std_("armscii-8") ],
#- chinese needs special console driver for text mode
  "Big5"       => [ undef,		undef,		undef,
	"big5", "950", "-*-*-*-*-*-*-*-*-*-*-*-*-big5-0" ],
  "gb2312"     => [ undef,		undef,		undef,
	"gb2312", "936", "-*-*-*-*-*-*-*-*-*-*-*-*-gb2312.1980-0" ],
  "georgian-academy" => [ "t_geors", "geors.uni",	"trivial.trans",
	undef,  undef, "-*-*-*-*-*-*-*-*-*-*-*-*-georgian-academy" ],
  "georgian-ps" => [ "t_geors",		"geors.uni",	"geors_to_geops.trans",
	undef,  undef, "-*-*-*-*-*-*-*-*-*-*-*-*-georgian-academy" ],
  "iso-8859-1" => [ "lat0-sun16",	undef,		"iso15",
	"iso8859-1", "850", sub { std("iso8859-1", @_) } ],
  "iso-8859-2" => [ "lat2-sun16",	undef,		"iso02",
	"iso8859-2", "852", sub { std("iso8859-2", @_) } ],
  "iso-8859-3" => [ "iso03.f16",	undef,		"iso03",
	"iso8859-3", undef, std_("iso8859-3") ],
  "iso-8859-4" => [ "lat4u-16",		undef,		"iso04",
	"iso8859-4", "775", std_("iso8859-4") ],
  "iso-8859-5" => [ "iso05.f16",	"iso05",	"trivial.trans",
  	"iso8859-5", "855", 
	std2("iso8859-5", 10), std2("iso8859-5",  8) ],
#-#- arabic needs special console driver for text mode [acon]
#-#- (and gtk support isn't done yet)
  "iso-8859-6" => [ "iso06.f16",	"iso06",	"trivial.trans",
    "iso8859-6", "864", std_("iso8859-6") ],
  "iso-8859-7" => [ "iso07.f16",	"iso07",	"trivial.trans",
	"iso8859-7", "869", std_("iso8859-7") ],
#-#- hebrew needs special console driver for text mode [acon]
#-#- (and gtk support isn't done yet)
   "iso-8859-8" => [ "iso08.f16",	"iso08",	"trivial.trans",
#	std_("iso8859-8") ],
	"iso8859-8", "862", std_("microsoft-cp1255") ],
  "iso-8859-9" => [ "iso09.f16",	"iso09",	"trivial.trans",
	"iso8859-9", "857", sub { std("iso8859-9", @_) } ],
  "iso-8859-13" => [ "tlat7",		"iso01",	"trivial.trans",
	"iso8859-13", "775", std_("iso8859-13") ],
  "iso-8859-14" => [ "tlat8",		"iso01",	"trivial.trans",
	"iso8859-14", "850", std_("iso8859-14") ],
  "iso-8859-15" => [ "lat0-sun16",	undef,		"iso15",
	"iso8859-15", "850", std("iso8859-15") ],
  "iso-8859-9e" => [ "tiso09e",		"iso09",	"trivial.trans",
	"iso8859-9", "857", std2("iso8859-9e",10) ],
#- japanese needs special console driver for text mode [kon2]
  "jisx0208"   => [ undef,		undef,		"trivial.trans",
	"euc-jp", "932", "-*-*-*-*-*-*-*-*-*-*-*-*-jisx*.*-0" ],
  "koi8-r"     => [ "UniCyr_8x16",	undef,		"koi8-r",
	"koi8-r", "866", std("koi8-r") ],
  "koi8-u"     => [ "UniCyr_8x16",	undef,		"koi8-u",
	"koi8-u", "866", std("koi8-u") ],
  "koi8-k"     => [ "koi8-k",		"iso01",	"trivial.trans",
	undef, undef, std("koi8-c") ],
  "tatar-cyr"  => [ "tatar-cyr",	undef,		"cp1251",
	undef, undef, std("tatar-cyr") ],
  "cp1251"     => [ "UniCyr_8x16",	undef,		"cp1251",
	"cp1251", "866", sub { std("microsoft-cp1251", @_) } ],
#- Yiddish needs special console driver for text mode [acon]
#- (and gtk support isn't done yet)
  "cp1255"     => [ "iso08.f16",        "iso08",        "trivial.trans",
	"cp1255", "862", std_("microsoft-cp1255") ],
#- Urdu needs special console driver for text mode [acon]
#- (and gtk support isn't done yet)
  "cp1256"     => [ undef,              undef,          "trivial.trans",
	undef, "864", std_("microsoft-cp1255") ],
#- korean needs special console driver for text mode
  "ksc5601"    => [ undef,		undef,		undef,
	"euc-kr", "949", "-*-*-*-*-*-*-*-*-*-*-*-*-ksc5601.1987-*" ],
#- I have no console font for Thai...
  "tis620"     => [ undef,		undef,		"trivial.trans",
	"tis-620", "874", std2("tis620.2533-1",12) ],
  "tcvn"       => [ "tcvn8x16",		"tcvn",		"trivial.trans",
	undef, undef, std2("tcvn-5712", 13), std2("tcvn-5712", 10) ],
  "viscii"     => [ "viscii10-8x16",	"viscii.uni",	"viscii1.0_to_viscii1.1.trans",
#-	"-*-*-*-*-*-*-*-*-*-*-*-*-viscii1.1-1" ],
	undef, undef, std2("tcvn-5712", 13), std2("tcvn-5712", 10) ],
#- Farsi (iranian) needs special console driver for text mode [acon]
#- (and gtk support isn't done yet)
  "isiri-3342" => [ undef,		undef,		"trivial.trans",
	undef, undef, "-*-*-*-*-*-*-*-*-*-*-*-*-isiri-3342" ],
  "tscii-0" => [ "tamil",		undef,		"trivial.trans",
	undef, undef, "-*-*-*-*-*-*-*-*-*-*-*-*-tscii-0" ],
  "unicode" => [ undef,			undef,		"trivial.trans",
	"utf8", undef, "-*-*-*-*-*-*-*-*-*-*-*-*-iso10646-1" ],
);

#-######################################################################################
#- Functions
#-######################################################################################

sub list { keys %languages }
sub lang2text     { $languages{$_[0]} && $languages{$_[0]}[0] }
sub lang2charset  { $languages{$_[0]} && $languages{$_[0]}[1] }
sub lang2LANG     { $languages{$_[0]} && $languages{$_[0]}[2] }
sub lang2LANGUAGE { $languages{$_[0]} && $languages{$_[0]}[3] }
sub getxim { $xim{$_[0]} }

sub set { 
    my ($lang) = @_;

    if ($lang && $languages{$lang}) {
	#- use "packdrake -x" that follow symlinks and expand directory.
	#- it is necessary as there is a lot of symlinks inside locale.cz2,
	#- using a compressed cpio archive is nighmare to extract all files.
	#- reset locale environment variable to avoid any warnings by perl,
	#- so installation of new locale is done with empty locale ...
	unless (-e "$ENV{SHARE_PATH}/locale/$languages{$lang}[2]") {
	    @ENV{qw(LANG LC_ALL LANGUAGE LINGUAS)} = ();

	    eval { commands::rm("-r", "$ENV{SHARE_PATH}/locale") };
	    eval {
		require packdrake;
		my $packer = new packdrake("$ENV{SHARE_PATH}/locale.cz2");
		$packer->extract_archive("$ENV{SHARE_PATH}/locale", "UTF-8", $languages{$lang}[2]);
	    };
	    #require 'run_program.pm';
	    #run_program::run("packdrake", "-x", "$ENV{SHARE_PATH}/locale.cz2", "$ENV{SHARE_PATH}/locale", "UTF-8");
	    #run_program::run("packdrake", "-x", "$ENV{SHARE_PATH}/locale.cz2", "$ENV{SHARE_PATH}/locale", $languages{$lang}[2]);
	}

#- set all LC_* variables to a unique locale ("C"), and only redefine
#- LC_CTYPE (for X11 choosing the fontset) and LANGUAGE (for the po files)
	$ENV{LC_NUMERIC}		= "C";
	$ENV{LC_TIME}			= "C";
	$ENV{LC_COLLATE}		= "C";
	$ENV{LC_MONETARY}		= "C";
	$ENV{LC_MESSAGES}		= "C";
	$ENV{LC_PAPER}			= "C";
	$ENV{LC_NAME}			= "C";
	$ENV{LC_ADDRESS}		= "C";
	$ENV{LC_TELEPHONE}		= "C";
	$ENV{LC_MEASUREMENT}	= "C";
	$ENV{LC_IDENTIFICATION}	= "C";

	$ENV{LC_CTYPE}  = $lang;
	$ENV{LANG}      = $languages{$lang}[2];
	$ENV{LANGUAGE}  = $languages{$lang}[3];

    } else {
	# stick with the default (English) */
	delete $ENV{LANG};
	delete $ENV{LC_ALL};
	delete $ENV{LANGUAGE};
	delete $ENV{LINGUAS};
    }
}

sub langs {
    my ($l) = @_;
    grep { $l->{$_} } keys %$l;
}

sub langsLANGUAGE {
    my ($l) = @_;
    my @l = $l->{all} ? list() : langs($l);
    uniq(map { split ':', $languages{$_}[3] } @l);
}

sub pack_langs { 
    my ($l) = @_; 
    $l->{all} ? 'all' : join ':', uniq(map { $languages{$_}[3] } langs($l));
}

sub write_langs {
    my ($prefix, $langs) = @_;
    my $s = pack_langs($langs);
    symlink "$prefix/etc/rpm", "/etc/rpm" if $prefix;
    substInFile { s/%_install_langs.*//; $_ .= "%_install_langs $s\n" if eof && $s } "$prefix/etc/rpm/macros";
}

sub write { 
    my ($prefix, $lang) = @_;

    $lang or return;

    my $h = {};
    $h->{$_} = $lang foreach qw(LC_COLLATE LC_CTYPE LC_MESSAGES LC_NUMERIC LC_MONETARY LC_TIME);
    if (my $l = $languages{$lang}) {
	add2hash $h, { LANG => $l->[2], LANGUAGE => $l->[3] };

	my $c = $charsets{$l->[1] || ''};
	if ($c) {
	    my $p = "$prefix/usr/lib/kbd";
	    if ($c->[0]) {
		add2hash $h, { SYSFONT => $c->[0] };
		eval {
		    commands::cp("-f",
			"$p/consolefonts/$c->[0].psf.gz",
			"$prefix/etc/sysconfig/console/consolefonts");
		};
		$@ and log::l("missing console font $c->[0]");
	    }
	    if ($c->[1]) {
		add2hash $h, { UNIMAP => $c->[1] };
		eval {
		    commands::cp("-f",
			glob_("$p/consoletrans/$c->[1]*"),
			"$prefix/etc/sysconfig/console/consoletrans");
		};
		$@ and log::l("missing console unimap file $c->[1]");
	    }
	    if ($c->[2]) {
		add2hash $h, { SYSFONTACM => $c->[2] };
		eval {
		    commands::cp("-f",
			glob_("$p/consoletrans/$c->[2]*"),
			"$prefix/etc/sysconfig/console/consoletrans");
		};
		$@ and log::l("missing console acm file $c->[2]");
	    }

	}
	add2hash $h, $xim{$lang};
    }
    setVarsInSh("$prefix/etc/sysconfig/i18n", $h);
}

sub load_po {
    my ($lang) = @_;
    my ($s, $from, $to, $state, $fuzzy);

    $s .= "package po::I18N;\n";
    $s .= "no strict;\n";
    $s .= "\%{'$lang'} = (";

    my $f; -e ($f = "$_/po/$lang.po") and last foreach @INC;

    local *F;
    my $pid;
    unless ($f && -e $f) {
	-e ($f = "$_/po/$lang.po.bz2") and last foreach @INC;
	if (-e $f) {
	    open F, "$ENV{LD_LOADER} bzip2 -dc $f 2>/dev/null |";
	} else {
	    -e ($f = "$_/po.cz2") and last foreach @INC;
	    log::l("trying to load $lang.po from $f");
	    #open F, "packdrake -x $f '' $lang.po 2>/dev/null |";
	    unless ($pid = open F, "-|") {
		eval {
		    require packdrake;
		    my $packer = new packdrake($f);
		    $packer->extract_archive(undef, "$lang.po");
		};
		c::_exit(0);
	    }
	}
    } else {
	open F, $f; #- not returning here help avoiding reading the same multiple times.
    }
    local $_;
    while (<F>) {
	/^msgstr/ and $state = 1;
	/^msgid/  && !$fuzzy and $state = 2;
	s/@/\\@/g;

	if (/^(#|$)/ && $state != 3) {
	    $state = 3;
	    if (my @l = $to =~ /%(\d+)\$/g) {
		$to =~ s/%(\d+)\$/%/g;
		$to = qq([ "$to", ) . join(",", map { $_ - 1 } @l) . " ],";
	    } else {
		$to = qq("$to");
	    }
	    $s .= qq("$from" => $to,\n) if $from;
	    $from = $to = '';
	}
	$to .= (/"(.*)"/)[0] if $state == 1;
	$from .= (/"(.*)"/)[0] if $state == 2;

	$fuzzy = /^#, fuzzy/;
    }
    $s .= ");";
    no strict "vars";
    eval $s;
    $pid and waitpid $pid, 0;
    !$@;
}


sub console_font_files {
    map { -e $_ ? $_ : "$_.gz" }
      (map { "/usr/lib/kbd/consolefonts/$_.psf" } uniq grep {$_} map { $_->[0] } values %charsets),
      (map { -e $_ ? $_ : "$_.sfm" } map { "/usr/lib/kbd/consoletrans/$_" } uniq grep {$_} map { $_->[1] } values %charsets),
      (map { -e $_ ? $_ : "$_.acm" } map { "/usr/lib/kbd/consoletrans/$_" } uniq grep {$_} map { $_->[2] } values %charsets),
}

sub load_console_font {
    my ($lang) = @_;
    my ($charset) = $languages{$lang} && $languages{$lang}[1] ;
    my ($f, $u, $m) = @{$charsets{$charset} || []};

    require run_program;
    run_program::run('consolechars', '-v',
		          ('-f', $f || 'lat0-sun16'),
		     $u ? ('-u', $u) : (),
		     $m ? ('-m', $m) : ());
}

#-sub load_font {
#-    my ($charset) = @_;
#-    my $fontFile = "lat0-sun16";
#-
#-    if (my $c = $charsets{$charset}) {
#-	   log::l("loading $charset font");
#-	   $fontFile = $c->[0];
#-    }
#-
#-    # text mode font
#-    log::l("loading font $ENV{SHARE_PATH}/consolefonts/$fontFile");
#-    #c::loadFont("/tmp/$fontFile") or log::l("error in loadFont: one of PIO_FONT PIO_UNIMAPCLR PIO_UNIMAP PIO_UNISCRNMAP failed: $!");
#-    #print STDERR "\033(K";
#-
#-}

sub get_x_fontset {
    my ($lang, $size) = @_;

    my $l = $languages{$lang}  or return;
    my $c = $charsets{$l->[1]} or return;
    my ($big, $small) = @$c[5..6];
    ($big, $small) = $big->($size) if ref $big;
    ($big, $small);
}

sub charset {
    my ($lang, $prefix) = @_;
    my $l = $languages{$lang} && $languages{$lang}[2];
    foreach (cat_("$prefix/usr/X11R6/lib/X11/locale/locale.alias")) {
	/$l:\s+.*\.(\S+)/ and return $1;
    }
    $l =~ /.*\.(\S+)/ and return $1;
}

#-######################################################################################
#- Wonderful perl :(
#-######################################################################################
1;
