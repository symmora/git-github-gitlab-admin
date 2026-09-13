---
name: git-github-gitlab
description: "Комплексный скилл для администрирования и использования git, GitHub и GitLab. Покрывает операции от базовой настройки git до продвинутого rebase, работы с платформами через gh и glab CLI, CI/CD, безопасности и AI-инструментов."
description_en: "Comprehensive Git, GitHub & GitLab administration skill with gh/glab CLI, router and tests."
description_zh: "git/GitHub/GitLab, admin & duties"
license: MIT
agent_created: true
allowed-tools: "Read, Write, Bash, Glob, Grep, Edit"
metadata:
  version: "1.0.0"
  author: "dit"
  tags: "git, gh, glab"
---

# git / GitHub / GitLab — Администрирование и использование

> **Язык:** Русский (с английскими техническими терминами где необходимо).
> **Версия:** 1.0.0
> **Требования:** `git` >= 2.40, `gh` (GitHub CLI), `glab` (GitLab CLI)

---

## Когда использовать этот скилл

Используйте этот скилл для **любой** задачи, связанной с:

- **Git** — локальные операции: init, clone, add, commit, push, pull, branch, merge, rebase, stash, cherry-pick, revert, tag, blame, bisect, reflog, worktree, hooks, submodules, патчи, archive, gc, fsck, sparse-checkout, notes, bundle, replace
- **GitHub** — Issues, PR, Actions, Pages, Releases, Discussions, Projects, CODEOWNERS, Dependabot, Secret scanning, CodeQL, Branch protection, Webhooks, Packages, Apps, Gists, Templates, Insights
- **GitLab** — Merge Requests, Issues, CI/CD pipelines, Environments, Releases, Container Registry, Pages, Wiki, Boards
- **CLI инструменты** — `gh` (GitHub CLI) и `glab` (GitLab CLI)
- **AI-инструменты** — GitHub Copilot, AI-ассистенты на платформах

## Структура скилла

```
git-github-gitlab-admin/
├── SKILL.md                          ← Этот файл — оглавление и быстрые ссылки
├── references/
│   ├── 01-git-basics.md              ← Настройка, init, clone, add, commit, push, pull
│   ├── 02-git-branches-merge.md      ← Ветки, merge-стратегии, rebase
│   ├── 03-git-advanced.md            ← Stash, cherry-pick, revert, rebase -i, tag
│   ├── 04-git-investigation.md       ← log, diff, blame, bisect, reflog
│   ├── 05-git-config-hooks.md        ← config (3 уровня), hooks, submodules
│   ├── 06-git-patches-archive.md     ← format-patch, apply, am, archive, bundle
│   ├── 07-git-maintenance.md         ← gc, fsck, repack, sparse-checkout, notes, replace
│   ├── 08-github-platform.md         ← GitHub: Issues, PR, Actions, Pages, Releases...
│   ├── 09-gitlab-platform.md         ← GitLab: MR, CI/CD, Registry, Pages, Wiki...
│   ├── 10-gh-cli.md                  ← GitHub CLI (gh) — полный справочник
│   ├── 11-glab-cli.md                ← GitLab CLI (glab) — полный справочник
│   ├── 12-security-cicd.md           ← Безопасность и CI/CD на платформах
│   └── 13-ai-assistants.md           ← GitHub Copilot и AI-ассистенты
├── assets/
│   └── how-to-authorize.md          ← Authentication flow, credentials и tokens
├── scripts/
│   └── git-router.sh                 ← Маршрутизатор — диспетчер команд
└── tests/
    └── test-router.sh                ← Тесты Маршрутизатора
```

## Быстрый старт

### 1. Первичная настройка git

```bash
# Имя и email (глобально)
git config --global user.name "Имя Фамилия"
git config --global user.email "user@example.com"

# Проверка настроек
git config --list --show-origin

# Дефолтная ветка — main
git config --global init.defaultBranch main
```

### 2. Авторизация на платформах

Полный технический разбор authentication flow, включая места создания, передачи, проверки, обновления и хранения credentials и tokens, находится в [`assets/how-to-authorize.md`](assets/how-to-authorize.md). Там же приведены Mermaid-схема, риски текущих defaults и явно отмеченные неопределённости.

```bash
# GitHub — через gh CLI (рекомендуется, используется Personal Access Token)
gh auth login

# GitLab — через glab CLI
glab auth login

# Альтернатива — credential helper для кэширования пароля/токена
git config --global credential.helper store    # хранить в ~/.git-credentials
git config --global credential.helper cache   # кэш в памяти на 15 мин
```

### 3. Базовый рабочий цикл

```bash
# Создать репо
git init my-project && cd my-project
git add .
git commit -m "feat: начальная структура проекта"

# Подключить remote и запушить
git remote add origin https://github.com/user/my-project.git
git branch -M main
git push -u origin main
```

### 4. Использование Маршрутизатора

```bash
# Запуск с указанием задачи
./scripts/git-router.sh init my-project
./scripts/git-router.sh commit "feat: добавлен модуль авторизации"
./scripts/git-router.sh pr-create --title "Feature: auth" --base main
./scripts/git-router.sh stash
./scripts/git-router.sh undo       # отмена последнего коммита (soft)
./scripts/git-router.sh help      # список всех команд

# Полное руководство — см. scripts/git-router.sh --help
```

