# 11 — GitLab CLI (glab) — полный справочник

> Справочник по всем основным командам `glab` — официального GitLab CLI.

---

## Содержание
1. [Установка и авторизация](#установка-и-авторизация)
2. [repo — репозитории](#repo)
3. [issue — задачи](#issue)
4. [mr — merge requests](#mr)
5. [ci — CI/CD](#ci)
6. [release — релизы](#release)
7. [snippet — сниппеты](#snippet)
8. [label — метки](#label)
9. [variable — переменные CI/CD](#variable)
10. [api — прямой доступ к API](#api)
11. [runner — runners](#runner)
12. [Конфигурация glab](#конфигурация-glab)

---

## Установка и авторизация

```bash
# Проверка
glab --version

# Авторизация (интерактивно)
glab auth login
# Выбор: GitLab.com / Self-hosted GitLab
# Указание: hostname, token (Personal/Project/Group token)

# Авторизация с токеном (для self-hosted)
glab auth login --hostname gitlab.company.com --token <token>

# Проверка статуса
glab auth status

# Управление несколькими инстансами
glab auth status --hostname gitlab.company.com

# Выход
glab auth logout
```

---

## repo

```bash
# Создать
glab repo create my-project --private --source=. --push
glab repo create my-project --public
glab repo create org/my-project --internal

# Клонировать
glab repo clone user/repo
glab repo clone user/repo my-local-dir

# Форк
glab repo fork user/repo --clone
glab repo fork

# Просмотр
glab repo view
glab repo view user/repo --web

# Архивировать
glab repo archive user/repo

# Список
glab repo list
glab repo list --mine
glab repo list --group my-group

# Удалить
glab repo delete user/repo
```

---

## issue

```bash
# Создать
glab issue create --title "Баг" --description "Описание"
glab issue create --title "Фича" --label "enhancement" --assignee "@me"
glab issue create --title "Задача" --milestone "v2.0"

# Список
glab issue list
glab issue list --label "bug"
glab issue list --assignee "@me"
glab issue list --closed
glab issue list --search "auth"

# Просмотр
glab issue view 42
glab issue view 42 --web
glab issue view 42 --comments

# Комментировать
glab issue comment 42 --message "Текст"
glab issue comment 42 --file comment.md

# Закрыть / открыть
glab issue close 42
glab issue reopen 42

# Редактировать
glab issue update 42 --title "Новое название"
glab issue update 42 --label "wontfix"
glab issue update 42 --assignee "user1"

# Назначить несколько
glab issue update 42 --assignee "user1,user2"
```

---

## mr

```bash
# Создать MR
glab mr create --title "feat: новая фича" --description "..." --target-branch main --source-branch feature
glab mr create --fill
glab mr create --draft --title "WIP"
glab mr create --reviewer "user1,user2" --assignee "@me"
glab mr create --label "review-required" --milestone "v2.0"

# Список
glab mr list
glab mr list --state opened
glab mr list --author "@me"
glab mr list --label "review-required"

# Просмотр
glab mr view 42
glab mr view 42 --web
glab mr view 42 --comments
glab mr diff 42

# Checkout MR
glab mr checkout 42

# Слияние
glab mr merge 42
glab mr merge 42 --squash
glab mr merge 42 --rebase
glab mr merge 42 --remove-source-branch
glab mr merge 42 --auto-merge     # auto-merge when pipeline succeeds

# Закрыть
glab mr close 42
glab mr reopen 42

# Редактировать
glab mr update 42 --title "Новое название"
glab mr update 42 --add-reviewer "user1"
glab mr update 42 --target-branch develop

# Review / approval
glab mr review 42                 # открыть интерактивный review
glab mr review 42 --approve
glab mr review 42 --request-changes --comment "Нужны тесты"
glab mr review 42 --comment "Комментарий"

# Notes (комментарии)
glab mr note 42 --message "Комментарий"
glab mr note 42 --file comment.md

# Approvals
glab mr approvers 42               # список аппрувов
glab mr approvers 42 --add "user1,user2"
```

---

## ci

```bash
# Список pipelines
glab ci list
glab ci list --branch=main
glab ci list --status=success
glab ci list --per-page=20

# Просмотр
glab ci view
glab ci view --branch=main

# Логи конкретного pipeline
glab ci trace
glab ci trace --branch=main --job=build
glab ci trace --branch=feature --job=test

# Повторный запуск
glab ci retry
glab ci retry --branch=main
glab ci retry --failed           # только упавшие

# Запуск нового pipeline
glab ci run --branch=feature
glab ci run --branch=main --variables "DEPLOY=true,ENV=staging"

# Отмена pipeline
glab ci retry --cancel
glab ci delete <pipeline-id>
```

---

## release

```bash
# Создать
glab release create v1.0.0 --name "Релиз 1.0.0" --notes "Описание"
glab release create v1.0.0 --notes-file CHANGELOG.md
glab release create v1.0.0 --assets ./dist/app.tar.gz
glab release create v1.0.0 --milestone "v2.0"

# Список
glab release list

# Просмотр
glab release view v1.0.0
glab release view v1.0.0 --web

# Скачать
glab release download v1.0.0
glab release download v1.0.0 --assets "*.tar.gz"

# Удалить
glab release delete v1.0.0

# Загрузить артефакты
glab release upload v1.0.0 ./new-artifact.zip
glab release upload v1.0.0 ./new-artifact.zip --clobber
```

---

## snippet

```bash
# Создать
glab snippet create file.py --title "Сниппет" --visibility public
glab snippet create file.py --title "Сниппет" --visibility private
echo "print('hello')" | glab snippet create --title "Hello" --filename hello.py

# Список
glab snippet list

# Просмотр
glab snippet view <id>
glab snippet view <id> --raw

# Удалить
glab snippet delete <id>
```

---

## label

```bash
glab label create "priority-critical" --color "#B60205" --description "Критический"
glab label list
glab label list --search "priority"
```

---

## variable

Управление переменными CI/CD (для конвейеров).

```bash
# Список
glab variable list
glab variable list --env "production"

# Создать
glab variable set DATABASE_URL --value "postgresql://..."
glab variable set DEPLOY_KEY --value "xxx" --env "production" --masked

# Удалить
glab variable delete DATABASE_URL
glab variable delete DEPLOY_KEY --env "production"
```

---

## api

```bash
# REST API v4
glab api user
glab api projects
glab api projects/:id
glab api groups

# Методы
glab api --method POST projects --name "new-project" --path "new-project"
glab api --method PUT projects/:id --description "New description"
glab api --method DELETE projects/:id

# С пагинацией
glab api projects --paginate

# jq-фильтрация
glab api projects --jq '.[] | .path_with_namespace'
glab api user --jq '.username'

# Поиск
glab api --method GET search -f scope=projects -f search="keyword"
glab api --method GET search -f scope=issues -f search="auth"

# GraphQL
glab api graphql -f query='
query {
  currentUser {
    username
    projectMemberships {
      nodes {
        project { name }
      }
    }
  }
}'
```

---

## runner

```bash
# Регистрация GitLab Runner
glab runner register \
  --url https://gitlab.com \
  --token <registration-token> \
  --description "my-runner" \
  --executor docker

# Список
glab runner list
glab runner list --all

# Просмотр
glab runner view <runner-id>

# Удалить
glab runner delete <runner-id>

# Статистика
glab api projects/:id/runners
glab api projects/:id/runners --method POST -f runner_id=<id>
```

---

## Конфигурация glab

```bash
# Конфигурационный файл
# Linux/macOS: ~/.config/glab-cli/config.yml
# Windows: %AppData%\glab-cli\config.yml

# Установка дефолтного хоста
glab config set host gitlab.com

# Установка дефолтного протокола
glab config set git_protocol ssh

# Установка редактора
glab config set editor "code --wait"

# Browser
glab config set browser "code"

# Prompt
glab config set --global prompt.enabled false

# Просмотр
glab config list
```

### Пример конфига

```yaml
# ~/.config/glab-cli/config.yml
hosts:
  gitlab.com:
    token: <token>
    git_protocol: https
  gitlab.company.com:
    token: <token>
    git_protocol: ssh
editor: code --wait
browser: code
git_protocol: ssh
```
