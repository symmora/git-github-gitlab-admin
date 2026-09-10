# 10 — GitHub CLI (gh) — полный справочник

> Справочник по всем основным командам `gh` — официального GitHub CLI.

---

## Содержание
1. [Установка и авторизация](#установка-и-авторизация)
2. [repo — репозитории](#repo)
3. [issue — задачи](#issue)
4. [pr — pull requests](#pr)
5. [workflow — GitHub Actions](#workflow)
6. [run — запуски](#run)
7. [release — релизы](#release)
8. [gist — сниппеты](#gist)
9. [secret — секреты](#secret)
10. [variable — переменные](#variable)
11. [label — метки](#label)
12. [project — проекты](#project)
13. [api — прямой доступ к API](#api)
14. [codespace — Codespaces](#codespace)
15. [extension — расширения](#extension)
16. [cache — кэш Actions](#cache)
17. [browse — открытие в браузере](#browse)
18. [Конфигурация gh](#конфигурация-gh)

---

## Установка и авторизация

```bash
# Проверка установки
gh --version

# Авторизация (интерактивно)
gh auth login
# Выбор: GitHub.com / GitHub Enterprise
# Выбор: HTTPS / SSH
# Выбор: вход через браузер / вставка токена

# Авторизация с токеном (для автоматизации)
echo "<token>" | gh auth login --with-token

# Проверка статуса
gh auth status

# Обновление токена
gh auth refresh
gh auth refresh --scopes "repo,workflow,read:org"

# Выход
gh auth logout

# Управление учётными записями (несколько аккаунтов)
gh auth switch --user "username"
gh auth status --show-token
```

---

## repo

```bash
# Создать репозиторий
gh repo create my-project --public --source=. --push
gh repo create my-project --private --source=. --push
gh repo create org/my-project --internal --source=. --push
gh repo create --template user/template-repo my-project

# Клонировать
gh repo clone user/repo
gh repo clone user/repo my-local-dir

# Просмотр
gh repo view
gh repo view user/repo --web

# Форк
gh repo fork user/repo --clone
gh repo fork user/repo --clone --remote

# Синхронизация fork
gh repo sync

# Редактирование настроек
gh repo edit --enable-issues --enable-wiki --enable-rebase-merge
gh repo edit --default-branch main
gh repo edit --delete-branch-on-merge
gh repo edit --visibility public

# Удалить
gh repo delete user/repo --yes

# Архивировать
gh repo archive user/repo

# Список репозиториев
gh repo list
gh repo list --limit 50
gh repo list --source        # только те, что вы создали (не fork)

# Перенос репозитория
gh repo transfer user/repo new-owner
```

---

## issue

```bash
# Создать
gh issue create --title "Заголовок" --body "Описание"
gh issue create --title "Bug" --label "bug,priority-high" --assignee "@me"
gh issue create --title "Feature" --project "Roadmap" --milestone "v2.0"

# Список
gh issue list
gh issue list --label "bug"
gh issue list --assignee "@me"
gh issue list --state open
gh issue list --search "auth in:title"

# Просмотр
gh issue view 42
gh issue view 42 --web
gh issue view 42 --comments

# Комментировать
gh issue comment 42 --body "Текст"
gh issue comment 42 --body-file comment.md

# Закрыть / открыть
gh issue close 42
gh issue close 42 --reason "not planned"
gh issue reopen 42

# Редактировать
gh issue edit 42 --add-label "wontfix"
gh issue edit 42 --remove-label "bug"
gh issue edit 42 --add-assignee "user1"
gh issue edit 42 --title "Новое название"

# Перенос (transfer)
gh issue transfer 42 another-repo
```

---

## pr

```bash
# Создать PR
gh pr create --title "feat: новая фича" --body "Описание" --base main --head feature
gh pr create --fill                # из коммитов (title + body)
gh pr create --draft               # черновик
gh pr create --reviewer "user1" --assignee "@me"
gh pr create --label "review-required" --project "Q4"

# Список
gh pr list
gh pr list --state open
gh pr list --author "@me"
gh pr list --label "review-required"
gh pr list --search "auth"

# Просмотр
gh pr view 42
gh pr view 42 --web
gh pr view 42 --comments
gh pr diff 42
gh pr checks 42                   # статус CI/CD чеков

# Checkout ветки PR
gh pr checkout 42

# Ready for review
gh pr ready 42

# Merge
gh pr merge 42
gh pr merge 42 --squash --delete-branch
gh pr merge 42 --rebase --auto
gh pr merge 42 --merge --subject "Merge PR #42"

# Закрыть
gh pr close 42
gh pr close 42 --comment "Не актуально"
gh pr reopen 42

# Редактировать
gh pr edit 42 --add-reviewer "user1,user2"
gh pr edit 42 --add-label "priority-high"
gh pr edit 42 --base develop

# Review
gh pr review 42 --approve --body "LGTM"
gh pr review 42 --request-changes --body "Нужны тесты"
gh pr review 42 --comment --body "Вопрос по строке 42"

# Синхронизация с remote (после rebase/merge upstream)
gh pr sync-base 42
```

---

## workflow

```bash
# Список workflows
gh workflow list

# Просмотр
gh workflow view <workflow-name-or-id>
gh workflow view <id> --yaml    # YAML-содержимое

# Запуск workflow вручную
gh workflow run <workflow-name>
gh workflow run <workflow-name> --ref feature-branch
gh workflow run <workflow-name> -f key=value -f key2=value2

# Включить / отключить
gh workflow enable <id>
gh workflow disable <id>

# Список запусков
gh run list
gh run list --workflow=<name>
gh run list --limit 10
gh run list --branch main
gh run list --status failure
```

---

## run

```bash
# Просмотр запуска
gh run view <run-id>
gh run view <run-id> --log         # логи
gh run view <run-id> --log-failed  # только упавшие шаги

# Повторный запуск
gh run rerun <run-id>
gh run rerun <run-id> --failed      # только упавшие jobs

# Отменить
gh run cancel <run-id>

# Скачать артефакты
gh run download <run-id>
gh run download <run-id> --name artifact.zip --dir ./downloads

# Удалить
gh run delete <run-id>

# Просмотр конкретного job
gh run view <run-id> --job=<job-id> --log
```

---

## release

```bash
# Создать
gh release create v1.0.0 --title "Релиз 1.0.0" --notes "Описание"
gh release create v1.0.0 --notes-file CHANGELOG.md
gh release create v1.0.0 --generate-notes    # авто из коммитов
gh release create v1.0.0 --draft --prerelease
gh release create v1.0.0 ./dist/*.tar.gz     # с артефактами

# Список
gh release list

# Просмотр
gh release view v1.0.0

# Скачать
gh release download v1.0.0
gh release download v1.0.0 --pattern "*.tar.gz" --dir ./downloads
gh release download v1.0.0 --clobber         # перезаписать существующие

# Загрузить артефакты
gh release upload v1.0.0 ./new-artifact.zip

# Удалить
gh release delete v1.0.0
gh release delete v1.0.0 --cleanup-tag       # удалить и тег
```

---

## gist

```bash
gh gist create file.py --desc "Сниппет" --public
gh gist create file.py --desc "Сниппет" --secret
gh gist list
gh gist view <id>
gh gist view <id> --raw
gh gist clone <id>
gh gist edit <id> --filename file.py --content "new code"
gh gist delete <id>
```

---

## secret

Управление секретами для GitHub Actions.

```bash
# Список секретов репо
gh secret list

# Установить секрет
gh secret set DATABASE_URL --body "postgresql://..."
gh secret set API_KEY < api-key.txt    # из файла
gh secret set MY_VAR --app actions      # для Actions

# Установить для окружения (environment)
gh secret set PROD_TOKEN --env production --body "secret-value"

# Установить для организации
gh secret set ORG_SECRET --org my-org --visibility "selected" --repos "repo1,repo2"

# Удалить
gh secret delete DATABASE_URL
gh secret delete PROD_TOKEN --env production
```

---

## variable

Управление переменными Actions (не секретные).

```bash
# Список
gh variable list

# Установить
gh variable set NODE_ENV --body "production"
gh variable set BUILD_DIR --body "dist"

# Для окружения
gh variable set DEPLOY_URL --env production --body "https://prod.example.com"

# Удалить
gh variable delete NODE_ENV
```

---

## label

```bash
gh label create "priority-critical" --color "B60205" --description "Критический"
gh label list
gh label edit "old-name" --name "new-name" --color "FF0000"
gh label delete "old-label"
```

---

## project

```bash
gh project create "Roadmap Q4" --owner "@me"
gh project list
gh project view 1
gh project item-add 1 --url https://github.com/user/repo/issues/42
gh project item-list 1
gh project item-delete 1 <item-id>
gh project field-create 1 --name "Priority" --data-type "single_select" --options "High,Medium,Low"
gh project item-edit --id <item-id> --field-id <field-id> --project-id <project-id> --value "High"
```

---

## api

```bash
# REST API
gh api user
gh api user/repos --paginate
gh api repos/{owner}/{repo}
gh api repos/{owner}/{repo}/issues -f title="Bug" -f body="Описание"

# Методы
gh api --method POST repos/{owner}/{repo}/labels -f name="bug" -f color="ff0000"
gh api --method PUT repos/{owner}/{repo}/topics -f names[]=bug,enhancement
gh api --method DELETE repos/{owner}/{repo}/labels/bug

# С пагинацией
gh api user/repos --paginate --jq '.[].full_name'

# jq-фильтрация
gh api user/repos --jq '.[] | "\(.full_name) ⭐ \(.stargazers_count)"'

# GraphQL
gh api graphql -f query='
query {
  viewer {
    login
    repositories(first: 5, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes { name updatedAt }
    }
  }
}'
```

---

## codespace

```bash
gh codespace create --repo user/repo
gh codespace create --repo user/repo --branch feature --machine basicLinux32gb
gh codespace list
gh codespace view
gh codespace code          # открыть в VS Code
gh codespace ssh          # SSH-подключение
gh codespace jupyter      # Jupyter
gh codespace stop
gh codespace delete
```

---

## extension

```bash
# Установка расширений
gh extension install owner/gh-extension-name

# Список
gh extension list

# Создание своего расширения
gh extension create my-extension

# Поиск
gh extension search keyword
```

---

## cache

Управление кэшем GitHub Actions.

```bash
gh cache list
gh cache list --ref main
gh cache delete --all
gh cache delete <cache-id>
```

---

## browse

```bash
# Открыть репо в браузере
gh browse
gh browse user/repo

# Открыть конкретный путь
gh browse src/auth/login.ts
gh browse 42        # issue #42
gh browse -p pulls/42   # PR #42
gh browse -n --settings # настройки репо
```

---

## Конфигурация gh

```bash
# Установка редактора
gh config set editor "code --wait"

# Дефолтный протокол
gh config set git_protocol ssh

# Дефолтный текстовый редактор для коммитов
gh config set editor "vim"

# Тема (light/dark/system)
gh config set theme dark

# Prompt-настройки
gh config set --global prompt.enabled true

# Просмотр всех настроек
gh config list
```
