# Instalasi Moodle dengan Podman Compose

## 1. Buat Folder Moodle

```bash
mkdir moodle moodle_data
```

Folder:

* `moodle` → berisi source code Moodle
* `moodle_data` → sebagai `moodledata` (writable directory)

## 2. Clone Repository Moodle

```bash
git clone --branch MOODLE_501_STABLE --depth 1 https://github.com/moodle/moodle.git moodle
```

Branch **MOODLE_501_STABLE** adalah rilis stabil untuk Moodle 5.0.1.

## 3. Siapkan File Environment

Salin `.env-example` ke `.env` lalu edit sesuai kebutuhan:

```plaintext
APP_NAME=univ

DB_DATABASE=demo-app
DB_USERNAME=demo-app
DB_PASSWORD=securepass

MYSQL_ROOT_PASSWORD=securepass
```

## 4. Jalankan Podman Compose

```bash
podman compose up -d
```

Pastikan semua container berjalan:

```bash
podman compose ps
```

## 5. Install Moodle dari Dalam Container

Masuk ke container `moodle`:

```bash
podman compose exec -it moodle bash
```

Jalankan installer non-interaktif:

```bash
php /var/www/html/admin/cli/install.php \
  --adminuser=admin \
  --adminemail=admin@example.com \
  --adminpass=securepass \
  --agree-license \
  --dataroot=/var/www/moodledata \
  --dbhost=db \
  --dbname=demo-app \
  --dbuser=demo-app \
  --dbpass=securepass \
  --dbport=3306 \
  --dbtype=mariadb \
  --fullname="Universitas Teknologi Moodle" \
  --lang=id \
  --non-interactive \
  --shortname="UTMoodle" \
  --wwwroot=https://example.com
```

## 6. Tambahkan Konfigurasi pada `config.php`

Edit file `config.php` dan tambahkan:

```php
$CFG->sslproxy = true;
$CFG->routerconfigured = true;
```

Penjelasan:

* `$CFG->sslproxy = true;` → digunakan bila Moodle ada di balik reverse proxy/HTTPS termination.
* `$CFG->routerconfigured = true;` → menghindari Moodle menimpa `.htaccess` atau file routing.

## 7. Jalankan Composer (Sebagai User Application)

Masuk ke container moodle
```bash
podman compose exec -it --user application moodle bash
```

Lalu jalankan composer.
```bash
cd /var/www/html
composer install --no-dev --classmap-authoritative
```

## 8. Mengaktifkan Automatic Cron

Moodle **wajib** menjalankan cron setiap 1 menit agar fitur seperti email, backup otomatis, task queue, dan cleanup berjalan dengan benar.

### Opsi A — Jalankan Cron dari Host (Disarankan)

Buat cron job langsung pada host:

```bash
*/1 * * * * podman exec -it moodle php /var/www/html/admin/cli/cron.php > /dev/null 2>&1
```

### Opsi B — Cron di Dalam Container

Bila container moodle berbasis OS lengkap (misalnya Debian/Ubuntu image):

Masuk:

```bash
podman compose exec -it moodle bash
```

Edit crontab:

```bash
crontab -e
```

Tambah:

```cron
*/1 * * * * php /var/www/html/admin/cli/cron.php > /dev/null 2>&1
```

### Opsi C — Gunakan Supervisor

Buat file `/usr/local/bin/moodle-cron.sh`:
```bash
#!/bin/sh
while true; do
  php /var/www/html/admin/cli/cron.php
  sleep 60
done
```

Beri permission.
```bash
chmod +x /usr/local/bin/moodle-cron.sh
```

Buat file konfigurasi supervisor `moodle-cron.conf`:
```ini
[group:moodle]
programs=moodle-cron
priority=25

[program:moodle-cron]
command = /usr/local/bin/moodle-cron.sh
process_name=%(program_name)s
startsecs = 0
autostart = true
autorestart = true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
```

Reload supervisor.
```bash
supervisorctl reread
supervisorctl update
supervisorctl start moodle-cron
```