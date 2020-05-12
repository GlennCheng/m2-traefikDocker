# Docker with Traefik
此Repository可同台機器中使用同一份網站的docker-compose.yml來啟動多台站台,

透過Traefik反向代理不需再個別站台修改nginx port or mysql port等等會衝突的設定, 每個站台可以有自己一套獨立的services
(eg. nginx, php-cli, php-fpm, mysql)

並經過監聽80,8080,443,3306等port, 及label的設定, 
透過domain name, subdomain即可進入你想要的web applicaiton中

## 使用說明
首先 請clone此repo

---

## Traefik
先將trarfik啟動

```bash
$ cd traefik/ && docker-compose up -d
```
由於trarfik是共用的反向代理會去監聽設定的port 再看request的domain跟subdomain符合哪一個站的label, 所以只要起動一次就好其他站台不需要再啟動

___

## Magento2
在此repo根目錄中除了docker-compose.yml之外還有另外一隻docker-run.sh檔案

如果單純啟動或是進去docker-compose.yml會看到裏面有設定了一些環境變數

這些環境變數就是需要透過docker-run.sh及給定的參數來給予
首先我們要先設定一些基本的環境變數

### 環境變數設定
在config裏面會看到有
docker-<local|dev|staging|production>-env.sh
等等四隻檔案, 顧名思義裡面就是設定對應環境的環境變數

先將 DOMAINNAME改為你自訂的domain

```bash 
unset DIRNAME;  
unset DOMAINNAME;  
unset GIT_COMMIT_HASH;  
unset DOCKER_PREFIX;  
  
export DOMAINNAME='magento2-test.com'
```
再確認及修改```config/<local|dev|staging|production>```四個資料夾中, magento裡面的config.php還有env.php
- magento/config.php:app/etc/config.php
- magento/env.php:app/etc/env.php

#### DB預設
```bash
MYSQL_DATABASE: magento  
MYSQL_PASSWORD: magento  
MYSQL_ROOT_PASSWORD: root  
MYSQL_USER: magento
```

---
### 啟動服務

直接執行./docker-run.sh可以看到有什麼參數需要帶入
```bash
$ ./docker-run.sh
usage: <docker-run> <local|dev|staging|production> options:<s:|c|d>
```

- 必選參數```<local|dev|staging|production>```為環境 會依照輸入值去設定變數值:
	 * local 會對應到 config/docker-local-env.sh
	 * dev 會對應到 config/docker-dev-env.sh
	 * 以此類推
- 可選參數
	 * -d: deamon背景模式, 如同docker-compose up -d
	 * -c: 使用當下的commit hash當作subdomain
	 * -s: 自訂義subdomain

例如：
```bash
$ ./docker-run.sh local -d
```
```bash
$ ./docker-run.sh dev -c 
```
```bash
$ ./docker-run.sh dev -s thisisyoursubdomain -d
```
(別忘了把domain跟subdomain加入你的hosts或是網站的DNS服務中)


