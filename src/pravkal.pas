{$mode tp}
{$H-}
program pravkal;
uses crt, SysUtils, nizz, kalsys1, kalmenu1, kalwork1, kaltxt;

const
  VERSION = '1.0.0';

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
  { Day-of-week initials, Cyrillic: Недеља Понедељак Уторак Среда Четвртак
    Петак Субота. String (not char) array because each glyph is multi-byte. }
  dun: array[0..6] of kstr = ('Н','П','У','С','Ч','П','С');

  { Layout driver string: 'a'=top-separator 'b'=Sunday-label 'c'=mid-separator
    digit/letter=day row.  Repeated 63-char pattern covers all week layouts. }
  tabs: array[1..63] of char =
     'abc0123456abc0123456abc0123456abc0123456abc0123456abc0123456abc';

  nedelja: array[1..19] of pathstr = (
    'Недеља о митару и фарисеју',
    'Недеља о блудном сину',
    'Недеља месопусна',
    'Недеља сиропусна',
    'Недеља прва поста - Чиста Православља',
    'Недеља друга поста - Пачиста',
    'Недеља трећа поста - Крстопоклона',
    'Недеља четврта поста - Средопосна',
    'Недеља пета поста - Глувна',
    'Недеља шеста поста - Цветна',
    'Недеља светла. На лит. ап.1.Јев.Јн зач 1 /1,1-17/',
    'Недеља друга - Томина',
    'Недеља трећа - Мироносница',
    'Недеља четврта - Раслабљеног',
    'Недеља пета - Самарјанке',
    'Недеља шеста - Слепога',
    'Недеља седма - Светих Отаца',
    'Недеља Педесетнице',
    'Недеља прва по Духовима - Свих Светих');

  brvp = 5;
  vazpr: array[1..brvp] of prstr = (
    'Благовести',
    'Воздвижење Часног Крста - Крстовдан',
    'Рождество Пресвете Богородице',
    'Ваведење Пресвете Богородице',
    'Божић - Рождество Господа Исуса Христа');

  praz: array[1..12] of array[1..31] of prstr = (
    ('cЈАН.- Обрез.ГИХр; св.Василије; Н.год. ',
     'oСвета Сила и свети Серафим Саровски',
     'oСвети пророк Малахије и св. мученик Гордије',
     'oСабор светих 70 апост.;св.Јевстатије српски',
     'mСв.мученик Теопемпт и Теона - Крстовдан',
     'cБогојављење',
     'cСабор светог Јована Крститеља - Јовањдан',
     'oПреподобни Георгије Хозевит; св.Григ.Охрид.',
     'oСвети мученик Полиевкт; св. Филип Московски',
     'oСвети Григорије Ниски и преп. Дометијан',
     'oПреподобни Теодосије Велики и преп. Михаило',
     'oСвета мученица Татијана',
     'oСвети муч. Ермил и Стратоник (Одан.Богој.)',
     'cСвети Сава први архиепископ српски',
     'oПреподобни Павле; преп. Гаврило Лесновски',
     'mЧасне вериге апостола Петра;преп.Ромил Рав.',
     'oПреподобни Антоније Велики',
     'mСвети Атанасије Велики; свети Максим Српски',
     'oПреп. Макарије Египатски; св. Марко Ефески',
     'oПреподобни Јевтимије Велики',
     'oПреп. Максим Исповедник; св.муч.Теофан',
     'oСвети апостол Тимотеј и препмуч. Анастасије',
     'oСвештеномученик Климент Анкирски и други',
     'oПреподобна Ксенија Римљанка',
     'oСвети Григорије Богослов',
     'oПреподобни Ксенофонт и Марија',
     'oПренос моштију светог Јована Златоуста',
     'oПреподобни Јефрем Сирин',
     'oПренос моштију Игњатија Богоносца',
     'cСвета Три Јерарха',
     'oСвети бесребреници Кир и Јован'),

    ('oФЕБ.-Свети мученик Трифун (Претпр.Сретења)',
     'cСретење Господње',
     'mСвети Симеон и Ана; св.Јаков архиеп. српски',
     'oПреподобни Исидор Пелусиот',
     'oСвета мученица Агапија',
     'oСвети Фотије и св.Вукол Смирн. (Одан.Срет.)',
     'oСвети Партеније Лампсакијски',
     'oСв. Теодор Стратилат; св. Сава II српски',
     'oСвети мученик Никифор',
     'mСвештеномученик Харалампије',
     'oСвештмученик Власије; св.муч. Ђорђе Крат.',
     'oСвети Малетије Антиохијски',
     'oПреподобни Симеон Мироточиви',
     'mПреподобни Авксентије; св.Кирил Словенски',
     'oСвети апостол Онисим и преп. Јевсевије',
     'oСв. муч. Памфил и Порфирије - Задушнице',
     'mСвети великомученик Теодор Тирон',
     'oСвети Лав Римски и св. Флавијан Цариградски',
     'oСвети апостоли Архип, Филимон и Апфија',
     'oСвети Лав Катански и свештеномученик Садок',
     'oПреподобни Тимотеј и свети Евстатије',
     'oСвети мученици у Евгенији',
     'oСвештеномученик Поликарп Смирнски',
     'mI и II обр. главе светог Јована Крститеља',
     'oСвети Тарасије Цариградски',
     'oСвети Порфирије епископ гаски',
     'oПреподобни Прокопије Декаполит',
     'oПреподобни Василије Исповедник',
     'oПреподобни Јован Касијан',
     'oПреп. Василије Испов. и преп. Јован Касијан',''),

    ('oМАРТ- Преподобномученица Евдокија',
     'oСвештеномученик Теодот Киринејски',
     'oСвети мученици Евтропије,Калиник и Василиск',
     'oПреподобни Герасим Јордански',
     'oСвети мученик Конон и преп. Марко Подвижник',
     'oСветих 42 мученика из Амореје',
     'oСветих 7 свештеномученика херсонских',
     'oСвети Теофилакт Исповедник',
     'mСветих 40 мученика севастијских - Младенци',
     'oСвети мученик Кодрат Коринтски',
     'oСвети Софроније Јерусалимски',
     'oСвети Григорије Двој., преп.Теофан и Симеон',
     'oПренос моштију светог Никифора Цариградског',
     'oПреподобни Бенедикт Нурсијски',
     'oСвети мученик Агапије',
     'oСвети Аристовул, мученици Папа и Савин',
     'mПреподобни Алексије - човек Божји',
     'oСвети Кирил Јерусалимски',
     'oСвети мученици Хризант, Дарија и други',
     'oПрепмуч. Јован, Сергије, Патрикије и други',
     'oПреподобни Јован Исповедник',
     'oСвештеномученик Василије Анхирски',
     'oПреподобномученик Никон и други',
     'oПреподобни Захарије (Претпр. Благовести)',
     'cБлаговести',
     'oСабор св. арх. Гаврила (Одан.Благ.-I бден)',
     'oПреподобна Матрона Солунска',
     'oПреподобни Иларион Нови (II бденије)',
     'oСвештеномученик Марко Аретуски',
     'oПреподобни Јован Лествичник',
     'oПреподобни Ипатије Гангријски'),

    ('oАПРИЛ- Преподобна Марија Египчанка',
     'oПреподобни Тит Чудотворац',
     'oПреподобни Никита Исповедник',
     'oПреподобни Јосиф Химнограф',
     'mМученик Агапод',
     'oСвети Евтихије и преподобни Григорије',
     'oСвети Грогорије Исповедник',
     'oСвети апостоли Иродион, Агав и други',
     'oСвети мученик Евпеихије',
     'oСвети мученик Терентије, Помпије',
     'oСвештеномученик Антипа Пергамски',
     'oПреподобни Василије Исповедник',
     'oСвештеномученик Артемон',
     'oСвети Матрин Исповедник',
     'oСвети апостоли Аристарх, Труд и Трофим',
     'oСвете мученице Агапија, Хионија и Ирина',
     'oСвештеномученик Симеон Персијски',
     'oПреподобни Јован',
     'oПреподобни Јован Ветхопештерник',
     'oПреподобни Теодор; преп. Јоасаф српски',
     'oСвештеномученик Јануарије',
     'oПреподобни Теодор Сикеот',
     'cСвети великомученик Георгије - Ђурђевдан',
     'oСвети Сава Стратилат; свети Сава Ердељски',
     'mСвети апостол и јеванђелист Марко',
     'oСвештеномученик Василије Амасијски',
     'oСпаљивање моштију светог Саве',
     'oСвети апостоли Јасон и Сосипатр',
     'oСвети Василије Острошки',
     'oСвети апостол Јаков Зеведејев',''),

    ('mМАЈ- Свети пророк Јеремија',
     'oСвети Атанасије Велики',
     'oСвети мученици Тимотеј и Мавра',
     'oСвета мученица Пелагија Тарсијска',
     'oСвета великомученица Ирина',
     'oПреподоб. Јован; пренос моштију светог Саве',
     'oПојава Часног Крста у Јерусалиму',
     'mСвети апостол и јеванђелист Јован Богослов',
     'mПренос моштију светог Николе',
     'oСимон Зилот; преподобна Исидора',
     'cСвети Цирило и Методије; Никодим српски',
     'oСвети Епифаније и свети Герман',
     'oСвета мученица Гликерија',
     'oСвети мученик Исидор',
     'oПреподобни Пахомије Велики',
     'oПреподобни Теодор Освећени',
     'oСвети апостол Андроник и Јулија',
     'oСвети мученик Теодор Анкирски',
     'oСвештеномученик Патрикије Пруски',
     'oСвети мученик Талалеј; Стефан Пиперски',
     'cСвети цар Константин и царица Јелена',
     'oСвети Јован Владимир',
     'oПреподобни Михаило Исповедник',
     'oПреподобни Симеон Дивногорац',
     'mТреће обретење главе св. Јована Крститеља',
     'oСвети апостол Карп',
     'oСвештеномученик Терапонт',
     'oПреподобни Никита Исповедник',
     'oПреподобномученица Теодосија Тирска',
     'oПреподобни Исакије Далматски',
     'oСвети апостол Јерма и свети мученик Ермије'),

    ('oЈУН- Мученик Јустин Филозоф',
     'oСвети Никифор; свештеномуч. Еразмо Охридски',
     'oСвети мученик Лукијан и други',
     'oСвети Митрофан и св. мирон. Марта и Марија',
     'oСвештеномученик Доротеј; преп.Петар Кориски',
     'oПреподобни Висарион и Иларион Нови',
     'oСвештмуч. Теодот Анкирски',
     'oСвети великомученик Теодор Стратилат',
     'oСвети Кирило Александријски',
     'oСвештеномученик Тимотеј Пруски',
     'mСвети апостоли Вартоломеј и Варнава',
     'oПреподобни Онуфрије Велики',
     'oСвета мученица Акилина и свети Трифилије',
     'mСвети пророк Јелисеј; свети Методије',
     'cСв. вмуч. цар Лазар и срп.св.муч.- Видовдан',
     'oСвети Тихон Аматунски Чудотворац',
     'oСвети мученици Мануил, Савел и Исмаил',
     'oСвети мученици Леонтије, Ипатије и Теодул',
     'oСвети ап. Јуда и преподобни Пајсије Велики',
     'oСвештеномучен. Методије; преп.Наум Охридски',
     'oСвети мученик Јулијан Тарсијски',
     'oСвештеномуч.Јевсевије; преп.Анастасија Срп.',
     'oСвета мученица Агрипина; Влад. икона М. Б.',
     'cРождество св. Јована Крститеља - Ивањдан',
     'oПреподобномученица Февронија',
     'oПреподобни Давид Солунски',
     'oПреподобни Сампсон Странопримац',
     'oПренос моштију св.бесребеника Кира и Јована',
     'cСвети апостоли Петар и Павле - Петровдан',
     'oСабор светих 12 апостола',''),

    ('mЈУЛ- Св. муч. и бесребреници Козма и Дамјан',
     'oПолагање ризе Пресвете Богородице',
     'oСвети мученик Јакинт и преподобни Анатолије',
     'oСвети Андреј Критски и преподобна Марта',
     'oПреп. Атанасије Атон; Сергије Радоњешки',
     'oПреподобни Сисоје Велики',
     'oПреподобни Тома Малеин и св. муч. Недења',
     'mСвети великомученик Прокопије',
     'oСвештеномученик Панкратије и свети Теодор',
     'oСветих 45 мученика и Никопоља',
     'oСв. великомученица Ефимија и Блажена Олга',
     'oСвети мученици Прокло и Иларије',
     'mСабор светог архангела Гаврила',
     'oСвети апостол Акила и преподобни Никодим',
     'mСвети мученик Кирик и Јулита; св. Владимир',
     'oСвештеномуч. Атиноген; св. мученица Јулија',
     'mСвета великомуч. Марина (Огњена Марија)',
     'oСвети мученик Емилијан и мученик Јакинт',
     'oСвети Стефан и препод. Евгенија (Лазаревић)',
     'cСвети пророк Илија; свети Илија Грузијски',
     'oСвети пророк Језекиљ',
     'oСвета Марија Магдалина (Блага Марија)',
     'oСвети мученици Трофим, Теофил и други',
     'oСвета мученица Христина',
     'oУспеније свете Ане',
     'mПрепмуч.Параскева (Трнова);Св.Сава III срп.',
     'mСвети велмуч. Пантелејмон; св. Климент Охр.',
     'oСв.ап. и ђакон Прохор,Никанор,Пармен и др.',
     'oСвети мученик Калиник и мученица Серафима',
     'oПреподобна мати Ангелина српска',
     'oСвети Евдоким'),

    ('mАВГУСТ- Изношење Часног Крста; Макавеји',
     'oПренос мост. св.првомуч. и архиђак.Стефана',
     'oПреподобни Исакије, Далмат и Фауст',
     'oСветих седам мученика у Ефесу',
     'oСвети муч. Евсигније (Претпр. Преображења)',
     'cПреображење Господње',
     'oПреподобномученик Дометије и преподобни Ор',
     'oСв. Емилијан Исп.; преп. Зосим Тумански',
     'oСв. апостол Матија и св. мученик Антоније',
     'oСвети мученик и архиђакон Лаврентије',
     'oСвети мученик и архиђакон Евпло',
     'oСвети мученици Фотије, Аникита и други',
     'oСвети мученик Иполит (Оданије Преображења)',
     'oСвети пророк Михеј (Претпр. Успенија)',
     'cУспеније Пресв. Богород.- Велика Госпојина',
     'oСв.Јевстатије, преп.Роман, Рафаило Банат.',
     'oСвети мученици Мирон и Патрокло',
     'oСвети мученик Флор; преподобни Јован Рилски',
     'oСвети мученик Андреј Стратилат',
     'oСвети пророк Самуило и свештмуч. Самуило',
     'oСв.ап.Тадеј; св.мученица Васа и њена деца',
     'mСвети муч. Агатоник; свештмуч. Горазд Чеш.',
     'oСвештеномученик Иринеј и мученик Луп',
     'oСвештеномученик Евтихије; мученица Сара',
     'oПренос мост.св.ап.Вартоломеја и св.ап.Тит',
     'mСвети мученици Адријан и Наталија',
     'oПреподобни Пимен Велики',
     'oПреподобни Мојсеј Мурин и Сава Псковски',
     'cУсековање главе светог Јована Крститеља',
     'mСв. Алексан. Невски; Кирил,Никон и Макарије',
     'oПолагање појаса Пресвете Богородице'),

    ('mСЕПТ.- Преп. Симеон Столпник - Црквена Н.г.',
     'oСвети мученик Мамант; свети Јован Постник',
     'oСвесмуч.Антим;св.Јоаникије I патријарх срп.',
     'oСвештмуч. Вавила; пророк Мојсеј Боговилац',
     'oСвети пророк Захарија и прав. Јелисавета',
     'oЧудо св. архан. Михаила; св. муч. Евдоксије',
     'oСвети муч. Созонт (Претпр. Рожд. Пр. Бог.)',
     'cРождество Пресв.Богородице (Мала Госпојина)',
     'mСвети праведни Јоаким и Ана',
     'oМученице Минодора, Митродора и Нимфодора',
     'oПреподобна Теодора; преп. Сергије и Герман',
     'oСвештмуч. Автоном (Од. Рож. Пресв. Бог.)',
     'oСвештмученик Корнилије (Претпр.Воздвижења)',
     'cВоздвижење Часног Крста - Крстовдан',
     'oВеликомученик Никита; св.Јосиф Темишварски',
     'oВелмуч. Јефимија; преп. Доротеј и Кипријан',
     'mМуч. Вера, Нада и Љубав и мати им Софија',
     'oСв. Евменије Гортински; мученица Арнадна',
     'oСв. муч. Трофим, Саватије и Доримедонт',
     'mСвети великомученик Јевстатије',
     'oСвети апостол Кодрат (Оданије Воздвижења)',
     'oСвештеномученик Фока и пророк Јона',
     'mЗачеће светог Јована Крститеља',
     'oПрвомуч. Текла; пепр. Симон Владислав и др.',
     'oПреподобна Ефросинија и Сергије Радоњешки',
     'mСвети апостол и јеванђелист Јован Богослов',
     'oСвети мученик Калистрат',
     'oПрепод. Харитон Исповедник; мученик Марко',
     'mПреп. Киријак Отселник - Михољдан',
     'oСвештеномученик Григорије и свети Михаил',''),

    ('mОКТОБАР- Покров Пресвете Богородице',
     'oСвештеномученик Кипријан и преп. Андреј',
     'oСвештеномученик Дионисије Ареопагит',
     'oСвети Стефан и Јелена (Стиљановић)',
     'oСвети муч. Харитина; свештмуч. Дионисије',
     'mСвети Тома - Томиндан',
     'mСвети мученици Сергије и Вакхо - Срђевдан',
     'oПреподобна Пелагија и преподобна Таиса',
     'oСвети ап.Јаков; свети Стефан српски (Слепи)',
     'oСвети мученици Евлампије и Евлампија',
     'oСвети апостол Филип и св. Теофан Нацертани',
     'oСвети мученици Тарах, Пров и Андроник',
     'oСв. муч. Карп; новомученица Злата Магленска',
     'cПреподобна мати Параскева - Света Петка',
     'oСвештеномученик Лукијан и преп. Јевтимије',
     'oСвети мученик Лонгин Сотник',
     'oСвети пророк Осија; препмуч. Андреј Критски',
     'mСвети ап. и јеван. Лука; св.Петар Цетињски',
     'oПрор.Јоил; преп. Прохор Пчињски и Јов.Рил.',
     'oВеликомученик Артемије',
     'oПреподобни Иларион; св. Иларион и Висарион',
     'oСвети равноапостолни Аверкије Јерапољски',
     'mСвети ап. Јаков, први епископ јерусалимски',
     'oСвети великомученик Арета',
     'oСвети мученици Макријан и Мартирије',
     'cСвети великомученик Димитрије - Митровдан',
     'oСвети мученик Нестор',
     'oСвети муч. Терентије; свети Арсеније Сремац',
     'mСвети Аврамије Затворник',
     'oСвети краљ Милутин, Теоктист и Јелена',
     'oСв. апостоли Стахије, Амплије, Урвин и др.'),

    ('mНОВЕМБАР- Свети Козма и Дамјан - Врачеви',
     'oСвети мученици Акиндин, Пигасије и др.',
     'mОбновљење храма св. Георгија - Ђурђиц',
     'oПреп. Јоаникије Велики; свештмуч. Никандар',
     'oПреподобномученици Галактион и Епистима',
     'oСвети Павле Исповедник',
     'oСветих 33 мученика у Мелитини; преп. Лазар',
     'cСабор светог архан. Михаила - Аранђеловдан',
     'oСв. муч. Онисифор и Порфирије; Нектар. Ег.',
     'oСвети апостоли Олимп, Ераст, Родион и др.',
     'oСвети краљ Стефан Дечански - Мратиндан',
     'mСвети Јован Милостиви; преп. Нил Синајски',
     'mСвети Јован Златоусти',
     'mСвети апостол Филип',
     'oСвети мученик Гурије',
     'mСвети апостол и јеванђелист Матеј',
     'oСвети Григорије Чудотворац; Никон Радоњски',
     'oСвети мученици Платон, Роман и други',
     'oПророк Авдија; преподобни Варлаам и Јоасаф',
     'oПреп. Григорије Декаполит (Претпр. Вавед.)',
     'cВаведење Пресвете Богородице',
     'oСвети апостоли Филимон, Апфија и Архип',
     'oСвети Амфилохије и свети Григорије',
     'mВеликомученица Екатарина; Меркурије',
     'mСвештеномученик Климент (Одан. Ваведења)',
     'mСвети Алимпије Столпник',
     'oСвети мученик Јаков Персијанац',
     'oПреподобномученик Стефан; свети муч. Христо',
     'oСвети мученици Парамон, Филумен и други',
     'mСвети апостол Андреј Првозвани',''),

    ('oДЕЦЕМБАР- Пророк Наум и свети Филарет',
     'oСвети цар Урош и преп. Јоаникије Девички',
     'oПророк Софонија и преподобни Јован Ћутљиви',
     'mВеликомученица Варвара; преп.Јован Дамаскин',
     'mПреп.Сава Освећени; Нектарије Битољски',
     'cСвети Никола - Никољдан',
     'oСвети Амвросије; преподоб. Григорије Горњ.',
     'oПреп. Патапије; св.ап. Состен, Аполос и др.',
     'oЗачеће свете Ане',
     'oСвета мученица Мина; свети Јован Српски',
     'oПреподобни Данило Столпник',
     'mПреподобни Спиридон Чудотворац',
     'oМученик Евстратије; св. Гаврило и Никодим',
     'oСвети муч. Тирс, Левкије, Филимон и др.',
     'oСвештеномученик Елевтерије и преп. Павле',
     'oПророк Агеј и света Теофанија',
     'oПророк Данило; препмученик ђакон Авакум',
     'oСвети мученик Севастијан;свети Модерт и др.',
     'mСвети мученик Бонифације',
     'mСв.Игњатије Бог.; Дан.II Срп. (Прет.Рожд.)',
     'oСвета мученица Јулијана и св.Петар Кијевски',
     'oСвета великомученица Анастасија',
     'oСв. 10 мученика Критских; преп. Наум Охр.',
     'oПреподобномученица Евгенија - Бадњи дан',
     'cРождество Христово - Божић',
     'cСабор Пресвете Богородице',
     'cСвети првомученик и архиђакон Стефан',
     'oСветих 20.000 мученика Никомидијских',
     'oСветих 14.000 младенаца Витлејемских',
     'oСвета мученица Анисија и преподобна Теодора',
     'oПреподобна Меланија (Оданије Рождества)'));

  praz_p: array[1..12] of prstr = (
    'cУлазак Г. И. Христа у Јерусалим - Цвети',
    'mВелики четвртак (Велико бденије)',
    'cВелики петак',
    'mВелика субота',
    'cВаскрсење Господа Исуса Христа - Васкрс',
    'cВаскрсни понедељак',
    'cВаскрсни уторак',
    'cВазнесење Господње - Спасовдан',
    'cСилазак Светог Духа - Педесетница - Тројице',
    'cДуховски понедељак',
    'cДуховски уторак',
    'cВаскрсење Христово - Васкрс - Благовести');

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
  da      : string[12];
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
  mainm[1] := 'Деск';      mainm[2] := 'Опције';
  mainm[3] := 'Трагање';   mainm[4] := 'Штампање';
  mainm[5] := 'Помоћ';
  mainh[1] := 'Деск информације';
  mainh[2] := 'Главне команде (промена датума, табела постова, излазак)';
  mainh[3] := 'Претраживања у календару (налажење имена празника, недеља, итд.)';
  mainh[4] := 'Извоз месечног календара или табеле постова у TXT';
  mainh[5] := 'Помоћ и упутство за коришћење Православног календара';
  for gu := 1 to mmmax do
  begin
    mmpos[gu] := mmpos_[gu];
    mmpol[gu] := mmpol_[gu];
    mmdim[gu][1] := mmdim_[gu][1];
    mmdim[gu][2] := mmdim_[gu][2];
    mmnli[gu] := mmnli_[gu];
    mmcrt[gu] := mmcrt_[gu];
  end;
  mmsss[1][1] := 'Програм...';
  mmsss[2][1] := 'Активни датум      F3';
  mmsss[2][2] := 'Постови        Ctrl-P';
  mmsss[2][3] := 'Хеортологија       F5';
  mmsss[2][4] := 'Индиктион';
  mmsss[2][5] := 'Излазак        Ctrl-C';
  mmsss[3][1] := 'Тражење датума';
  mmsss[3][2] := 'Тражење празника';
  mmsss[3][3] := 'Тражење поста';
  mmsss[3][4] := 'Тражење недеље';
  mmsss[4][1] := 'Извоз месеца у TXT    F7';
  mmsss[4][2] := 'Извоз постова у TXT  F8';
  mmsss[4][3] := 'Конфигурација';
  mmsss[4][4] := 'Снимање конфигурације';
  mmsss[5][1] := 'Помоћ          F1';
  mmsss[5][2] := 'Садржај    Alt-F1';
  for gu := 1 to mmmax do mmpcm[gu] := 1;
  kfun[1].sta[1] := 'F1';  kfun[1].sta[2] := 'Помоћ';           kfun[1].kps := 2;
  kfun[2].sta[1] := 'F3';  kfun[2].sta[2] := 'Промена датума';  kfun[2].kps := 12;
  kfun[3].sta[1] := 'F5';  kfun[3].sta[2] := 'Хеортологија';    kfun[3].kps := 31;
  kfun[4].sta[1] := 'F7';  kfun[4].sta[2] := 'Штампање месеца'; kfun[4].kps := 48;
  kfun[5].sta[1] := 'F10'; kfun[5].sta[2] := 'Мени';            kfun[5].kps := 69;
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
  { Table separators (single-line box glyphs). Column widths: D=3 G=4 J=5 feast=45.
    gnd/dnd/pktab cross the column lines (├─┼─┼─┼─┤); zatvtab closes the table
    bottom (└─┴─┴─┴─┘). }
  gnd     := BOX_LTEE + nizs(3,BOX_H) + BOX_CROSS + nizs(4,BOX_H) + BOX_CROSS + nizs(5,BOX_H) + BOX_CROSS + nizs(45,BOX_H) + BOX_RTEE;
  dnd     := gnd;
  pktab   := gnd;
  zatvtab := BOX_LLC + nizs(3,BOX_H) + BOX_BTEE + nizs(4,BOX_H) + BOX_BTEE + nizs(5,BOX_H) + BOX_BTEE + nizs(45,BOX_H) + BOX_LRC;
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
    BOX_V + '   ' + BOX_V + '    ' + BOX_V + '     ' + BOX_V + niz(45, ' ') + BOX_V,
    co[2]);
