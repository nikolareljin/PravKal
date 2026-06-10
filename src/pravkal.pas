{$mode tp}
{$H-}
program pravkal;
uses crt, SysUtils, nizz, kalsys1, kalmenu1, kalwork1, kaltxt;

const
  VERSION = '0.1.0';

procedure showHelp;
begin
  WriteLn('Pravoslavni Kalendar - Serbian Orthodox TUI Calendar');
  WriteLn;
  WriteLn('Usage:  pravkal [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  -h, --help     Show this help and exit');
  WriteLn('  -v, --version  Show version and exit');
  WriteLn;
  WriteLn('Controls:');
  WriteLn('  Up/Down        Scroll weeks within current month');
  WriteLn('  F3             Change month / year');
  WriteLn('  F5             Heortology viewer (feast-day texts)');
  WriteLn('  F7             Export current month to TXT (mesec_YYYY_MM.txt)');
  WriteLn('  F8             Export fasting schedule to TXT (postovi_YYYY.txt)');
  WriteLn('  F10            Drop-down menu');
  WriteLn('  Ctrl-C         Exit');
  Halt(0);
end;

procedure showVersion;
begin
  WriteLn('pravkal ' + VERSION);
  Halt(0);
end;

type
  nedstr = string[58];
  mssm_  = array[1..2] of byte;   { local alias; structurally same as nizz.mssm }