#### ***執行***
執行後會看到如下
```bash
networks:  
network-back:  
external: true  
traefik_default:  
external: true  
services:  
cli:  
command: bash -c "php bin/magento setup:store-config:set --base-url='http://your-domain.name/';  
php bin/magento setup:store-config:set --base-url-secure='https://your-domain.name/';  
php bin/magento cron:install; rm -rf /app/generated/*; tail -f /dev/null"  
image: magento/magento-cloud-docker-php:7.2-cli-1.1  
links:  
- mysql  
networks:  
network-back: null  
volumes:  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/src:/app:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/.user.ini:/app/pub/.user.ini:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/env.php:/app/app/etc/env.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/config.php:/app/app/etc/config.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:ro  
- /home/glenn/snap/docker/423/.composer/cache:/root/.composer/cache:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/auth.json:/root/.composer/auth.json:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/bin/composer:/usr/local/bin/composer:delegated  
fpm:  
environment:  
MAGENTO_RUN_MODE: developer  
UPDATE_UID_GID: "true"  
VERBOSE: "true"  
image: magento/magento-cloud-docker-php:7.2-fpm-1.1  
links:  
- mysql  
networks:  
network-back: null  
volumes:  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/src:/app:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/.user.ini:/app/pub/.user.ini:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/env.php:/app/app/etc/env.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/config.php:/app/app/etc/config.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:ro  
- /home/glenn/snap/docker/423/.composer/cache:/root/.composer/cache:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/auth.json:/root/.composer/auth.json:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/bin/composer:/usr/local/bin/composer:delegated  
mysql:  
environment:  
MYSQL_DATABASE: magento  
MYSQL_PASSWORD: magento  
MYSQL_ROOT_PASSWORD: root  
MYSQL_USER: magento  
hostname: m2-traefikdocker.mysql  
image: mysql:5.7  
labels:  
traefik.docker.network: traefik_default  
traefik.enable: "true"  
traefik.tcp.routers.m2-traefikdocker.entrypoints: mysql  
traefik.tcp.routers.m2-traefikdocker.rule: HostSNI(`*`)  
networks:  
network-back: null  
traefik_default: null  
volumes:  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/var/mysql/dbdata:/var/lib/mysql:rw  
web:  
environment:  
VERBOSE: "true"  
image: magento/magento-cloud-docker-nginx:latest  
labels:  
traefik.docker.network: traefik_default  
traefik.enable: "true"  
traefik.http.routers.m2-traefikdocker.rule: Host(`your-domain.name`)  
traefik.http.services.m2-traefikdocker.loadbalancer.server.port: '80'  
links:  
- fpm  
networks:  
network-back: null  
traefik_default: null  
volumes:  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/src:/app:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/.user.ini:/app/pub/.user.ini:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/env.php:/app/app/etc/env.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/magento/config.php:/app/app/etc/config.php:rw  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/config/dev/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:ro  
- /home/glenn/snap/docker/423/.composer/cache:/root/.composer/cache:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/auth.json:/root/.composer/auth.json:delegated  
- /home/glenn/src/AstralWebInc/Projects/m2-traefikDocker/composer/bin/composer:/usr/local/bin/composer:delegated  
version: '3.0'

---  
  
# ===============================================================================  
#containar prefix: m2-traefikdocker  
#host: your-domain.name  
#database host: m2-traefikdocker.mysql  
# ===============================================================================

Please make sure the config, Do you want to run the docker according to the above config? [y/n] :
```

#### 重要資訊
最重要的是最後三行
```bash
#containar prefix: m2-traefikdocker  
#host: your-domain.name  
#database host: m2-traefikdocker.mysql
```
- containar prefix: 此站台docker containar name的prefix, 可以透過```$ docker ps -a``` 看到
- host: 站台url
- database host: db透過tcp/ip連線方式的host, port 3306

***要關掉某一站台全部服務請執行***
```bash
$ docker-compose -p <yourprefix> down 
```

***以上資訊都會紀錄在*** **info.txt**


---
### 啟動網站

#### ***從原來專案安裝***
如果有原來m2專案的話, 直接把整個專案丟進src中即可, 並確認```config/<local|dev|staging|production>```四個資料夾中, magento裡面的config.php還有env.php

啟動服務後再把原來專案的db匯入
最後重新啟動服務



#### ***第一次安裝***

 ***1.*** 下載magento2 
* **在src外**執行
```bash
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.3.3 src
```
 * 或是把已有的composer.json丟至src內執行
 ```bash
 composer install
 ```

***2.*** 安裝
```bash
chmod 755 bin/magento ;
BASE_URL="${DOMAINNAME}";
ADMIN_EMAIL="glennn@astralwebinc.com";
bin/magento setup:install \
  --db-host=mysql \
  --db-name=magento \
  --db-user=magento \
  --db-password=magento \
  --base-url=http://$BASE_URL/ \
  --backend-frontname=admin \
  --admin-firstname=magento \
  --admin-lastname=admin \
  --admin-email=$ADMIN_EMAIL \
  --admin-user=admin \
  --admin-password=admin123 \
  --language=en_US \
  --currency=TWD \
  --timezone=Asia/Taipei \
  --use-rewrites=1;
```

***3.*** 重新啟動
檢查info.txt中的執行或關閉命令

**e.g**
```bash
$ docker-compose -p <yourprefix> down 
$ docker-compose -p <yourprefix> up -d 
```


___

### 同時多站
要再起一台直接整個資料夾cp到另一個資料夾, 通常此時cp完都已經有了magento2跟db資料

正常來說只要 ./docker-run.sh 加上參數<-c | -s>設定subdomain就好  

123456
