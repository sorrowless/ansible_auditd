# Профили compliance

Роль закрывает **локальную** регистрацию событий через `auditd`. Она не заменяет аттестацию, отчёт QSA или заключение по ГОСТ. Централизованный сбор, хранение в календарных днях, разбор инцидентов и процессы организации остаются вне роли.

По умолчанию (`auditd_profiles: []`) ставится только baseline под AUD-01 из host_audit.

## pci_dss — PCI DSS 4.0, требование 10

Файл: `/etc/audit/rules.d/zz-50-pci-dss.rules`.

| Требование | Что делает роль |
| --- | --- |
| 10.2.1.1 | Watch на пути из `auditd_pci_data_paths`. Пустой список — ничего не добавляется |
| 10.2.1.2 | Exec-watch на найденные setuid/setgid в `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/usr/local/bin`, `/usr/local/sbin` |
| 10.2.1.3 / 10.2.1.6 | Watch на `/var/log/audit`, `/etc/audit`, unit auditd, `auditctl` / `auditd` / `augenrules` |
| 10.2.1.4 | Syscall-правила `open`/`openat`/`creat`/… с `exit=-EACCES` и `exit=-EPERM`, `auid>=1000` |
| 10.2.1.5 | Watch на PAM, faillock/faillog, lastlog, wtmp, btmp. Identity-файлы уже в baseline |
| 10.2.1.7 | `unlink`/`rename`, `chmod`/`chown`/`setxattr`, `mount` |
| 10.3.1 / 10.3.2 | `log_format=ENRICHED`, `max_log_file_action=keep_logs`, пороги места, `SYSLOG`/`SINGLE`, права `0750`/`0640` на каталог и журнал |

Не покрывается ролью:

- 10.3.3 / 10.5.1 — центральный архив и доставка логов;
- `disk_full_action=HALT` — не включается само; при необходимости задайте через `auditd_config`.

## gost_57580 — ГОСТ Р 57580.1-2017, уровень «стандартный»

Файл: `/etc/audit/rules.d/zz-60-gost-57580.rules`.

Практическая часть процесса регистрации событий защиты информации:

| Область | Реализация |
| --- | --- |
| Аутентификация и сессии | faillog/faillock, lastlog, wtmp, btmp, utmp |
| Отказы в доступе | `open`/`openat`/`creat` с `EACCES`/`EPERM` |
| Привилегированные действия | `execve` с `euid=0` и `auid>=1000` |
| Учётные записи и права | watches на passwd/shadow/group/gshadow, `chmod`/`chown` |
| Настройки защиты | pam, ssh, sudoers, sysctl, `/etc/audit` |
| Жизненный цикл регистрации | журнал audit, unit, `auditctl`/`auditd`/`augenrules` |
| Смена времени | `adjtimex`/`settimeofday`/`clock_settime`, `/etc/localtime` |
| Содержание записи | `log_format=ENRICHED` (время, субъект, объект, результат в записи) |
| Защита журнала | `keep_logs`, права каталога/файла, сигнал в syslog при нехватке места |

Срок хранения в календарных днях стандарт задаёт через политику организации. Роль не имитирует его числом `num_logs`. Централизованный сбор и разбор инцидентов — вне роли.

## Пересечение профилей

Оба профиля можно включить одновременно. Правила пишутся в разные файлы; одинаковые watch с разными ключами для auditd допустимы. Ключи `auditd.conf` из `auditd_profile_config` выставляются один раз; `auditd_config` их перекрывает.

## Immutable

`auditd_immutable: true` добавляет `-e 2` в `zz-99-immutable.rules`. После успешной загрузки правила нельзя менять до перезагрузки. Профили сами этот флаг не включают.