const
  { Orthodox cross for on-screen display, 9 rows }
  krst: array[1..9] of kstr = (
    '      |      ',
    '   ---|---   ',
    '|     |     |',
    '=============',
    '|     |     |',
    '      |      ',
    '      |      ',
    '      |      ',
    '   ---|---   ');

  { Menu geometry (filled into kalmenu1 vars by dodvredmoom) }
  jmmax  = 5;
  mmpos_ : array[1..jmmax] of byte = (3,9,17,27,38);
  mmpol_ : array[1..jmmax] of byte = (3,9,17,27,38);
  mmdim_ : array[1..jmmax] of mssm_ =
    ((13,1),(23,6),(21,4),(26,5),(19,2));
  mmnli_ : array[1..jmmax] of byte = (1,5,4,4,2);
  mmcrt_ : array[1..jmmax] of byte = (0,5,0,4,0);

  bmd: array[1..12] of integer = (31,28,31,30,31,30,31,31,30,31,30,31);
  dun: array[0..6] of char = 'NPUSCPS';

  { Layout driver string: 'a'=top-separator 'b'=Sunday-label 'c'=mid-separator
    digit/letter=day row.  Repeated 63-char pattern covers all week layouts. }
  tabs: array[1..63] of char =
     'abc0123456abc0123456abc0123456abc0123456abc0123456abc0123456abc';

  nedelja: array[1..19] of pathstr = (
    'Nedelja o mitaru i fariseju',
    'Nedelja o bludnom sinu',
    'Nedelja mesopusna',
    'Nedelja siropusna',
    'Nedelja prva posta - Cista Pravoslavlja',
    'Nedelja druga posta - Pacista',
    'Nedelja treca posta - Krstopoklona',
    'Nedelja cetvrta posta - Sredoposna',
    'Nedelja peta posta - Gluvna',
    'Nedelja sesta posta - Cvetna',
    'Nedelja svetla. Na lit. ap.1.Jev.Jn zac 1 /1,1-17/',
    'Nedelja druga - Tomina',
    'Nedelja treca - Mironosnica',
    'Nedelja cetvrta - Raslabljenog',
    'Nedelja peta - Samarjanke',
    'Nedelja sesta - Slepoga',
    'Nedelja sedma - Svetih Otaca',
    'Nedelja Pedesetnice',
    'Nedelja prva po Duhovima - Svih Svetih');

  brvp = 5;
  vazpr: array[1..brvp] of prstr = (
    'Blagovesti',
    'Vozdvizenje Casnog Krsta - Krstovdan',
    'Rozdestvo Presvete Bogorodice',
    'Vavedenje Presvete Bogorodice',
    'Bozic - Rozdestvo Gospoda Isusa Hrista');

  praz: array[1..12] of array[1..31] of prstr = (
    ('cJAN.- Obrez.GIHr; sv.Vasilije; N.god. ',
     'oSveta Sila i sveti Serafim Sarovski',
     'oSveti prorok Malahije i sv. mucenik Gordije',
     'oSabor svetih 70 apost.;sv.Jevstatije srpski',
     'mSv.mucenik Teopempt i Teona - Krstovdan',
     'cBogojavljenje',
     'cSabor svetog Jovana Krstitelja - Jovanjdan',
     'oPrepodobni Georgije Hozevit; sv.Grig.Ohrid.',
     'oSveti mucenik Polievkt; sv. Filip Moskovski',
     'oSveti Grigorije Niski i prep. Dometijan',
     'oPrepodobni Teodosije Veliki i prep. Mihailo',
     'oSveta mucenica Tatijana',
     'oSveti muc. Ermil i Stratonik (Odan.Bogoj.)',
     'cSveti Sava prvi arhiepiskop srpski',
     'oPrepidobni Pavle; prep. Gavrilo Lesnovski',
     'mCasne verige apostola Petra;prep.Romil Rav.',
     'oPrepodobni Antonije Veliki',
     'mSveti Atanasije Veliki; sveti Maksim Srpski',
     'oPrep. Makarije Egipatski; sv. Marko Efeski',
     'oPrepodobni Jevtimije Veliki',
     'oPrep. Maksim Ispovednik; sv.muc.Teofan',
     'oSveti apostol Timotej i prepmuc. Anastasije',
     'oSvestenomucenik Kliment Ankirski i drugi',
     'oPrepodobna Ksenija Rimljanka',
     'oSveti Grigorije Bogoslov',
     'oPrepodobni Ksenofont i Marija',
     'oPrenos mostiju svetog Jovana Zlatousta',
     'oPrepodobni Jefrem Sirin',
     'oPrenos mostiju Ignjatija Bogonosca',
     'cSveta Tri Jerarha',
     'oSveti besrebrenici Kir i Jovan'),

    ('oFEB.-Sveti mucenik Trifun (Pretpr.Sretenja)',
     'cSretenje Gospodnje',
     'mSveti Simeon i Ana; sv.Jakov arhiep. srpski',
     'oPrepodobni Isidor Pelusiot',
     'oSveta mucenica Agapija',
     'oSveti Fotije i sv.Vukol Smirn. (Odan.Sret.)',
     'oSveti Partenije Lampsakijski',
     'oSv. Teodor Stratilat; sv. Sava II srpski',
     'oSveti mucenik Nikifor',
     'mSvestenomucenik Haralampije',
     'oSvestmucenik Vlasije; sv.muc. Djordje Krat.',
     'oSveti Maletije Antiohijski',
     'oPrepodobni Simeon Mirotocivi',
     'mPrepodobni Avksentije; sv.Kiril Slovenski',
     'oSveti apostol Onisim i prep. Jevsevije',
     'oSv. muc. Pamfil i Porfirije - Zadusnice',
     'mSveti velikomucenik Teodor Tiron',
     'oSveti Lav Rimski i sv. Flavijan Carigradski',
     'oSveti apostoli Arhip, Filimon i Apfija',
     'oSveti Lav Katanski i svestenomucenik Sadok',
     'oPrepodobni Timotej i sveti Evstatije',
     'oSveti mucenici u Evgeniji',
     'oSvestenomucenik Polikarp Smirnski',
     'mI i II obr. glave svetog Jovana Krstitelja',
     'oSveti Tarasije Carigradski',
     'oSveti Porfirije episkop gaski',
     'oPrepodobni Prokopije Dekapolit',
     'oPrepodobni Vasilije Ispovednik',
     'oPrepodobni Jovan Kasijan',
     'oPrep. Vasilije Ispov. i prep. Jovan Kasijan',''),

    ('oMART- Prepodobnomucenica Evdokija',
     'oSvestenomucenik Teodot Kirinejski',
     'oSveti mucenici Evtropije,Kalinik i Vasilisk',
     'oPrepodobni Gerasim Jordanski',
     'oSveti mucenik Konon i prep. Marko Podviznik',
     'oSvetih 42 mucenika iz Amoreje',
     'oSvetih 7 svestenomucenika hersonskih',
     'oSveti Teofilakt Ispovednik',
     'mSvetih 40 mucenika sevastijskih - Mladenci',
     'oSveti mucenik Kodrat Korintski',
     'oSveti Sofronije Jerusalimski',
     'oSveti Grigorije Dvoj., prep.Teofan i Simeon',
     'oPrenos mostiju svetog Nikifora Carigradskog',
     'oPrepodobni Benedikt Nursijski',
     'oSveti mucenik Agapije',
     'oSveti Aristovul, mucenici Papa i Savin',
     'mPrepodobni Aleksije - covek Bozji',
     'oSveti Kiril Jerusalimski',
     'oSveti mucenici Hrizant, Darija i drugi',
     'oPrepmuc. Jovan, Sergije, Patrikije i drugi',
     'oPrepodobni Jovan Ispovednik',
     'oSvestenomucenik Vasilije Anhirski',
     'oPrepodobnomucenik Nikon i drugi',
     'oPrepodobni Zaharije (Pretpr. Blagovesti)',
     'cBlagovesti',
     'oSabor sv. arh. Gavrila (Odan.Blag.-I bden)',
     'oPrepodobna Matrona Solunska',
     'oPrepodobni Ilarion Novi (II bdenije)',
     'oSvestenomucenik Marko Aretuski',
     'oPrepodobni Jovan Lestvicnik',
     'oPrepodobni Ipatije Gangrijski'),

    ('oAPRIL- Prepodobna Marija Egipcanka',
     'oPrepodobni Tit Cudotvorac',
     'oPrepodobni Nikita Ispovednik',
     'oPrepodobni Josif Himnograf',
     'mMucenik Agapod',
     'oSveti Evtihije i prepodobni Grigorije',
     'oSveti Grogorije Ispovednik',
     'oSveti apostoli Irodion, Agav i drugi',
     'oSveti mucenik Evpeihije',
     'oSveti mucenik Terentije, Pompije',
     'oSvestenomucenik Antipa Pergamski',
     'oPrepodobni Vasilije Ispovednik',
     'oSvestenomucenik Artemon',
     'oSveti Matrin Ispovednik',
     'oSveti apostoli Aristarh, Trud i Trofim',
     'oSvete mucenice Agapija, Hionija i Irina',
     'oSvestenomucenik Simeon Persijski',
     'oPrepodobni Jovan',
     'oPrepodobni Jovan Vethopescernik',
     'oPrepodobni Teodor; prep. Joasaf srpski',
     'oSvestenomucenik Januarije',
     'oPrepodobni Teodor Sikeot',
     'cSveti velikomucenik Georgije - Djurdjevdan',
     'oSveti Sava Stratilat; sveti Sava Erdeljski',
     'mSveti apostol i jevandjelist Marko',
     'oSvestenomucenik Vasilije Amasijski',
     'oSpaljivanje mostiju svetog Save',
     'oSveti apostoli Jason i Sosipatr',
     'oSveti Vasilije Ostroski',
     'oSveti apostol Jakov Zevedejev',''),

    ('mMAJ- Sveti prorok Jeremija',
     'oSveti Atanasije Veliki',
     'oSveti mucenici Timotej i Mavra',
     'oSveta mucenica Pelagija Tarsijska',
     'oSveta velikomucenica Irina',
     'oPrepodob. Jovan; prenos mostiju svetog Save',
     'oPojava Casnog Krsta u Jerusalimu',
     'mSveti apostol i jevandjelist Jovan Bogoslov',
     'mPrenos mostiju svetog Nikole',
     'oSimon Zilot; prepodobna Isidora',
     'cSveti Cirilo i Metodije; Nikodim srpski',
     'oSveti Epifanije i sveti German',
     'oSveta mucenica Glikerija',
     'oSveti mucenik Isidor',
     'oPrepodobni Pahomije Veliki',
     'oPrepodobni Teodor Osveceni',
     'oSveti apostol Andronik i Julija',
     'oSveti mucenik Teodor Ankirski',
     'oSvestenomucenik Patrikije Pruski',
     'oSveti mucenik Talalej; Stefan Piperski',
     'cSveti car Konstantin i carica Jelena',
     'oSveti Jovan Vladimir',
     'oPrepodobni Mihailo Ispovednik',
     'oPrepodobni Simeon Divnogorac',
     'mTrece obretenje glave sv. Jovana Krstitelja',
     'oSveti apostol Karp',
     'oSvestenomucenik Terapont',
     'oPrepodobni Nikita Ispovednik',
     'oPrepodobnomucenica Teodosija Tirska',
     'oPrepodobni Isakije Dalmatski',
     'oSveti apostol Jerma i sveti mucenik Ermije'),

    ('oJUN- Mucenik Justin Filozof',
     'oSveti Nikifor; svestenomuc. Erazmo Ohridski',
     'oSveti mucenik Lukijan i drugi',
     'oSveti Mitrofan i sv. miron. Marta i Marija',
     'oSvestenomucenik Dorotej; prep.Petar Koriski',
     'oPrepodobni Visarion i Ilarion Novi',
     'oSvestmuc. Teodot Ankirski',
     'oSveti velikomucenik Teodor Stratilat',
     'oSveti Kirilo Aleksandrijski',
     'oSvestenomucenik Timotej Pruski',
     'mSveti apostoli Vartolomej i Varnava',
     'oPrepodobni Onufrije Veliki',
     'oSveta mucenica Akilina i sveti Trifilije',
     'mSveti prorok Jelisej; sveti Metodije',
     'cSv. vmuc. car Lazar i srp.sv.muc.- Vidovdan',
     'oSveti Tihon Amatunski Cudotvorac',
     'oSveti mucenici Manuil, Savel i Ismail',
     'oSveti mucenici Leontije, Ipatije i Teodul',
     'oSveti ap. Juda i prepodobni Pajsije Veliki',
     'oSvestenomucen. Metodije; prep.Naum Ohridski',
     'oSveti mucenik Julijan Tarsijski',
     'oSvestenomuc.Jevsevije; prep.Anastasija Srp.',
     'oSveta mucenica Agripina; Vlad. ikona M. B.',
     'cRozdestvo sv. Jovana Krstitelja - Ivanjdan',
     'oPrepodobnomucenica Fevronija',
     'oPrepodobni David Solunski',
     'oPrepodobni Sampson Stranoprimac',
     'oPrenos mostiju sv.besrebenika Kira i Jovana',
     'cSveti apostoli Petar i Pavle - Petrovdan',
     'oSabor svetih 12 apostola',''),

    ('mJUL- Sv. muc. i besrebrenici Kozma i Damjan',
     'oPolaganje rize Presvete Bogorodice',
     'oSveti mucenik Jakint i prepodobni Anatolije',
     'oSveti Andrej Kritski i prepodobna Marta',
     'oPrep. Atanasije Aton; Sergije Radonjeski',
     'oPrepodobni Sisoje Veliki',
     'oPrepodobni Toma Malein i sv. muc. Nedenja',
     'mSveti velikomucenik Prokopije',
     'oSvestenomucenik Pankratije i sveti Teodor',
     'oSvetih 45 mucenika i Nikopolja',
     'oSv. velikomucenica Efimija i Blazena Olga',
     'oSveti mucenici Proklo i Ilarije',
     'mSabor svetog arhangela Gavrila',
     'oSveti apostol Akila i prepodobni Nikodim',
     'mSveti mucenik Kirik i Julita; sv. Vladimir',
     'oSvestenomuc. Atinogen; sv. mucenica Julija',
     'mSveta velikomuc. Marina (Ognjena Marija)',
     'oSveti mucenik Emilijan i mucenik Jakint',
     'oSveti Stefan i prepod. Evgenija (Lazarevic)',
     'cSveti prorok Ilija; sveti Ilija Gruzijski',
     'oSveti prorok Jezekilj',
     'oSveta Marija Magdalina (Blaga Marija)',
     'oSveti mucenici Trofim, Teofil i drugi',
     'oSveta mucenica Hristina',
     'oUspenije svete Ane',
     'mPrepmuc.Paraskeva (Trnova);Sv.Sava III srp.',
     'mSveti velmuc. Pantelejmon; sv. Kliment Ohr.',
     'oSv.ap. i djakon Prohor,Nikanor,Parmen i dr.',
     'oSveti mucenik Kalinik i mucenica Serafima',
     'oPrepodobna mati Angelina srpska',
     'oSveti Evdokim'),

    ('mAVGUST- Iznosenje Casnog Krsta; Makaveji',
     'oPrenos most. sv.prvomuc. i arhidjak.Stefana',
     'oPrepodobni Isakije, Dalmat i Faust',
     'oSvetih sedam mucenika u Efesu',
     'oSveti muc. Evsignije (Pretpr. Preobrazenja)',
     'cPreobrazenje Gospodnje',
     'oPrepodobnomucenik Dometije i prepodobni Or',
     'oSv. Emilijan Isp.; prep. Zosim Tumanski',
     'oSv. apostol Matija i sv. mucenik Antonije',
     'oSveti mucenik i arhidjakon Lavrentije',
     'oSveti mucenik i arhidjakon Evplo',
     'oSveti mucenici Fotije, Anikita i drugi',
     'oSveti mucenik Ipolit (Odanije Preobrazenja)',
     'oSveti prorok Mihej (Pretpr. Uspenija)',
     'cUspenije Presv. Bogorod.- Velika Gospojina',
     'oSv.Jevstatije, prep.Roman, Rafailo Banat.',
     'oSveti mucenici Miron i Patroklo',
     'oSveti mucenik Flor; prepodobni Jovan Rilski',
     'oSveti mucenik Andrej Stratilat',
     'oSveti prorok Samuilo i svestmuc. Samuilo',
     'oSv.ap.Tadej; sv.mucenica Vasa i njena deca',
     'mSveti muc. Agatonik; svestmuc. Gorazd Ces.',
     'oSvestenomucenik Irinej i mucenik Lup',
     'oSvestenomucenik Evtihije; mucenica Sara',
     'oPrenos most.sv.ap.Vartolomeja i sv.ap.Tit',
     'mSveti mucenici Adrijan i Natalija',
     'oPrepodobni Pimen Veliki',
     'oPrepodobni Mojsej Murin i Sava Pskovski',
     'cUsekovanje glave svetog Jovana Krstitelja',
     'mSv. Aleksan. Nevski; Kiril,Nikon i Makarije',
     'oPolaganje pojasa Presvete Bogorodice'),

    ('mSEPT.- Prep. Simeon Stolpnik - Crkvena N.g.',
     'oSveti mucenik Mamant; sveti Jovan Postnik',
     'oSvesmuc.Antim;sv.Joanikije I patrijarh srp.',
     'oSvestmuc. Vavila; prorok Mojsej Bogovilac',
     'oSveti prorok Zaharija i prav. Jelisaveta',
     'oCudo sv. arhan. Mihaila; sv. muc. Evdoksije',
     'oSveti muc. Sozont (Pretpr. Rozd. Pr. Bog.)',
     'cRozdestvo Presv.Bogorodice (Mala Gospojina)',
     'mSveti pravedni Joakim i Ana',
     'oMucenice Minodora, Mitrodora i Nimfodora',
     'oPrepodobna Teodora; prep. Sergije i German',
     'oSvestmuc. Avtonom (Od. Roz. Presv. Bog.)',
     'oSvestmucenik Kornilije (Pretpr.Vozdvizenja)',
     'cVozdvizenje Casnog Krsta - Krstovdan',
     'oVelikomucenik Nikita; sv.Josif Temisvarski',
     'oVelmuc. Jefimija; prep. Dorotej i Kiprijan',
     'mMuc. Vera, Nada i Ljubav i mati im Sofija',
     'oSv. Evmenije Gortinski; mucenica Arnadna',
     'oSv. muc. Trofim, Savatije i Dorimedont',
     'mSveti velikomucenik Jevstatije',
     'oSveti apostol Kodrat (Odanije Vozdvizenja)',
     'oSvestenomucenik Foka i prorok Jona',
     'mZacece svetog Jovana Krstitelja',
     'oPrvomuc. Tekla; pepr. Simon Vladislav i dr.',
     'oPrepodobna Efrosinija i Sergije Radonjeski',
     'mSveti apostol i jevandjelist Jovan Bogoslov',
     'oSveti mucenik Kalistrat',
     'oPrepod. Hariton Ispovednik; mucenik Marko',
     'mPrep. Kirijak Otselnik - Miholjdan',
     'oSvestenomucenik Grigorije i sveti Mihail',''),

    ('mOKTOBAR- Pokrov Presvete Bogorodice',
     'oSvestenomucenik Kiprijan i prep. Andrej',
     'oSvestenomucenik Dionisije Areopagit',
     'oSveti Stefan i Jelena (Stiljanovic)',
     'oSveti muc. Haritina; svestmuc. Dionisije',
     'mSveti Toma - Tomindan',
     'mSveti mucenici Sergije i Vakho - Srdjevdan',
     'oPrepodobna Pelagija i prepodobna Taisa',
     'oSveti ap.Jakov; sveti Stefan srpski (Slepi)',
     'oSveti mucenici Evlampije i Evlampija',
     'oSveti apostol Filip i sv. Teofan Nacertani',
     'oSveti mucenici Tarah, Prov i Andronik',
     'oSv. muc. Karp; novomucenica Zlata Maglenska',
     'cPrepodobna mati Paraskeva - Sveta Petka',
     'oSvestenomucenik Lukijan i prep. Jevtimije',
     'oSveti mucenik Longin Sotnik',
     'oSveti prorok Osija; prepmuc. Andrej Kritski',
     'mSveti ap. i jevan. Luka; sv.Petar Cetinjski',
     'oPror.Joil; prep. Prohor Pcinjski i Jov.Ril.',
     'oVelikomucenik Artemije',
     'oPrepodobni Ilarion; sv. Ilarion i Visarion',
     'oSveti ravnoapostolni Averkije Jerapoljski',
     'mSveti ap. Jakov, prvi episkop jerusalimski',
     'oSveti velikomucenik Areta',
     'oSveti mucenici Makrijan i Martirije',
     'cSveti velikomucenik Dimitrije - Mitrovdan',
     'oSveti mucenik Nestor',
     'oSveti muc. Terentije; sveti Arsenije Sremac',
     'mSveti Avramije Zatvornik',
     'oSveti kralj Milutin, Teoktist i Jelena',
     'oSv. apostoli Stahije, Amplije, Urvin i dr.'),

    ('mNOVEMBAR- Sveti Kozma i Damjan - Vracevi',
     'oSveti mucenici Akindin, Pigasije i dr.',
     'mObnovljenje hrama sv. Georgija - Djurdjic',
     'oPrep. Joanikije Veliki; svestmuc. Nikandar',
     'oPrepodobnomucenici Galaktion i Epistima',
     'oSveti Pavle Ispovednik',
     'oSvetih 33 mucenika u Melitini; prep. Lazar',
     'cSabor svetog arhan. Mihaila - Arandjelovdan',
     'oSv. muc. Onisifor i Porfirije; Nektar. Eg.',
     'oSveti apostoli Olimp, Erast, Rodion i dr.',
     'oSveti kralj Stefan Decanski - Mratindan',
     'mSveti Jovan Milostivi; prep. Nil Sinajski',
     'mSveti Jovan Zlatousti',
     'mSveti apostol Filip',
     'oSveti mucenik Gurije',
     'mSveti apostol i jevandjelist Matej',
     'oSveti Grigorije Cudotvorac; Nikon Radonjski',
     'oSveti mucenici Platon, Roman i drugi',
     'oProrok Avdija; prepodobni Varlaam i Joasaf',
     'oPrep. Grigorije Dekapolit (Pretpr. Vaved.)',
     'cVavedenje Presvete Bogorodice',
     'oSveti apostoli Filimon, Apfija i Arhip',
     'oSveti Amfilohije i sveti Grigorije',
     'mVelikomucenica Ekatarina; Merkurije',
     'mSvestenomucenik Kliment (Odan. Vavedenja)',
     'mSveti Alimpije Stolpnik',
     'oSveti mucenik Jakov Persijanac',
     'oPrepodobnomucenik Stefan; sveti muc. Hristo',
     'oSveti mucenici Paramon, Filumen i drugi',
     'mSveti apostol Andrej Prvozvani',''),

    ('oDECEMBAR- Prorok Naum i sveti Filaret',
     'oSveti car Uros i prep. Joanikije Devicki',
     'oProrok Sofonija i prepodobni Jovan Cutljivi',
     'mVelikomucenica Varvara; prep.Jovan Damaskin',
     'mPrep.Sava Osveceni; Nektarije Bitoljski',
     'cSveti Nikola - Nikoljdan',
     'oSveti Amvrosije; prepodob. Grigorije Gornj.',
     'oPrep. Patapije; sv.ap. Sosten, Apolos i dr.',
     'oZacece svete Ane',
     'oSveta mucenica Mina; sveti Jovan Srpski',
     'oPrepodobni Danilo Stolpnik',
     'mPrepodobni Spiridon Cudotvorac',
     'oMucenik Evstratije; sv. Gavrilo i Nikodim',
     'oSveti muc. Tirs, Levkije, Filimon i dr.',
     'oSvestenomucenik Elevterije i prep. Pavle',
     'oProrok Agej i sveta Teofanija',
     'oProrok Danilo; prepmucenik djakon Avakum',
     'oSveti mucenik Sevastijan;sveti Modert i dr.',
     'mSveti mucenik Bonifacije',
     'mSv.Ignjatije Bog.; Dan.II Srp. (Pret.Rozd.)',
     'oSveta mucenica Julijana i sv.Petar Kijevski',
     'oSveta velikomucenica Anastasija',
     'oSv. 10 mucenika Kritskih; prep. Naum Ohr.',
     'oPrepodobnomucenica Evgenija - Badnji dan',
     'cRozdestvo Hristovo - Bozic',
     'cSabor Presvete Bogorodice',
     'cSveti prvomucenik i arhidjakon Stefan',
     'oSvetih 20.000 mucenika Nikomidijskih',
     'oSvetih 14.000 mladenaca Vitlejemskih',
     'oSveta mucenica Anisija i prepodobna Teodora',
     'oPrepodobna Melanija (Odanije Rozdestva)'));

  praz_p: array[1..12] of prstr = (
    'cUlazak G. I. Hrista u Jerusalim - Cveti',
    'mVeliki cetvrtak (Veliko bdenije)',
    'cVeliki petak',
    'mVelika subota',
    'cVaskrsenje Gospoda Isusa Hrista - Vaskrs',
    'cVaskrsni ponedeljak',
    'cVaskrsni utorak',
    'cVaznesenje Gospodnje - Spasovdan',
    'cSilazak Svetog Duha - Pedesetnica - Trojice',
    'cDuhovski ponedeljak',
    'cDuhovski utorak',
    'cVaskrsenje Hristovo - Vaskrs - Blagovesti');

