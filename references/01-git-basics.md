# 01 — Основы Git: настройка, init, clone, add, commit, push, pull

> Полный справочник по базовым операциям Git.

---

## Содержание
1. [Настройка git (config)](#настройка-git-config)
2. [Создание репозитория (init)](#создание-репозитория-init)
3. [Клонирование (clone)](#клонирование-clone)
4. [Добавление в индекс (add)](#добавление-в-индекс-add)
5. [Удаление из индекса и из репо](#удаление-из-индекса-и-из-репо)
6. [Коммиты (commit)](#коммиты-commit)
7. [Push и pull](#push-и-pull)
8. [Удалённые репозитории (remote)](#удалённые-репозитории-remote)
9. [Получение версии файла на дату](#получение-версии-файла-на-дату)

---

## Настройка git (config)

Git config имеет три уровня приоритета (от низшего к высшему):

| Уровень | Флаг | Файл | Назначение |
|---------|------|------|------------|
| System | `--system` | `/etc/gitconfig` | Для всех пользователей системы |
| Global | `--global` | `~/.gitconfig` | Для текущего пользователя |
| Local | `--local` | `.git/config` | Для текущего репо (по умолчанию) |

### Базовая настройка

```bash
# Имя и email (обязательно)
git config --global user.name "Иван Иванов"
git config --global user.email "ivan@example.com"

# Дефолтная ветка
git config --global init.defaultBranch main

# Окончание строк (Windows)
git config --global core.autocrlf true
# Окончание строк (Linux/macOS)
git config --global core.autocrlf input

# Редактор по умолчанию
git config --global core.editor "code --wait"

# Включить цветной вывод
git config --global color.ui auto

# Pull strategy — rebase вместо merge
git config --global pull.rebase true

# Автокоррекция опечаток
git config --global help.autocorrect 1

# Алиасы
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'restore --staged'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg "log --graph --oneline --decorate --all"
```

### Просмотр настроек

```bash
# Все настройки с указанием источника
git config --list --show-origin

# Конкретная настройка
git config user.name

# Удалить настройку
git config --global --unset user.name
```

### Автозамена URL

```bash
# Замена HTTPS на SSH для GitHub
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Замена для корпоративного GitHub Enterprise
git config --global url."git@git.company.com:".insteadOf "https://git.company.com/"
```

---

## Создание репозитория (init)

```bash
# Создать новый репо в текущей директории
git init

# Создать новый репо в указанной директории
git init my-project

# Создать репо с конкретной веткой по умолчанию
git init --initial-branch=main my-project

# "голый" репо (bare) — для сервера, без рабочей директории
git init --bare my-project.git
```

### Создание удалённого репо через CLI

```bash
# GitHub через gh
gh repo create my-project --public --source=. --push
gh repo create my-project --private --source=. --push
gh repo create org/my-project --internal

# GitLab через glab
glab repo create my-project --private --source=. --push
```

---

## Клонирование (clone)

```bash
# HTTPS
git clone https://github.com/user/repo.git

# SSH
git clone git@github.com:user/repo.git

# Клонирование в указанную директорию
git clone https://github.com/user/repo.git my-local-dir

# Клонирование определённой ветки
git clone --branch develop https://github.com/user/repo.git

# Поверхностное клонирование (только последний коммит)
git clone --depth 1 https://github.com/user/repo.git

# Клонирование без истории (--depth 1 + --single-branch)
git clone --depth 1 --single-branch https://github.com/user/repo.git

# Клонирование с подмодулями
git clone --recurse-submodules https://github.com/user/repo.git

# Клонирование только определённых директорий (sparse)
git clone --filter=blob:none --sparse https://github.com/user/repo.git
cd repo
git sparse-checkout set src/lib docs

# Создание зеркала (полная копия для бэкапа)
git clone --mirror https://github.com/user/repo.git
```

---

## Добавление в индекс (add)

```bash
# Добавить конкретный файл
git add file.txt

# Добавить несколько файлов
git add file1.txt file2.txt

# Добавить всё (все изменения, включая новые файлы)
git add .
git add -A    # включает удаления

# Добавить по паттерну
git add *.py
git add src/

# Интерактивное добавление (патчи по частям)
git add -p
# y — да, n — нет, s — разбить на меньшие части, q — выход, e — редактировать вручную

# Добавить только отслеживаемые файлы (без новых)
git add -u

# Добавить с проверкой (показывает что будет добавлено)
git add --dry-run .
```

---

## Удаление из индекса и из репо

### Убрать из индекса (unstage)

```bash
# Убрать конкретный файл из стейджа (изменения остаются)
git restore --staged file.txt
# Старый синтаксис (всё ещё работает)
git reset HEAD file.txt

# Убрать всё из стейджа
git restore --staged .
git reset HEAD
```

### Удалить файл из репо и с диска

```bash
# Удалить файл и добавить удаление в индекс
git rm file.txt

# Удалить только из индекса, оставить на диске
git rm --cached file.txt

# Удалить директорию рекурсивно
git rm -r old-dir/

# Игнорировать изменения в отслеживаемом файле
git update-index --assume-unchanged config/local.env
# Вернуть отслеживание
git update-index --no-assume-unchanged config/local.env
```

### Удаление с удалённого репо

```bash
# Удалить файл из репо и запушить
git rm file.txt
git commit -m "chore: удаляем устаревший файл"
git push

# Удалить файл из всей истории (ВНИМАНИЕ: переписывает историю!)
# Использовать только для секретов/паролей
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secrets.env' \
  --prune-empty --tag-name-filter cat -- --all
# Или через BFG Repo-Cleaner (быстрее)
bfg --delete-files secrets.env
git push --force
```

---

## Коммиты (commit)

```bash
# Коммит всех staged изменений
git commit -m "feat: добавлена авторизация"

# Многострочное сообщение
git commit -m "feat: добавлена авторизация" -m "Использует JWT токены. Добавлены middleware и тесты."

# Коммит всех изменений (включая unstaged, кроме untracked)
git commit -am "fix: исправлен баг в логике валидации"

# Изменить последний коммит (добавить изменения к нему)
git add --all
git commit --amend --no-edit    # сохранить сообщение
git commit --amend -m "feat: добавлена авторизация + тесты"  # новое сообщение

# Пустой коммит (для триггеров CI/CD)
git commit --allow-empty -m "ci: триггер пайплайна"

# Подписанный коммит (GPG)
git commit -S -m "feat: критическое изменение"
```

### Conventional Commits — стандарт сообщений

```
<type>(<scope>): <description>

<body>

<footer(s)>
```

| Тип | Назначение | Пример |
|-----|-----------|--------|
| `feat` | Новая функциональность | `feat(auth): добавлена регистрация через OAuth` |
| `fix` | Исправление бага | `fix(api): исправлен null-pointer в обработчике` |
| `docs` | Документация | `docs: обновлён README` |
| `style` | Форматирование, не затрагивающий логику | `style: применён prettier` |
| `refactor` | Рефакторинг без изменения поведения | `refactor: разделён UserService на модули` |
| `test` | Тесты | `test: добавлены unit-тесты для AuthService` |
| `chore` | Обслуживание | `chore: обновлены зависимости` |
| `ci` | CI/CD | `ci: добавлен линтер в GitHub Actions` |
| `build` | Сборка | `build: обновлён webpack до v5` |
| `perf` | Производительность | `perf(db): добавлен индекс на users.email` |
| `revert` | Откат | `revert: feat(auth): откат OAuth регистрации` |

**Footer для breaking changes:**
```
feat(api): v2 endpoint

BREAKING CHANGE: /api/v1/* удалён, использовать /api/v2/*
```

### Генерация сообщения коммита

```bash
# Пример авто-генерации через git log + diff
git log --oneline -5    # посмотреть стиль предыдущих коммитов
git diff --cached       # посмотреть что коммитим
# Сформировать сообщение по Conventional Commits
```

---

## Push и pull

```bash
# Push текущей ветки (с установкой upstream)
git push -u origin main
git push --set-upstream origin feature-branch

# Обычный push
git push
git push origin main

# Push всех веток
git push origin --all

# Push тегов
git push origin --tags
git push origin v1.0.0

# Force push (ОПАСНО — перезаписывает удалённую историю)
# Безопасный вариант — проверяет, не запушел ли кто-то ещё
git push --force-with-lease
# Опасный — без проверки
git push --force    # НЕ использовать на общих ветках!

# Push с удалением удалённой ветки
git push origin --delete feature-branch

# Pull (по умолчанию merge)
git pull

# Pull с rebase (линейная история)
git pull --rebase

# Pull конкретной ветки
git pull origin develop

# Fetch (без merge)
git fetch
git fetch origin
git fetch --all --prune    # обновить все remote и удалить несуществующие ветки
```

---

## Удалённые репозитории (remote)

```bash
# Просмотр remote
git remote -v

# Добавить remote
git remote add origin https://github.com/user/repo.git
git remote add upstream https://github.com/original/repo.git

# Изменить URL remote
git remote set-url origin git@github.com:user/repo.git

# Переименовать remote
git remote rename origin github

# Удалить remote
git remote remove origin

# Просмотр информации о remote
git remote show origin
```

### Работа с несколькими remote

```bash
# Fork workflow: origin — ваш fork, upstream — оригинал
git remote add upstream https://github.com/original/repo.git
git fetch upstream
git checkout main
git merge upstream/main    # синхронизировать fork с оригиналом
git push origin main       # запушить обновления в свой fork
```

---

## Получение версии файла на дату

### Метод 1: через git log + git show

```bash
# Найти последний коммит, изменявший файл до указанной даты
HASH=$(git log --before="2025-06-15" -1 --format=%H -- path/to/file.txt)
# Показать содержимое файла на этот коммит
git show "$HASH:path/to/file.txt"
```

### Метод 2: через git checkout (AS-OF, Git 2.5+)

```bash
# Восстановить файл из состояния на дату (без переключения ветки)
git checkout HEAD@{2025-06-15} -- path/to/file.txt
# Или через относительное время
git checkout "HEAD@{1 month ago}" -- path/to/file.txt
```

### Метод 3: через reflog или тег

```bash
# По тегу
git show v1.2.0:path/to/file.txt

# По конкретному хешу
git show abc1234:path/to/file.txt

# Сравнить версии файла между датами
git diff "$(git log --before='2025-01-01' -1 --format=%H)" \
         "$(git log --before='2025-06-01' -1 --format=%H)" \
         -- path/to/file.txt
```

### Метод 4: rev-list для точного поиска

```bash
# Найти коммит, который изменил файл между двумя датами
git rev-list --since="2025-03-01" --until="2025-04-01" HEAD -- path/to/file.txt

# Кто изменил строку 42 в указанный период
git log -L 42,42:path/to/file.txt --since="2025-03-01" --until="2025-04-01"
```