end;

procedure tekdat;
begin
  openwind(67, 16, 79, 24, 27, 27, '', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwrite(69, 17, imm[_m] + niz(10 - dlen(imm[_m]), ' '));
  elwrite(69, 19, prsl(_g));
  elwrite(69, 20, strf(_g) + '   ');
  elwrite(69, 22, strf(indiktiong(_g)) + '.');
  elwrite(69, 23, 'индиктион');
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
  elwritecol(2, 2, BOX_ULC + nizs(60, BOX_H) + BOX_URC, co[2]);
  elwritecol(2, 4, BOX_LTEE + nizs(3,BOX_H) + BOX_TTEE + nizs(4,BOX_H) + BOX_TTEE + nizs(5,BOX_H) + BOX_TTEE + nizs(45,BOX_H) + BOX_RTEE, co[2]);
  elwritecol(2, 5, BOX_V + ' Д ' + BOX_V + '  Г ' + BOX_V + '  Ј  ' + BOX_V + ' Православни празник' + niz(25, ' ') + BOX_V, co[4]);
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
  elwrite(2, 3, BOX_V + niz(60, ' ') + BOX_V);
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
  scrNorm;
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
        im := 'Недеља ' + strf(imi[fv] - 1000) + '. по Духовима';
      if (imi[fv] >= 100) and (imi[fv] <= 999) then
        im := 'Недеља ' + strf(imi[fv] - 100) + '. по Духовима';
      if imi[fv] <= 19 then
        im := nedelja[imi[fv]];
    end;
  imened := im;
end;

procedure writenedelja(dn, ms, gd: integer);
var im: pathstr;
begin
  elwritecol(2, gd, BOX_V + niz(60, ' ') + BOX_V, co[2]);
  im := imened(dn, ms);
  elwritecol(32 - (dlen(im) div 2), gd, im, co[15]);
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
  if brmdg(_m, _g) mod 10 <> 1 then da := 'дана' else da := 'дан';
  elwritecol(4, 3, strf(_g), co[17]);
  elwritecol(59 - dlen(da), 3, strf(brmdg(_m, _g)) + ' ' + da, co[17]);
  elwritecol(32 - (dlen(imm[_m]) div 2), 3, upcasestr(imm[_m]), co[15]);
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
    elwritecol(2, 24, BOX_LLC + nizs(60, BOX_H) + BOX_LRC, co[2]);
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
  addLine(BOX_ULC + nizs(60, BOX_H) + BOX_URC);
  buf := BOX_V + ' ' + strf(_g) + niz(4 - length(strf(_g)), ' ') +
         niz(25 - (dlen(imm[_m]) div 2), ' ') +
         upcasestr(imm[_m]) +
         niz(21 - (dlen(imm[_m]) div 2), ' ');
  if dlen(imm[_m]) mod 2 = 0 then buf := buf + ' ';
  buf := buf + niz(4 - dlen(da), ' ') + strf(brmdg(_m, _g)) + ' ' + da + ' ' + BOX_V;
  addLine(buf);
  addLine(dnd);
  addLine(BOX_V + ' Д ' + BOX_V + '  Г ' + BOX_V + '  Ј  ' + BOX_V + ' Православни празник' + niz(25, ' ') + BOX_V);
  if mtt__ <> 2 then addLine(pktab) else addLine(gnd);

  drj := di; drm := mi; xcv := gi; d_d := _dd; qww := mtt__; dan := 0;
  while dan < brmdg(_m, _g) do
  begin
    case tabs[qww] of
      'a': addLine(gnd);
      'b': begin
             imnd := imened(drj, drm);
             addLine(BOX_V + niz((60 - dlen(imnd)) div 2, ' ') + imnd +
                     niz(60 - dlen(imnd) - (60 - dlen(imnd)) div 2, ' ') + BOX_V);
           end;
      'c': addLine(dnd);
    else
      begin
        inc(dan);
        imnd := imepraz(drj, drm, xcv);
        { Column widths from separator +---+----+-----+---...---+:
            D=3  G=4  J+fast=5  feast=45 }
        buf := BOX_V + ' ' + dun[d_d] + ' ' + BOX_V +
               niz(3 - length(strf(dan)), ' ') + strf(dan) + ' ' + BOX_V +
               niz(3 - length(strf(drj)), ' ') + strf(drj) + ' ';
        if _post[drm][drj] then buf := buf + BOX_BULL else buf := buf + ' ';
        buf := buf + BOX_V + ' ' + copy(imnd, 2, length(imnd) - 1) +
               niz(45 - dlen(imnd), ' ') + BOX_V;
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
    openwind(8, 10, 71, 15, co[27], co[27], ' Извоз у TXT ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'TXT снимљен:', co[4]);
    elwritecol(10, 12, fname, co[15]);
    waitKey('');
  end
  else
  begin
    openwind(8, 10, 71, 15, co[27], co[27], ' Грешка ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(10, 11, 'Грешка при снимању TXT фајла!', co[6]);
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
    scrGoto(x, y);
    scrAttr(co[15]);
    scrPut(buf + niz(maxlen - dlen(buf), ' '));
    scrGoto(x + dlen(buf), y);
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
  scrNorm;
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
           ' Тражење датума ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  ok := false;
  repeat
    elwritecol(X1+2, Y1+2, 'Дан   (1-31): ', co[4]);
    scrGoto(X1+16, Y1+2);
    scrAttr(co[15]);
    Str(nd, s); scrPut(s + '   ');
    elwritecol(X1+2, Y1+3, 'Месец (1-12): ', co[4]);
    scrGoto(X1+16, Y1+3);
    scrAttr(co[15]);
    Str(nm, s); scrPut(s + '   ');
    elwritecol(X1+2, Y1+4, 'Година:       ', co[4]);
    scrGoto(X1+16, Y1+4);
    scrAttr(co[15]);
    Str(ng, s); scrPut(s + '     ');
    scrNorm;
    if nd > brmdg(nm, ng) then nd := brmdg(nm, ng);
    setjulijan(nd, nm, ng, jd, jm, jy, true);
    feast   := imepraz(jd, jm, jy);
    nedname := imened(jd, jm);
    elwritecol(X1+2, Y1+6,
      'Јулиј: ' + strf(jd) + '.' + strf(jm) + '.' + strf(jy) + '.     ', co[17]);
    elwritecol(X1+2, Y1+7, niz(52, ' '), co[17]);
    elwritecol(X1+2, Y1+7, 'Празник: ' + copy(feast, 2, length(feast)), co[15]);
    if _post[jm][jd] then
      elwritecol(X1+2, Y1+8, 'Пост: ДА              ', co[19])
    else
      elwritecol(X1+2, Y1+8, 'Пост: -               ', co[17]);
    elwritecol(X1+2, Y1+9, niz(52, ' '), co[17]);
    if nedname <> '' then
      elwritecol(X1+2, Y1+9, nedname, co[16]);
    elwritecol(X1+2, Y1+11, '</>  = дан,  PgUp/PgDn = месец,  +/- = год.', co[17]);
    elwritecol(X1+2, Y1+12, 'Enter = иди на месец,   Esc = одустани', co[17]);
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
           ' Тражење празника ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  elwritecol(X1+2, Y1+2, 'Унеси део назива празника:', co[4]);
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
          { feast names fit the 65-wide result window; no byte-cut truncation
            (would split a UTF-8 Cyrillic sequence and corrupt the glyph) }
        end;
    end;
  openwind(X1, Y1, X2, Y2, co[27], co[27],
           ' Резултати: ' + strf(rcount) + ' ', 0,
           false, false, false, false, wsingle, 0, 0, true, false, 0);
  if rcount = 0 then
  begin
    elwritecol(X1+2, Y1+2, 'Није пронађен ниједан празник.', co[17]);
    waitKey(' Притисните било који тастер...');
    exit;
  end;
  pg    := 1;
  pgmax := (rcount + PERPAGE - 1) div PERPAGE;
  repeat
    elwritecol(X1+2, Y1+1, 'Датум      Празник' + niz(50, ' '), co[15]);
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
        'Стр. ' + strf(pg) + '/' + strf(pgmax) +
        '   PgUp/PgDn=страна   Esc=затвори', co[17]);
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
      waitKey(' Притисните било који тастер...');
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
             ' Тражење поста ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(X1+2, Y1+2,
      'Месец: ' + imm[nm] + niz(40, ' '), co[15]);
    elwritecol(X1+2, Y1+3, nizs(66, BOX_H), co[27]);
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
      elwritecol(X1+2, Y1+4, 'Нема посних дана у овом месецу.', co[17])
    else
      while nrow <= Y1+16 do
      begin
        elwritecol(X1+2, nrow, niz(67, ' '), co[2]);
        inc(nrow);
      end;
    elwritecol(X1+2, Y1+17, 'PgUp/PgDn = месец,  Esc = затвори', co[17]);
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
  if total < 1 then begin waitKey(' Нема података. '); exit; end;
  pg    := 1;
  pgmax := (total + PERPAGE - 1) div PERPAGE;
  repeat
    openwind(X1, Y1, X2, Y2, co[27], co[27],
             ' Недеље ' + strf(_g) + ' (' + strf(total) + ') ', 0,
             false, false, false, false, wsingle, 0, 0, true, false, 0);
    elwritecol(X1+2, Y1+1, 'Датум (јул.)   Назив недеље' + niz(40, ' '), co[15]);
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
        'Стр. ' + strf(pg) + '/' + strf(pgmax) +
        '   PgUp/PgDn=страна   Esc=затвори', co[17]);
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
      waitKey(' Притисните било који тастер...');
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
  scrAttrFB(7, 1);
  scrCls;
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
  scrAttrFB(2, 0);
  scrCls;
  lazarev_krst(3, 2);
  {$I-}
  Assign(f, direct + '_GRESKE.MOL');
  Reset(f);
  {$I+}
  if IOResult = 0 then
  begin
    for ge := 1 to 19 do
    begin
      ReadLn(f, yj);
      scrGoto(20, ge + 1);
      scrPut(yj);
    end;
    Close(f);
  end;
  scrGoto(20, 22);
  scrAttrFB(14, 0);
  scrPut('NEA BYZANTIA');
  scrAttrFB(2, 0);
  showcursor;
  scrGoto(1, 25);
  scrNorm;
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