var
  _d, _m, _g, _dd, _k, __dj__, __mj__, __gj__,
  i1_, i2_, _topday, _dj2_, _mj2_, _gj2_, qw, d_, m_, g_,
  i, vpd_, vpm_, brned, di, mi, gi,
  mt___, mtt__, ind_, indg_, __ud, __um, __sd, __sm,
  __dd, __dm : integer;
  pok_    : array[1..11] of spec;
  _post   : array[1..12] of array[1..31] of boolean;
  ned     : array[1..80] of array[1..2] of integer;
  imi     : array[1..80] of integer;
  da      : string[4];
  quit, again : boolean;
  gnd, dnd, zatvtab, pktab : tbstr;
  mw      : word;

{ ------------------------------------------------------------------ }

procedure getcursordata; begin end;
procedure showcursor;    begin end;
procedure hidecursor;    begin end;

{ ------------------------------------------------------------------ }

procedure dodvredmoom;
var gu, gi_: byte;
begin
  mmmax := jmmax;
  mainm[1] := 'Desk';      mainm[2] := 'Opcije';
  mainm[3] := 'Traganje';  mainm[4] := 'Stampanje';
  mainm[5] := 'Pomoc';
  mainh[1] := 'Desk informacije';
  mainh[2] := 'Glavne komande (promena datuma, tabela postova, izlazak)';
  mainh[3] := 'Pretrazivanja u kalendaru (nalazenja imena praznika, nedelja, itd.)';
  mainh[4] := 'Izvoz mesecnog kalendara ili tabele postova u TXT';
  mainh[5] := 'Pomoc i uputstvo za koriscenje Pravoslavnog kalendara';
  for gu := 1 to mmmax do
  begin
    mmpos[gu] := mmpos_[gu];
    mmpol[gu] := mmpol_[gu];
    mmdim[gu][1] := mmdim_[gu][1];
    mmdim[gu][2] := mmdim_[gu][2];
    mmnli[gu] := mmnli_[gu];
    mmcrt[gu] := mmcrt_[gu];
  end;
  mmsss[1][1] := 'Program...';
  mmsss[2][1] := 'Aktivni datum      F3';
  mmsss[2][2] := 'Postovi        Ctrl-P';
  mmsss[2][3] := 'Heortologija       F5';
  mmsss[2][4] := 'Indiktion';
  mmsss[2][5] := 'Izlazak        Ctrl-C';
  mmsss[3][1] := 'Trazenje datuma';
  mmsss[3][2] := 'Trazenje praznika';
  mmsss[3][3] := 'Trazenje posta';
  mmsss[3][4] := 'Trazenje nedelje';
  mmsss[4][1] := 'Izvoz meseca u TXT    F7';
  mmsss[4][2] := 'Izvoz postova u TXT  F8';
  mmsss[4][3] := 'Konfiguracija';
  mmsss[4][4] := 'Snimanje kofiguracije';
  mmsss[5][1] := 'Pomoc          F1';
  mmsss[5][2] := 'Sadrzaj    Alt-F1';
  for gu := 1 to mmmax do mmpcm[gu] := 1;
  kfun[1].sta[1] := 'F1';  kfun[1].sta[2] := 'Pomoc';           kfun[1].kps := 2;
  kfun[2].sta[1] := 'F3';  kfun[2].sta[2] := 'Promena datuma';  kfun[2].kps := 12;
  kfun[3].sta[1] := 'F5';  kfun[3].sta[2] := 'Heortologija';    kfun[3].kps := 31;
  kfun[4].sta[1] := 'F7';  kfun[4].sta[2] := 'Stampanje meseca';kfun[4].kps := 48;
  kfun[5].sta[1] := 'F10'; kfun[5].sta[2] := 'Meni';            kfun[5].kps := 69;
