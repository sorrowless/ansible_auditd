# auditd

Роль **устанавливает и настраивает** `auditd` на Ubuntu LTS. По умолчанию закрывает контроль AUD-01 из [sorrowless.host_audit](https://github.com/sorrowless/sorrowless.host_audit): слежение за identity-файлами, `sudoers` и сменой времени, unit enabled и запущен.

Опциональные профили `pci_dss` и `gost_57580` добавляют правила и ключи `auditd.conf` под локальную часть PCI DSS 4.0 (требование 10) и ГОСТ Р 57580.1-2017 (уровень «стандартный»). Это техническая настройка auditd, а не аттестация и не отчёт. Подробности: [docs/profiles.md](docs/profiles.md).

Поддерживаемые ОС: Ubuntu 22.04, 24.04, 26.04.

## Быстрый старт

Каталог называется `sorrowless.auditd`, Ansible не принимает точку в имени роли. Перед запуском сделайте symlink:

```bash
make link
ANSIBLE_ROLES_PATH=.cache/roles ./run-auditd.yml -i inventory.yml
ANSIBLE_ROLES_PATH=.cache/roles ./run-auditd.yml -i inventory.yml -l web-01,web-02
```

Плейбук идёт с `become: true`.

## Переменные

| Переменная | По умолчанию | Смысл |
| --- | --- | --- |
| `auditd_profiles` | `[]` | `pci_dss`, `gost_57580` в любой комбинации |
| `auditd_extra_rules` | `[]` | Дополнительные строки в `zz-90-local.rules` |
| `auditd_config` | `{}` | Ключи `auditd.conf`, перекрывают профили |
| `auditd_immutable` | `false` | Добавить `-e 2` последней строкой |
| `auditd_pci_data_paths` | `[]` | Пути карточных данных для PCI 10.2.1.1 |

Пример с профилями:

```yaml
auditd_profiles:
  - pci_dss
  - gost_57580
auditd_pci_data_paths:
  - /var/lib/payment/chd
auditd_extra_rules:
  - -w /opt/app/config -p wa -k app-config
auditd_config:
  num_logs: "20"
```

Доставка логов на центральный приёмник (LOG-01, PCI 10.3.3 / 10.5.1) этой ролью не настраивается.

## Что пишет роль

| Файл | Когда |
| --- | --- |
| `/etc/audit/rules.d/zz-10-baseline.rules` | всегда |
| `/etc/audit/rules.d/zz-50-pci-dss.rules` | профиль `pci_dss` |
| `/etc/audit/rules.d/zz-60-gost-57580.rules` | профиль `gost_57580` |
| `/etc/audit/rules.d/zz-90-local.rules` | непустой `auditd_extra_rules` |
| `/etc/audit/rules.d/zz-99-immutable.rules` | `auditd_immutable: true` |

Выключенный профиль удаляет свой файл. Штатный `-e 2` в `/etc/audit/rules.d/audit.rules`, если он активен, комментируется, иначе правила роли не загрузятся.

Если ядро не поддерживает audit (типично для Docker Desktop на macOS), роль оставляет unit enabled и файлы на месте, старт демона и `augenrules --load` не валят плейбук. На обычном сервере любая другая ошибка старта — fail.

## Тесты

```bash
make lint
make test              # ubuntu2204, ubuntu2404, ubuntu2604, profiles
make test-ubuntu2404
make test-profiles
```

Образы собираются локально из `public.ecr.aws/docker/library/ubuntu`.

## Автор

Stan Bogatkin <s@sbog.org>
