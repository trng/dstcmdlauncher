s/Конфигурационный файл найден/Configuration file found/g
s/Скрипт запуска выделенного сервера/Script to start a dedicated server/g
s/Для запуска обязательно наличие конфигурационного файла./Configuraton file must exist for server start.          /g
s/Два варианта запуска скрипта:/Two ways to run the script:  /g
s/(используется дефолтное имя: StartDSTwithParams.conf^)/(default name used: StartDSTwithParams.conf^)         /g
s/Если файла конфигурации с таким именем не существует,/If no config file found with this name,              /g
s/генерируется конфиг с дефолтными параметрами./config with default params will be generated./g
s/Конфигурационный файл ^( %ServerConfigFile% ^) не найден/Configuration file ^( %ServerConfigFile% ^) not found/g
s/Создать с параметрами по умолчанию? (Если "НЕТ", то просто выходим из скрипта)/Create with default params? (If "NO" - just exit from script)/g
s/Просто выходим из скрипта/Just exiting ^(from script^)/g
s/Имя кластера не может быть пустым. Попробуйте еще раз либо Ctrl-C для выхода/Cluster name cannot be empty. Try again or Ctrl-C for exit/g
s/Пробуем создать/Trying to create/g
s/Невозможно создать конфигурационный файл/Cannot create config file/g
s/Выходим из скрипта./Just exiting ^(from script^)./g
s/Пробуем загрузить параметры/Trying to load parameters/g
s/Требуются дополнительные параметры/Additional parameters needed/g
s/Скрипт будет остановлен/Script will be stopped/g
s/Проверка наличия необходимых файлов/Checking for required files/g
s/Пробуем скачать/Trying to load/g
s/Не удалось скачать/Failed to download/g
s/Удалось скачать/File downloaded/g
s/Кластер с таким именем уже существует/Cluster with the same name already exist/g
s/Будет использован новый конфигурационный файл с существующим кластером./New config file with existing cluster will be used/g
s/Продолжить? (Если "НЕТ", то просто выходим из скрипта/Continiue? (If "NO" - just exit from script)/g
s/Кластер не найден/Cluster not found/g
s/Создаем с параметрами по умолчанию/Create with default parameters/g
s/Проверяем наличие шаблонов для модов/Checking for mods templates availability/g
s/Template для модов/Template for mods/g
s/Генерируем конфигурацию кластера/Generating the cluster configuration/g
s/Имя кластера (видно в списке серверов)/Cluster name (showed in servers list)/g
s/Конфигурация создана успешно/Configuration successfully created/g
s/Папка с настройками сервера/Folder with server config/g
s/Конфигурация скрипта/Script config file/g
s/Файлы настройки модов находятся в/Mods configuration files are located in/g
s/При добавлении модов не забывайте менять оба файла/When adding mods, do not forget to change both files/g
s/ВНИМАНИЕ/ATTENTION/g
s/Сервер не будет запущен без вашего токена/Server will not start without your token/g
s/Впишите токен в/Write down the token in/g
s/Копипаст либо скачайте с/Copy-paste or download from/g
s/Сейчас скрипт будет остановлен/Script will be stopped now/g
s/Открыть cluster_token.txt в Блокноте? (Если "НЕТ", то просто выходим из скрипта)/Open cluster_token.txt in notepad? (If "NO" - just exit from script)/g
s/Не найдены папки для шардов/Shards folders not found/g
s/Найдены запущенные шарды/Running shards found/g
s/Шарды уже запущены! Остановить их? (Если "НЕТ", то просто выходим из скрипта)/Kill running shards? (If "NO" - just exit from script)/g
s/Пытаемся остановить запущенные шарды/Trying to kill runnig shards/g
s/Шарды остановлены. Можно запускать снова/Shards killed. Time to start new ones/g
s/Каталог\/файл не найден/Folder\/file not found/g
s/Каталог\/файл найден/Folder\/file found/g
s/%ESC%\[93m         Создать/%ESC%\[93m         Create/g
s/(Если "НЕТ", то просто выходим из скрипта)/(If "NO" - just exit from script)/g
s/Невозможно создать папку "%~1". Продолжение невозможно./Cannot create folder "%~1". Cannot continue/g
s/Конфигурационный файл для запуска скрипта/Configuration file to run the script     /g
s/Секции используются только для наглядности. Все параметры загружаются одним списком.   /Sections are used for illustration purposes only. All params are loaded in plain list. /g