end;

{ ------------------------------------------------------------------ }

procedure initialization_;   { renamed to avoid conflict with future unit usage }
var yr, mo, dy: word;
    dt: TDateTime;
begin
  getcursordata;
  hidecursor;
  dt := Now;
  DecodeDate(dt, yr, mo, dy);
  _g := integer(yr);
  _m := integer(mo);
  gnd     := '+' + niz(3,'-') + '+' + niz(4,'-') + '+' + niz(5,'-') + '+' + niz(45,'-') + '+';
  dnd     := '+' + niz(3,'-') + '+' + niz(4,'-') + '+' + niz(5,'-') + '+' + niz(45,'-') + '+';
  zatvtab := '+' + niz(3,'-') + '+' + niz(4,'-') + '+' + niz(5,'-') + '+' + niz(45,'-') + '+';
  pktab   := '+' + niz(3,'-') + '+' + niz(4,'-') + '+' + niz(5,'-') + '+' + niz(45,'-') + '+';
  dodvredmoom;
end;

function brmdg(ms, gd: integer): integer;
begin
  if ms <> 2 then brmdg := bmd[ms]
  else if prestupna_greg(gd) then brmdg := 29
  else brmdg := 28;
end;

function brdmj(ms, gd: integer): integer;
begin
  if ms <> 2 then brdmj := bmd[ms]
  else if prestupna_jul(gd) then brdmj := 29
  else brdmj := 28;
end;

procedure uvecjul(var od, om, og: integer);
begin
  inc(od);
  if od > brdmj(om, og) then
  begin
    od := 1;
    inc(om);
    if om = 13 then begin om := 1; inc(og); end;
  end;
end;

procedure umanjul(var od, om, og: integer);
begin
  dec(od);
  if od = 0 then
  begin
    dec(om);
    if om = 0 then begin om := 12; dec(og); end;
    od := brdmj(om, og);
  end;
end;

{ ------------------------------------------------------------------ }

procedure setjulijan(sd, sm, sg: integer;
                     var eoa, eob, eoc: integer;
                     smer: boolean);