## Карта разделов по темам

| Тема | Раздел | Ключевые команды |
|------|--------|-----------------|
| Настройка git | `01-git-basics.md` | `git config`, `git init`, `git clone` |
| Ветки и слияние | `02-git-branches-merge.md` | `git branch`, `git merge`, `git rebase` |
| Продвинутые операции | `03-git-advanced.md` | `git stash`, `git cherry-pick`, `git revert`, `git rebase -i`, `git tag` |
| Расследование | `04-git-investigation.md` | `git log`, `git diff`, `git blame`, `git bisect`, `git reflog` |
| Конфигурация и хуки | `05-git-config-hooks.md` | `git config`, hooks, `git submodule` |
| Патчи и архивы | `06-git-patches-archive.md` | `git format-patch`, `git apply`, `git archive`, `git bundle` |
| Обслуживание | `07-git-maintenance.md` | `git gc`, `git fsck`, `git sparse-checkout`, `git notes` |
| GitHub | `08-github-platform.md` | Issues, PR, Actions, Pages, Releases, Discussions |
| GitLab | `09-gitlab-platform.md` | MR, CI/CD, Registry, Pages, Wiki, Boards |
| gh CLI | `10-gh-cli.md` | `gh pr`, `gh issue`, `gh repo`, `gh workflow` |
| glab CLI | `11-glab-cli.md` | `glab mr`, `glab issue`, `glab repo`, `glab ci` |
| Безопасность и CI/CD | `12-security-cicd.md` | Dependabot, Secret scanning, CodeQL, Branch protection |
| AI-ассистенты | `13-ai-assistants.md` | GitHub Copilot, Copilot CLI, AI-агенты |

## Подключение к репозиториям — методы

### Метод 1: HTTPS + Personal Access Token (PAT)

```bash
# Клонирование с использованием токена в URL (не рекомендуется для постоянного использования)
git clone https://oauth2:<TOKEN>@github.com/user/repo.git

# Рекомендуемый способ — через credential helper
git config --global credential.helper store
git clone https://github.com/user/repo.git
# При первом push ввести токен вместо пароля
```

### Метод 2: SSH-ключ

```bash
# Генерация SSH-ключа
ssh-keygen -t ed25519 -C "user@example.com"

# Добавить публичный ключ на GitHub: Settings → SSH and GPG keys
# Клонирование по SSH
git clone git@github.com:user/repo.git
```

### Метод 3: Deploy Token / CI Token (для автоматизации)

```bash
# GitLab Deploy Token
git clone https://gitlab+deploy-token-<ID>:<TOKEN>@gitlab.com/user/repo.git

# GitHub Fine-grained PAT (ограниченный scope)
git clone https://x-access-token:<TOKEN>@github.com/user/repo.git
```

## Восстановление состояния — шпаргалка

| Ситуация | Команда |
|----------|---------|
| Отменить последний коммит (сохранить изменения) | `git reset --soft HEAD~1` |
| Отменить последний коммит (удалить изменения) | `git reset --hard HEAD~1` |
| Безопасно отменить коммит в общей ветке | `git revert <commit>` |
| Вернуться к состоянию до merge | `git merge --abort` или `git reset --hard ORIG_HEAD` |
| Вернуться к состоянию до rebase | `git rebase --abort` или `git reset --hard ORIG_HEAD` |
| Найти потерянный коммит | `git reflog` |
| Отменить `git add` | `git restore --staged <file>` или `git reset HEAD <file>` |
| Сбросить локальные изменения файла | `git restore <file>` или `git checkout -- <file>` |
| Получить версию файла на дату | `git log --before="2025-01-15" -1 --format=%H -- <file>` → `git show <hash>:<file>` |

## Маршрутизатор (Router)

Маршрутизатор — bash-скрипт-диспетчер, который принимает задачу на естественном языке и выполняет соответствующую последовательность git/gh/glab команд с проверками безопасности.

**Файл:** `scripts/git-router.sh`
**Тесты:** `tests/test-router.sh`

```bash
# Запуск
bash scripts/git-router.sh <команда> [аргументы]

# Список команд
bash scripts/git-router.sh help

# Примеры
bash scripts/git-router.sh init my-project
bash scripts/git-router.sh clone https://github.com/user/repo.git
bash scripts/git-router.sh commit "fix: исправлен баг авторизации"
bash scripts/git-router.sh pr-create --title "Fix auth" --base main
bash scripts/git-router.sh undo-last
bash scripts/git-router.sh stash save "WIP: эксперимент"
```

Подробное руководство по Маршрутизатору — в начале файла `scripts/git-router.sh`.

## Принципы работы

1. **Безопасность прежде всего** — деструктивные операции (`reset --hard`, `push --force`, `clean -fd`) требуют подтверждения
2. **Понятные сообщения коммитов** — следуем Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`)
3. **Защита общей истории** — на общих ветках используем `revert` вместо `reset`; `force push` только с `--force-with-lease`
4. **Проверка перед push** — `git status`, `git diff --cached`, `git log` перед отправкой
5. **Маленькие коммиты** — атомарные изменения легче ревьюить и откатывать