var yy, j, rr, _d2, _m2, _g2: integer;
begin
  rr := _r20_;
  { Adjust for century years where Julian has a leap day but Gregorian does not.
    Each such century (not div-400) adds 1 day to the Julian-Gregorian offset. }
  if (_g div 100) < (__indiktg div 100) then
  begin
    for yy := (_g div 100) + 1 to (__indiktg div 100) do
      if yy mod 4 <> 0 then dec(rr);
  end
  else
  begin
    for yy := (_g div 100) downto (__indiktg div 100) + 1 do
      if yy mod 4 <> 0 then inc(rr);
  end;
  _d2 := sd; _m2 := sm; _g2 := sg;
  if smer then
  begin
    if rr > 0 then
      for j := 1 to abs(rr) do umanjul(_d2, _m2, _g2)
    else
      for j := 1 to abs(rr) do uvecjul(_d2, _m2, _g2);
  end
  else
  begin
    if rr > 0 then
      for j := 1 to abs(rr) do uvecjul(_d2, _m2, _g2)
    else
      for j := 1 to abs(rr) do umanjul(_d2, _m2, _g2);
  end;
  if (_g mod 100 = 0) then
    if (_g mod 400 <> 0) then
      if _m2 in [1, 12] then uvecjul(_d2, _m2, _g2);
  eoa := _d2; eob := _m2; eoc := _g2;
end;

function prvdangod(ww: integer): integer;
begin
  prvdangod := (ww + ((ww-1) div 4) + ((ww-1) div 400) - ((ww-1) div 100)) mod 7;
end;

function danuned(m1, g1: integer; var oa, ob, oc: integer): integer;
var dpr, ii: integer;

  function brojdanmes(qm, rg: integer): integer;
  begin
    if qm <> 2 then brojdanmes := bmd[qm]
    else if prestupna_greg(rg) then brojdanmes := 29
    else brojdanmes := 28;
  end;

begin
  dpr := prvdangod(g1);
  for ii := 1 to m1 - 1 do
    inc(dpr, brojdanmes(ii, g1));
  dpr := dpr mod 7;
  setjulijan(1, _m, _g, oa, ob, oc, true);
  danuned := dpr;
end;

{ ------------------------------------------------------------------ }

procedure stick(gd: byte);
begin
  elwritecol(2, gd,
    '|   |    |     |' + niz(45, ' ') + '|',
    co[2]);
end;

procedure tekdat;
begin
  openwind(67, 16, 79, 24, 27, 27, '', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwrite(69, 17, imm[_m] + niz(10 - length(imm[_m]), ' '));
  elwrite(69, 19, prsl(_g));
  elwrite(69, 20, strf(_g) + '   ');
  elwrite(69, 22, strf(indiktiong(_g)) + '.');
  elwrite(69, 23, 'indiktion');
end;

procedure lazarev_krst(_x, _y: integer);
var i: integer;
begin
  for i := 1 to 9 do
    elwritecol(_x, pred(_y + i), krst[i], co[5]);
end;

procedure drawfirstscreen;
begin
  { Flood-fill calendar area first, then draw chrome on top }
  elbojwind(1, 2, 65, 24, co[2]);
  elwritecol(2, 2, '+' + niz(60, '-') + '+', co[2]);
  elwritecol(2, 4, '+' + niz(3,'-') + '+' + niz(4,'-') + '+' + niz(5,'-') + '+' + niz(45,'-') + '+', co[2]);
  elwritecol(2, 5, '| D |  G |  J  | Pravoslavni praznik' + niz(25, ' ') + '|', co[4]);
  openwind(67, 2, 79, 5, co[27], co[27], '', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwrite(69, 3, 'NEA');
  elwrite(69, 4, 'BYZANTIA');
  lazarev_krst(67, 6);
  showmainmenu;
  showkeyfunc(5);
end;

procedure drawscreen;
begin
  elwrite(2, 3, '|' + niz(60, ' ') + '|');
  elwrite(2, 6, pktab);
  elwrite(2, 24, zatvtab);
  tekdat;
end;

{ ------------------------------------------------------------------ }

function imepraz(__odj__, __omj__, __ogj__: integer): prstr;
var prr__: prstr;
    jj   : integer;
begin
  prr__ := praz[__omj__][__odj__];
  for jj := 1 to 11 do
    if (__odj__ = pok_[jj][1]) and (__omj__ = pok_[jj][2]) then
    begin
      if jj <> 5 then prr__ := praz_p[jj]
      else if (pok_[jj][1] = 25) and (pok_[jj][2] = 3) then
        prr__ := praz_p[12]
      else
        prr__ := praz_p[jj];
    end;
  if not prestupna_jul(__ogj__) then
    if (__omj__ = 2) and (__odj__ = 28) then prr__ := praz[2][30];
  if (__omj__ = 1) and (__odj__ = 1) then
    prr__ := prr__ + strf(__ogj__) + '.';
  imepraz := prr__;
end;

function rav2(tth: string): string;
begin
  if length(tth) = 1 then rav2 := ' ' + tth else rav2 := tth;
end;

procedure writedat(i, qw: byte;
                   __odj__, __omj__, __ogj__, _ddd: integer);
var pr__: prstr;
    tatt: integer;
begin
  stick(qw);
  pr__ := imepraz(__odj__, __omj__, __ogj__);
  if _post[__omj__][__odj__] then elwritecol(16, qw, BOX_BULL, co[19]);
  elwritecol(8, qw, rav2(strf(i)), co[17]);
  tatt := co[17];
  if _ddd = 0 then tatt := co[15]
  else if pr__[1] <> 'c' then tatt := co[17]
  else tatt := co[15];
  elwritecol(4, qw, dun[_ddd], tatt);
  elwritecol(13, qw, rav2(strf(__odj__)), tatt);
  case pr__[1] of
    'c': tatt := co[15];
    'm': tatt := co[16];
    'o': tatt := co[17];
  end;
  elwritecol(19, qw, copy(pr__, 2, length(pr__) - 1), tatt);
  NormVideo;
end;

{ ------------------------------------------------------------------ }

function imened(dn, ms: integer): pathstr;
var fv: integer;
    im: pathstr;
begin
  im := '';
  for fv := 1 to brned do
    if (ned[fv][1] = dn) and (ned[fv][2] = ms) then
    begin
      if imi[fv] > 1000 then
        im := 'Nedelja ' + strf(imi[fv] - 1000) + '. po Duhovima';
      if (imi[fv] >= 100) and (imi[fv] <= 999) then
        im := 'Nedelja ' + strf(imi[fv] - 100) + '. po Duhovima';
      if imi[fv] <= 19 then
        im := nedelja[imi[fv]];
    end;
  imened := im;
end;

procedure writenedelja(dn, ms, gd: integer);
var im: pathstr;
begin
  elwritecol(2, gd, '|' + niz(60, ' ') + '|', co[2]);
  im := imened(dn, ms);
  elwritecol(32 - (length(im) div 2), gd, im, co[15]);
end;

procedure kalendar;
var d_d, ppd, ji, iop, vv: integer;
begin
  _dd := danuned(_m, _g, __dj__, __mj__, __gj__);
  d_d := _dd;
  _k  := brmdg(_m, _g);
  qw  := 6; i := 0;
  di := __dj__; mi := __mj__; gi := __gj__;
  _dj2_ := __dj__; _mj2_ := __mj__; _gj2_ := __gj__;
  if brmdg(_m, _g) mod 10 <> 1 then da := 'dana' else da := 'dan';
  elwritecol(4, 3, strf(_g), co[17]);
  elwritecol(59 - length(da), 3, strf(brmdg(_m, _g)) + ' ' + da, co[17]);
  elwritecol(32 - (length(imm[_m]) div 2), 3, upcasestr(imm[_m]), co[15]);
  { Compute base tab position from day-of-week of first of month }
  if _dd = 0 then
  begin
    mt___ := 2;
    elwritecol(2, 6, gnd, co[2]);
  end
  else
    mt___ := 4 + _dd;
  { Advance by _topday-1 days to scroll the view window }
  vv := _topday - 1;
  for ppd := 1 to vv do
  begin
    inc(d_d); if d_d = 7 then d_d := 0;
    uvecjul(_dj2_, _mj2_, _gj2_);
  end;
  { Each week in tabs is 10 positions (abc0123456); advance mt___ by full weeks }
  mt___ := mt___ + ((vv div 7) * 10);
  mtt__ := mt___;
  iop := 6;
  for qw := mt___ to mt___ + 16 do
  begin
    inc(iop);
    case tabs[qw] of
      'a': elwritecol(2, iop, gnd, co[2]);
      'b': writenedelja(_dj2_, _mj2_, iop);
      'c': elwritecol(2, iop, dnd, co[2]);
    else
      begin
        inc(vv);
        writedat(vv, iop, _dj2_, _mj2_, _gj2_, d_d);
        inc(d_d); if d_d = 7 then d_d := 0;
        uvecjul(_dj2_, _mj2_, _gj2_);
      end;
    end;
  end;
  if tabs[mt___ + 16] in ['a', 'b'] then
    elwritecol(2, 24, '+' + niz(60, '-') + '+', co[2]);
  umanjul(_dj2_, _mj2_, _gj2_);
  i1_ := _topday; i2_ := vv;
end;

{ =================== Vaskrsenje Gospoda Isusa Hrista =============== }

procedure indiktion(gg: integer; var __indg: integer);
begin
  __indg := succ((gg - __indiktg + 532 * 5) mod 532);
end;

procedure setpost;
var tt, _d_, _m_, ggg: integer;
begin
  { Clear the entire fasting-day grid without DOS seg/ofs tricks }
  FillChar(_post, SizeOf(_post), 0);
  _post[1][5]   := true;
  _post[8][29]  := true;
  _post[9][14]  := true;
  for tt := 14 to 31 do _post[11][tt] := true;
  for tt := 1  to 24 do _post[12][tt] := true;
  _d_ := pok_[5][1]; _m_ := pok_[5][2]; ggg := _g;
  for tt := 1 to 48 do
  begin
    umanjul(_d_, _m_, ggg);
    if tt = 1 then begin postd[1][2][1] := _d_; postd[1][2][2] := _m_; end;
    _post[_m_][_d_] := true;
  end;
  postd[1][1][1] := _d_; postd[1][1][2] := _m_;
  vpd_ := _d_; vpm_ := _m_;
  _d_ := pok_[11][1]; _m_ := pok_[11][2];
  for tt := 1 to 6 do uvecjul(_d_, _m_, ggg);
  postd[2][1][1] := _d_; postd[2][1][2] := _m_;
  postd[2][2][1] := 29;  postd[2][2][2] := 6;
  while (_d_ <> 29) or (_m_ <> 6) do
  begin
    _post[_m_][_d_] := true;
    uvecjul(_d_, _m_, ggg);
  end;
  _post[7][31] := true;
  for tt := 1 to 14 do _post[8][tt] := true;
end;

procedure setnedelje;
var dd_, mm_, gh, hj, _gg, ggg, ig, np, pdh, odd_, omm_, xxx, xxx_,
    ccc, fvv, eed, eem, eeg, gty, wd, wm: integer;

  function nedprv(_duhd, _duhm: integer): integer;
  var bj, xv: integer;
  begin
    xv := bmd[_duhm] - _duhd;
    for bj := succ(_duhm) to 12 do inc(xv, bmd[bj]);
    nedprv := succ(xv div 7);
  end;

begin
  ggg := pred(_g);
  indiktion(ggg, ig);
  dd_ := datumi[ig][1]; mm_ := datumi[ig][2];
  for gh := 1 to 49 do uvecjul(dd_, mm_, ggg);
  setjulijan(dd_, mm_, ggg, wd, wm, xxx, false);
  np  := nedprv(wd, wm);
  _gg := _g; brned := 1;
  dd_ := vpd_; mm_ := vpm_;
  for gh := 1 to 22 do umanjul(dd_, mm_, _g);
  xxx_ := 8 - prvdangod(_g); if xxx_ = 8 then xxx_ := 1;
  setjulijan(xxx_, 1, _g, odd_, omm_, xxx, true);
  while (odd_ <> dd_) or (omm_ <> mm_) do
  begin
    imi[brned]    := 1000 + np;
    ned[brned][1] := odd_; ned[brned][2] := omm_;
    for hj := 1 to 7 do uvecjul(odd_, omm_, ccc);
    inc(np); inc(brned);
  end;
  fvv := 2;
  for gh := 1 to 19 do
  begin
    if gh in [1, 3, 11, 18] then
    begin
      inc(fvv);
      postd[fvv][1][1] := dd_; postd[fvv][1][2] := mm_;
      eed := dd_; eem := mm_; eeg := _g;
      for gty := 1 to 6 do uvecjul(eed, eem, eeg);
      postd[fvv][2][1] := eed; postd[fvv][2][2] := eem;
    end;
    imi[brned]    := gh;
    ned[brned][1] := dd_; ned[brned][2] := mm_;
    for hj := 1 to 7 do uvecjul(dd_, mm_, _g);
    inc(brned);
  end;
  pdh := 1;
  while (_gg = _g) do
  begin
    inc(pdh);
    imi[brned]    := 100 + pdh;
    ned[brned][1] := dd_; ned[brned][2] := mm_;
    for hj := 1 to 7 do uvecjul(dd_, mm_, _gg);
    inc(brned);
  end;
end;

procedure setuskrs;
var ii: integer;
begin
  indiktion(_g, indg_);
  ind_ := indiktiong(_g);
  __ud := datumi[indg_][1]; __um := datumi[indg_][2];
  __sd := __ud; __sm := __um;
  __dd := __ud; __dm := __um;
  for ii := 1 to 7 do umanjul(__ud, __um, _g);
  pok_[1][1] := __ud; pok_[1][2] := __um;
  for ii := 1 to 4 do uvecjul(__ud, __um, _g);
  for ii := 2 to 7 do
  begin
    pok_[ii][1] := __ud; pok_[ii][2] := __um;
    uvecjul(__ud, __um, _g);
  end;
  for ii := 1 to 39 do uvecjul(__sd, __sm, _g);
  pok_[8][1] := __sd; pok_[8][2] := __sm;
  for ii := 1 to 49 do uvecjul(__dd, __dm, _g);
  for ii := 9 to 11 do
  begin
    pok_[ii][1] := __dd; pok_[ii][2] := __dm;
    uvecjul(__dd, __dm, _g);
  end;
  setpost;
  setnedelje;
end;

{ ======================== Stampanje ================================ }

procedure stampaj;
var qww, dan, drj, drm, xcv, d_d, tg: integer;
    imnd : prstr;
    buf  : string;
    fname: string;
    lines: TKTXTLines;
    nl   : integer;

  procedure addLine(const s: string);
  begin
    if nl < KTXT_MAXLINES then begin lines[nl] := s; inc(nl); end;
  end;

begin
  nl    := 0;
  fname := direct + 'mesec_' + strf(_g) + '_';
  if _m < 10 then fname := fname + '0';
  fname := fname + strf(_m) + '.txt';

  for tg := 1 to 6 do addLine(krst1[tg]);
  addLine('');
  addLine('+' + niz(60, '-') + '+');
  buf := '| ' + strf(_g) + niz(4 - length(strf(_g)), ' ') +
         niz(25 - (length(imm[_m]) div 2), ' ') +
         upcasestr(imm[_m]) +
         niz(21 - (length(imm[_m]) div 2), ' ');
  if length(imm[_m]) mod 2 = 0 then buf := buf + ' ';
  buf := buf + niz(4 - length(da), ' ') + strf(brmdg(_m, _g)) + ' ' + da + ' |';
  addLine(buf);
  addLine(dnd);
  addLine('| D |  G |  J  | Pravoslavni praznik' + niz(25, ' ') + '|');
  if mtt__ <> 2 then addLine(pktab) else addLine(gnd);

  drj := di; drm := mi; xcv := gi; d_d := _dd; qww := mtt__; dan := 0;
  while dan < brmdg(_m, _g) do
  begin
    case tabs[qww] of
      'a': addLine(gnd);
      'b': begin
             imnd := imened(drj, drm);
             addLine('|' + niz((60 - length(imnd)) div 2, ' ') + imnd +
                     niz(60 - length(imnd) - (60 - length(imnd)) div 2, ' ') + '|');
           end;
      'c': addLine(dnd);
    else
      begin
        inc(dan);
        imnd := imepraz(drj, drm, xcv);
        { Column widths from separator +---+----+-----+---...---+:
            D=3  G=4  J+fast=5  feast=45 }
        buf := '| ' + dun[d_d] + ' |' +
               niz(3 - length(strf(dan)), ' ') + strf(dan) + ' |' +
               niz(3 - length(strf(drj)), ' ') + strf(drj) + ' ';
        if _post[drm][drj] then buf := buf + BOX_BULL else buf := buf + ' ';
        buf := buf + '| ' + copy(imnd, 2, length(imnd) - 1) +
               niz(45 - length(imnd), ' ') + '|';
        addLine(buf);
        inc(d_d); if d_d = 7 then d_d := 0;
        uvecjul(drj, drm, xcv);
      end;
    end;
    inc(qww);
  end;
  addLine(zatvtab);

  if writeTXTLines(fname, nl, lines) then
  begin
    openwind(8, 10, 71, 15, co[27], co[27], ' Izvoz u TXT ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'TXT snimljen:', co[4]);
    elwritecol(10, 12, fname, co[15]);
    waitKey('');
  end
  else
  begin
    openwind(8, 10, 71, 15, co[27], co[27], ' Greska ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'Greska pri snimanju TXT fajla!', co[6]);
    elwritecol(10, 12, fname, co[17]);
    waitKey('');
  end;
end;

{ ── String input helper ──────────────────────────────────────────── }

function readinput(x, y, maxlen: integer): string;
var buf: string; k: char;
begin
  buf := '';
  repeat
    GotoXY(x, y);
    TextColor(co[15] and $0F);
    TextBackground((co[15] shr 4) and $07);
    Write(buf + niz(maxlen - length(buf), ' '));
    GotoXY(x + length(buf), y);
    k := ReadKey;
    if k = #0 then k := ReadKey
    else case k of
      #8:  if length(buf) > 0 then Delete(buf, length(buf), 1);
      #27: begin buf := #27; break; end;
      #13: break;
    else
      if (length(buf) < maxlen) and (k >= ' ') then buf := buf + k;
    end;
  until false;
  NormVideo;
  readinput := buf;
end;

{ ── $0301 — Trazenje datuma ─────────────────────────────────────── }

function traziDatum: boolean;
const X1 = 12; Y1 = 5; X2 = 68; Y2 = 19;
var nd, nm, ng, jd, jm, jy: integer;
    feast: prstr; nedname: pathstr; s: string[8]; k: char; ok: boolean;
begin
  traziDatum := false;
  nd := 1; nm := _m; ng := _g;
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Trazenje datuma ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  ok := false;
  repeat
    elwritecol(X1+2, Y1+2, 'Dan   (1-31): ', co[4]);
    GotoXY(X1+16, Y1+2);
    TextColor(co[15] and $0F); TextBackground((co[15] shr 4) and $07);
    Str(nd, s); Write(s + '   ');
    elwritecol(X1+2, Y1+3, 'Mesec (1-12): ', co[4]);
    GotoXY(X1+16, Y1+3);
    TextColor(co[15] and $0F); TextBackground((co[15] shr 4) and $07);
    Str(nm, s); Write(s + '   ');
    elwritecol(X1+2, Y1+4, 'Godina:       ', co[4]);
    GotoXY(X1+16, Y1+4);
    TextColor(co[15] and $0F); TextBackground((co[15] shr 4) and $07);
    Str(ng, s); Write(s + '     ');
    NormVideo;
    if nd > brmdg(nm, ng) then nd := brmdg(nm, ng);
    setjulijan(nd, nm, ng, jd, jm, jy, true);
    feast   := imepraz(jd, jm, jy);
    nedname := imened(jd, jm);
    elwritecol(X1+2, Y1+6,
      'Julij: ' + strf(jd) + '.' + strf(jm) + '.' + strf(jy) + '.     ', co[17]);
    elwritecol(X1+2, Y1+7, niz(52, ' '), co[17]);
    elwritecol(X1+2, Y1+7, 'Praznik: ' + copy(feast, 2, length(feast)), co[15]);
    if _post[jm][jd] then
      elwritecol(X1+2, Y1+8, 'Post: DA              ', co[19])
    else
      elwritecol(X1+2, Y1+8, 'Post: -               ', co[17]);
    elwritecol(X1+2, Y1+9, niz(52, ' '), co[17]);
    if nedname <> '' then
      elwritecol(X1+2, Y1+9, nedname, co[16]);
    elwritecol(X1+2, Y1+11, '</>  = dan,  PgUp/PgDn = mesec,  +/- = god.', co[17]);
    elwritecol(X1+2, Y1+12, 'Enter = idi na mesec,   Esc = odustani', co[17]);
    k := ReadKey;
    if k = #0 then k := ReadKey;
    case k of
      '>': if nd < 31 then inc(nd) else nd := 1;
      '<': if nd > 1  then dec(nd) else nd := 31;
      pgupkey: if nm < 12 then inc(nm) else begin nm := 1; inc(ng); end;
      pgdnkey: if nm > 1  then dec(nm) else begin nm := 12; dec(ng); end;
      '+': inc(ng);
      '-': if ng > 1 then dec(ng);
      enterkey: ok := true;
      esckey:   exit;
    end;
  until ok;
  _m := nm; _g := ng;
  traziDatum := true;
end;

{ ── $0302 — Trazenje praznika ───────────────────────────────────── }

procedure traziPraznik;
const X1 = 5; Y1 = 4; X2 = 75; Y2 = 22; PERPAGE = 12;
var
  query             : string;
  rdates            : array[1..50] of string[10];
  rnames            : array[1..50] of pathstr;
  rcount, m, d, i   : integer;
  pg, pgmax, pgstart : integer;
  k                  : char;
  feast              : prstr;
begin
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Trazenje praznika ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1+2, Y1+2, 'Unesi deo naziva praznika:', co[4]);
  query := readinput(X1+2, Y1+3, 40);
  if (query = '') or (query[1] = #27) then exit;
  rcount := 0;
  for m := 1 to 12 do
    for d := 1 to brdmj(m, _g) do
    begin
      feast := imepraz(d, m, _g);
      if Pos(UpperCase(query), UpperCase(copy(feast, 2, length(feast)))) > 0 then
        if rcount < 50 then
        begin
          inc(rcount);
          rdates[rcount] := strf(d) + '.' + strf(m) + '.';
          rnames[rcount] := copy(feast, 2, length(feast));
          if length(rnames[rcount]) > 47 then
            rnames[rcount] := copy(rnames[rcount], 1, 47);
        end;
    end;
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Rezultati: ' + strf(rcount) + ' ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  if rcount = 0 then
  begin
    elwritecol(X1+2, Y1+2, 'Nije pronadjen nijedan praznik.', co[17]);
    waitKey(' Pritisnite bilo koji taster... ');
    exit;
  end;
  pg    := 1;
  pgmax := (rcount + PERPAGE - 1) div PERPAGE;
  repeat
    elwritecol(X1+2, Y1+1, 'Datum      Praznik' + niz(50, ' '), co[15]);
    for i := Y1+2 to Y1+2+PERPAGE do
      elwritecol(X1+2, i, niz(65, ' '), co[2]);
    pgstart := (pg - 1) * PERPAGE + 1;
    for i := pgstart to pgstart + PERPAGE - 1 do
    begin
      if i > rcount then break;
      elwritecol(X1+2, Y1+2 + (i - pgstart),
        rdates[i] + '  ' + rnames[i], co[17]);
    end;
    if pgmax > 1 then
    begin
      elwritecol(X1+2, Y1+2+PERPAGE,
        'Str. ' + strf(pg) + '/' + strf(pgmax) +
        '   PgUp/PgDn=strana   Esc=zatvori', co[17]);
      k := ReadKey;
      if k = #0 then k := ReadKey;
      case k of
        pgdnkey: if pg < pgmax then inc(pg);
        pgupkey: if pg > 1     then dec(pg);
        esckey:  exit;
      end;
    end
    else
    begin
      waitKey(' Pritisnite bilo koji taster... ');
      exit;
    end;
  until false;
end;

{ ── $0303 — Trazenje posta ──────────────────────────────────────── }

procedure traziPost;
const X1 = 5; Y1 = 4; X2 = 75; Y2 = 22;
var nm, d, nrow: integer; k: char; feast: prstr; found: boolean;
begin
  nm := _m;
  repeat
    openwind(X1, Y1, X2, Y2, co[27], co[27],
             ' Trazenje posta ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(X1+2, Y1+2,
      'Mesec: ' + imm[nm] + niz(40, ' '), co[15]);
    elwritecol(X1+2, Y1+3, niz(66, '-'), co[27]);
    nrow  := Y1 + 4;
    found := false;
    for d := 1 to brdmj(nm, _g) do
      if _post[nm][d] then
      begin
        feast := imepraz(d, nm, _g);
        elwritecol(X1+2, nrow,
          strf(d) + '.  ' + copy(feast, 2, length(feast)) + niz(60, ' '), co[17]);
        found := true;
        inc(nrow);
        if nrow > Y1 + 16 then break;
      end;
    if not found then
      elwritecol(X1+2, Y1+4, 'Nema posnih dana u ovom mesecu.', co[17])
    else
      while nrow <= Y1+16 do
      begin
        elwritecol(X1+2, nrow, niz(67, ' '), co[2]);
        inc(nrow);
      end;
    elwritecol(X1+2, Y1+17, 'PgUp/PgDn = mesec,  Esc = zatvori', co[17]);
    k := ReadKey;
    if k = #0 then k := ReadKey;
    case k of
      pgupkey: if nm < 12 then inc(nm) else nm := 1;
      pgdnkey: if nm > 1  then dec(nm) else nm := 12;
      esckey:  exit;
    end;
  until false;
end;

{ ── $0304 — Trazenje nedelje ────────────────────────────────────── }

procedure traziNedelju;
const X1 = 5; Y1 = 4; X2 = 75; Y2 = 22; PERPAGE = 12;
var total, pg, pgmax, pgstart, i: integer; k: char;
    nedname: pathstr; s: string[12];
begin
  total := brned - 1;
  if total < 1 then begin waitKey(' Nema podataka. '); exit; end;
  pg    := 1;
  pgmax := (total + PERPAGE - 1) div PERPAGE;
  repeat
    openwind(X1, Y1, X2, Y2, co[27], co[27],
             ' Nedelje ' + strf(_g) + ' (' + strf(total) + ') ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(X1+2, Y1+1, 'Datum (jul.)   Naziv nedelje' + niz(40, ' '), co[15]);
    for i := Y1+2 to Y1+2+PERPAGE do
      elwritecol(X1+2, i, niz(65, ' '), co[2]);
    pgstart := (pg - 1) * PERPAGE + 1;
    for i := pgstart to pgstart + PERPAGE - 1 do
    begin
      if i > total then break;
      nedname := imened(ned[i][1], ned[i][2]);
      Str(ned[i][1], s);
      s := s + '.' + strf(ned[i][2]) + '.';
      elwritecol(X1+2, Y1+2 + (i - pgstart),
        s + niz(14 - length(s), ' ') + nedname, co[17]);
    end;
    if pgmax > 1 then
    begin
      elwritecol(X1+2, Y1+2+PERPAGE,
        'Str. ' + strf(pg) + '/' + strf(pgmax) +
        '   PgUp/PgDn=strana   Esc=zatvori', co[17]);
      k := ReadKey;
      if k = #0 then k := ReadKey;
      case k of
        pgdnkey: if pg < pgmax then inc(pg);
        pgupkey: if pg > 1     then dec(pg);
        esckey:  exit;
      end;
    end
    else
    begin
      waitKey(' Pritisnite bilo koji taster... ');
      exit;
    end;
  until false;
end;

{ Restores the full screen — used as the tastmenu navigation callback. }
procedure doMenuRedraw;
begin
  drawfirstscreen;
  drawscreen;
  kalendar;
end;

procedure menuwork(mewo: word);
var dali: boolean;
begin
  case mewo of
    0:     begin drawfirstscreen; drawscreen; needRedraw := true; end;
    $0101: begin about;         drawfirstscreen; drawscreen; needRedraw := true; end;
    $0201: begin
             dali := setdat(_m, _g);
             if dali then begin quit := true; again := true; end
             else begin drawfirstscreen; drawscreen; needRedraw := true; end;
           end;
    $0202: begin tabpost(_g);   drawfirstscreen; drawscreen; needRedraw := true; end;
    $0203: begin helppraz;      drawfirstscreen; drawscreen; needRedraw := true; end;
    $0204: begin tabindikt;     drawfirstscreen; drawscreen; needRedraw := true; end;
    $0205: begin quit := true; again := false; end;
    $0301: begin
             if traziDatum then begin quit := true; again := true; end
             else begin drawfirstscreen; drawscreen; needRedraw := true; end;
           end;
    $0302: begin traziPraznik;  drawfirstscreen; drawscreen; needRedraw := true; end;
    $0303: begin traziPost;     drawfirstscreen; drawscreen; needRedraw := true; end;
    $0304: begin traziNedelju;  drawfirstscreen; drawscreen; needRedraw := true; end;
    $0401: begin stampaj;         drawfirstscreen; drawscreen; needRedraw := true; end;
    $0402: begin stampajPost(_g); drawfirstscreen; drawscreen; needRedraw := true; end;
    $0403: begin konfig;     drawfirstscreen; drawscreen; needRedraw := true; end;
    $0404: begin snimKonfig; drawfirstscreen; drawscreen; needRedraw := true; end;
    $0501: begin pomoc;      drawfirstscreen; drawscreen; needRedraw := true; end;
    $0502: begin sadrzaj;    drawfirstscreen; drawscreen; needRedraw := true; end;
  end;
  { Restore function-key bar (was: move video buffer row back) }
  showkeyfunc(5);
end;

{ ------------------------------------------------------------------ }

procedure mainwork;
var cc: char;
begin
  quit := false;
  repeat
    kalendar;
    needRedraw := false;
    repeat
      cc := scankey;
      case cc of
        downkey:
          begin
            if i2_ < brmdg(_m, _g) then
            begin
              inc(_topday, 7);
              needRedraw := true;
            end;
          end;
        upkey:
          begin
            if i1_ > 1 then
            begin
              dec(_topday, 7);
              if _topday < 1 then _topday := 1;
              needRedraw := true;
            end;
          end;
        F1:       menuwork($0501);
        F3:       menuwork($0201);
        #16:      menuwork($0202);  { Ctrl-P }
        F5:       menuwork($0203);
        F7:       menuwork($0401);
        F8:       menuwork($0402);
        #3:       menuwork($0205);  { Ctrl-C }
        F10:
          begin
            onNavRedraw := doMenuRedraw;
            mw := tastmenu;
            onNavRedraw := nil;
            menuwork(mw);
          end;
      end;
      if needRedraw then
      begin
        needRedraw := false;
        break;  { exit inner loop → outer loop re-calls kalendar }
      end;
    until quit;
  until quit;
end;

{ ------------------------------------------------------------------ }

procedure pocetak;
var t: byte;
begin
  TextBackground(1);
  TextColor(7);
  ClrScr;
  for t := 1 to 24 do
    elwritecol(1, t, niz(79, ' '), co[1]);
  { Row 25: write 79 chars to avoid wrap+scroll on the last terminal row }
  elwritecol(1, 25, niz(79, ' '), co[1]);
end;

procedure zavrsetak;
var ge: integer;
    f : text;
    yj: tbstr;
    t : byte;
begin
  TextBackground(0);
  TextColor(2);
  ClrScr;
  lazarev_krst(3, 2);
  GotoXY(20, 1);
  {$I-}
  Assign(f, direct + '_GRESKE.MOL');
  Reset(f);
  {$I+}
  if IOResult = 0 then
  begin
    for ge := 1 to 19 do
    begin
      ReadLn(f, yj);
      GotoXY(20, ge + 1);
      Write(yj);
    end;
    Close(f);
  end;
  GotoXY(20, 22);
  TextColor(14);
  Write('NEA BYZANTIA');
  TextColor(2);
  WriteLn;
  showcursor;
  GotoXY(1, 25);
  NormVideo;
end;

{ ================================================================== }

procedure parseArgs;
var i: integer; a: string;
begin
  for i := 1 to ParamCount do
  begin
    a := ParamStr(i);
    if (a = '-h') or (a = '--help')    then showHelp;
    if (a = '-v') or (a = '--version') then showVersion;
  end;
end;

begin
  parseArgs;
  { Stub: keep seg_scr for any code that reads it; no video buffer access }
  seg_scr := $B800;
  setconstcol;
  ucitajKonfig;     { load saved theme before any screen painting }
  pocetak;
  initialization_; { see procedure initialization_ above }
  drawfirstscreen;
  again := true;
  repeat
    _topday := 1;
    setuskrs;
    drawscreen;
    mainwork;
  until not again;
  zavrsetak;
end.
