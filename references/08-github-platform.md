# 08 — GitHub: платформенные возможности

> Полный справочник по платформенным возможностям GitHub.

---

## Содержание
1. [Issues — задачи](#issues)
2. [Labels & Milestones](#labels--milestones)
3. [Projects (канбан-доски)](#projects-канбан-доски)
4. [Pull Requests (PR)](#pull-requests)
5. [Code Review](#code-review)
6. [Releases](#releases)
7. [Discussions](#discussions)
8. [Wiki](#wiki)
9. [GitHub Pages](#github-pages)
10. [Gists](#gists)
11. [Fork](#fork)
12. [Organizations & Teams](#organizations--teams)
13. [Templates](#templates)
14. [Insights / Pulse / Traffic](#insights--pulse--traffic)
15. [Webhooks](#webhooks)
16. [API](#api-rest--graphql)
17. [GitHub Packages](#github-packages)
18. [GitHub Apps / OAuth Apps](#github-apps--oauth-apps)
19. [Sponsors](#sponsors)

---

## Issues

Issues — встроенный таск-трекер для отслеживания багов, фич, задач.

### Создание

```bash
# Через gh CLI
gh issue create --title "Баг: логин не работает" --body "Описание бага..."
gh issue create --title "Фича: тёмная тема" --label "enhancement" --assignee "@me"
gh issue create --title "Задача" --project "Roadmap Q4" --milestone "v2.0"

# Из файла
gh issue create --title "Спецификация" --body-file specs/feature-spec.md

# С несколькими метками
gh issue create --title "Баг" --label "bug,priority-high"
```

### Управление

```bash
# Список issues
gh issue list
gh issue list --label "bug"
gh issue list --assignee "@me"
gh issue list --state closed
gh issue list --search "auth in:title"

# Просмотр
gh issue view 42
gh issue view 42 --comments

# Комментирование
gh issue comment 42 --body "Подтверждаю, воспроизводится."
gh issue comment 42 --body-file comment.md

# Закрытие / открытие
gh issue close 42
gh issue close 42 --reason "not planned"
gh issue reopen 42

# Назначение
gh issue edit 42 --add-assignee "user1,user2"
gh issue edit 42 --remove-assignee "user1"

# Перенос в проект
gh issue edit 42 --add-project "Roadmap"
```

### Шаблоны Issues

Файлы `.github/ISSUE_TEMPLATE/*.md`:

```yaml
---
name: Bug Report
about: Сообщить о баге
title: "[BUG] "
labels: bug
assignees: ''
---

## Описание бага
...

## Шаги воспроизведения
1. ...
2. ...

## Ожидаемое поведение
...

## Фактическое поведение
...

## Скриншоты
...

## Окружение
- ОС:
- Браузер:
- Версия:
```

---

## Labels & Milestones

### Labels

```bash
# Создать метку
gh label create "priority-critical" --color "B60205" --description "Критический приоритет"
gh label create "good first issue" --color "7057ff"

# Список
gh label list

# Удалить
gh label delete "old-label"

# Стандартные метки GitHub
# bug, enhancement, documentation, duplicate, wontfix, help wanted, good first issue, question
```

### Milestones

```bash
# Создать milestone
gh api repos/{owner}/{repo}/milestones -f title="v2.0" -f due_on="2025-12-31"

# Список
gh api repos/{owner}/{repo}/milestones

# Привязать issue к milestone
gh issue edit 42 --milestone "v2.0"
```

---

## Projects (канбан-доски)

GitHub Projects v2 — трекинг задач в стиле Trello/Jira, с настраиваемыми полями и видами.

```bash
# Создать проект
gh project create "Roadmap Q4" --owner "@me"

# Список
gh project list

# Просмотр
gh project view 1

# Добавить issue в проект
gh project item-add 1 --url https://github.com/user/repo/issues/42

# Создать поле
gh project field-create 1 --name "Priority" --data-type "single_select" \
  --options "Critical,High,Medium,Low"

# Изменить поле элемента
gh project item-edit --id <item-id> --field-id <field-id> --project-id <project-id> --value "High"

# Удалить элемент
gh project item-delete <project-id> <item-id>
```

**Features:**
- Кастомные поля (text, number, date, single/multi select, iteration)
- Группировки, фильтры, сортировка
- Views: Board (канбан), Table (таблица), Roadmap (таймлайн)
- Inschten — диаграммы и графики
- Связь с issues, PR, drafts из любого репо

---

## Pull Requests

PR — запрос на слияние ветки. Основной инструмент code review.

```bash
# Создать PR
gh pr create --title "feat: добавлена авторизация" --body "Описание..." --base main --head feature/auth
gh pr create --fill          # автоматически из коммитов
gh pr create --draft         # черновик (WIP)
gh pr create --reviewer "user1,user2" --assignee "@me"

# Список
gh pr list
gh pr list --state open
gh pr list --author "@me"
gh pr list --label "review-required"

# Просмотр
gh pr view 42
gh pr view 42 --comments
gh pr diff 42                # посмотреть diff

# Checkout ветки PR локально
gh pr checkout 42

# Ready for review (из draft)
gh pr ready 42

# Слияние
gh pr merge 42
gh pr merge 42 --squash       # squash merge
gh pr merge 42 --rebase       # rebase merge
gh pr merge 42 --merge        # обычный merge commit
gh pr merge 42 --delete-branch  # удалить ветку после merge

# Закрыть без merge
gh pr close 42
gh pr close 42 --comment "Не актуально"

# Переоткрыть
gh pr reopen 42

# Запрос ревью
gh pr edit 42 --add-reviewer "user1"
gh pr edit 42 --remove-reviewer "user1"

# Approved / changes requested
gh pr review 42 --approve --body "LGTM"
gh pr review 42 --request-changes --body "Нужно добавить тесты"
gh pr review 42 --comment --body "Вопрос по строке 42"
```

---

## Code Review

### Inline-комментарии и suggestions

```bash
# Комментировать конкретную строку в PR
gh api repos/{owner}/{repo}/pulls/42/comments \
  -f body="Предлагаю заменить на более эффективный вариант" \
  -f commit_id=<sha> \
  -f path="src/auth.ts" \
  -f line=42 \
  -f side=RIGHT
```

**Suggestion** — предложение изменения прямо в комментарии:

```markdown
```suggestion
// Предлагаемый код
const user = await User.findById(id);
```
```

One-click apply — пользователь может применить suggestion прямо из UI.

### CODEOWNERS

Файл `.github/CODEOWNERS` — авто-назначение ревьюеров по путям:

```text
# По умолчанию
*                       @team-lead

# По директориям
/src/auth/              @auth-team @security-lead
/src/api/               @api-team
/docs/                  @docs-team

# По расширениям
*.md                    @docs-team
*.proto                 @proto-team

# Конкретные файлы
/package.json           @devops-team
/Dockerfile             @devops-team

# Шаблоны
/src/**/test_*.py       @qa-team
```

### Review requests

```bash
# Запрос ревью
gh pr edit 42 --add-reviewer "user1,user2,team/org"

# Групповой запрос (весь код команды)
gh pr edit 42 --add-reviewer "team/frontend"
```

---

## Releases

Привязка бинарных артефактов к тегам.

```bash
# Создать release
gh release create v1.0.0 --title "Релиз 1.0.0" --notes "Описание релиза"
gh release create v1.0.0 --notes-file CHANGELOG.md
gh release create v1.0.0 --generate-notes     # авто-генерация из коммитов

# С бинарными артефактами
gh release create v1.0.0 ./dist/app-linux.tar.gz ./dist/app-mac.tar.gz

# Draft (неопубликованный)
gh release create v1.0.0 --draft --notes "Pending review"

# Pre-release
gh release create v1.0.0-rc.1 --prerelease --notes "Release candidate"

# Список
gh release list

# Просмотр
gh release view v1.0.0

# Скачать артефакты
gh release download v1.0.0
gh release download v1.0.0 --pattern "*.tar.gz" --dir ./downloads

# Удалить
gh release delete v1.0.0

# Загрузить дополнительный артефакт
gh release upload v1.0.0 ./new-artifact.zip --clobber
```

---

## Discussions

Форум/вопросы отдельно от Issues. Для Q&A, идей, обсуждений.

```bash
# Включить Discussions в репо
gh api repos/{owner}/{repo} -X PATCH -f has_discussions=true

# Создать discussion (через API/GraphQL)
gh api graphql -f query='
mutation {
  createDiscussion(input: {
    repositoryId: "<repo-node-id>",
    categoryId: "<category-node-id>",
    title: "Идея: добавить экспорт в PDF",
    body: "Описание..."
  }) {
    discussion {
      number
      url
    }
  }
}'

# Категории Discussions:
# - Announcements (объявления)
# - General (общее)
# - Ideas (идеи)
# - Q&A (вопросы и ответы)
# - Show and tell (показать и рассказать)
```

---

## Wiki

Встроенная вики-документация проекта. Каждая страница — Markdown, версионированная в git.

```bash
# Клонировать wiki
git clone https://github.com/user/repo.wiki.git

# Структура
# Home.md         → главная страница
# Page-Name.md    → страница "Page Name"
# images/         → изображения

# Push изменений
cd repo.wiki
echo "# Документация" > Home.md
git add . && git commit -m "docs: обновлена вики" && git push
```

---

## GitHub Pages

Хостинг статических сайтов прямо из репо.

```bash
# Включить Pages через API
gh api repos/{owner}/{repo}/pages -X POST \
  -f source='{"branch":"main","path":"/"}'

# Настройка источника (ветка/directory)
gh api repos/{owner}/{repo}/pages -X PUT \
  -f source='{"branch":"gh-pages","path":"/"}'

# Использование GitHub Actions для деплоя
# .github/workflows/pages.yml:
# jobs:
#   deploy:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - uses: actions/configure-pages@v4
#       - uses: actions/upload-pages-artifact@v3
#         with:
#           path: ./dist
#       - uses: actions/deploy-pages@v4
```

URL формата:
- `https://<user>.github.io/<repo>/` — проектные страницы
- `https://<user>.github.io/` — пользовательские/организационные страницы
- Кастомный домен: Settings → Pages → Custom domain

---

## Gists

Сниппеты кода с версионированием. Публичные или секретные (не индексируются).

```bash
# Создать gist
gh gist create snippet.py --desc "Полезный сниппет" --public
gh gist create snippet.py --desc "Приватный сниппет" --secret

# Из stdin
echo "print('hello')" | gh gist create --filename hello.py

# Список
gh gist list

# Просмотр
gh gist view <gist-id>
gh gist view <gist-id> --raw

# Клонирование
gh gist clone <gist-id> my-gist

# Редактирование
gh gist edit <gist-id> --filename snippet.py --content "new code"

# Удаление
gh gist delete <gist-id>
```

---

## Fork

```bash
# Fork репозитория
gh repo fork user/repo --clone

# Fork без клонирования
gh repo fork user/repo

# Синхронизация fork с upstream
gh repo sync owner/repo --source upstream/repo

# Ручная синхронизация через git
git remote add upstream https://github.com/original/repo.git
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

---

## Organizations & Teams

```bash
# Создать организацию (через web UI)
# https://github.com/organizations/new

# Список членов организации
gh api orgs/{org}/members

# Команды
gh api orgs/{org}/teams
gh api orgs/{org}/teams -f name="frontend" -f description="Frontend Team"

# Добавить члена в команду
gh api orgs/{org}/teams/{team-slug}/memberships/{username} -f role="member"

# Доступы команды к репо
gh api orgs/{org}/teams/{team-slug}/repos/{owner}/{repo} -f permission="push"
```

### Roles в организации

| Role | Возможности |
|------|-------------|
| Owner | Полный доступ к организации |
| Member | Базовый доступ, создание репо |
| Billing manager | Управление биллингом |

---

## Templates

### Шаблоны репозиториев

Создать репо из шаблона:
```bash
gh repo create my-project --template user/template-repo
```

### Шаблоны Issue/PR

`.github/ISSUE_TEMPLATE/*.md` — выбор типа при создании issue.

`.github/PULL_REQUEST_TEMPLATE.md` — шаблон для всех PR.

```markdown
## Описание изменений

## Тип изменения
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Чек-лист
- [ ] Добавлены тесты
- [ ] Документация обновлена
- [ ] CHANGELOG обновлён
```

---

## Insights / Pulse / Traffic

```bash
# Просмотр активности
gh api repos/{owner}/{repo}/stats/contributors
gh api repos/{owner}/{repo}/stats/commit_activity
gh api repos/{owner}/{repo}/stats/code_frequency

# Traffic — посещаемость
gh api repos/{owner}/{repo}/traffic/views
gh api repos/{owner}/{repo}/traffic/clones
gh api repos/{owner}/{repo}/traffic/popular/referrers

# Pulse (через web): https://github.com/user/repo/pulse
```

---

## Webhooks

Уведомления о событиях репозитория во внешние системы.

```bash
# Создать webhook
gh api repos/{owner}/{repo}/hooks \
  -f name="web" \
  -f active=true \
  -f events="push,pull_request,issues" \
  -f config[url]="https://example.com/webhook" \
  -f config[content_type]="json"

# Список webhooks
gh api repos/{owner}/{repo}/hooks

# Удалить
gh api repos/{owner}/{repo}/hooks/{hook-id} -X DELETE

# Тестовый ping
gh api repos/{owner}/{repo}/hooks/{hook-id}/tests -X POST
```

**Типичные события:**
`push`, `pull_request`, `issues`, `issue_comment`, `release`, `fork`, `star`, `create`, `delete`, `deployment`, `workflow_run`

---

## API (REST & GraphQL)

### REST API

```bash
# Базовый URL: https://api.github.com
gh api repos/{owner}/{repo}
gh api repos/{owner}/{repo}/issues
gh api repos/{owner}/{repo}/pulls
gh api user
gh api user/repos --paginate
```

### GraphQL API

```bash
# Базовый URL: https://api.github.com/graphql
gh api graphql -f query='
query {
  viewer {
    login
    repositories(first: 5) {
      nodes {
        name
        stargazerCount
      }
    }
  }
}'
```

**Rate limits:**
- REST: 5000 requests/hour (authenticated)
- GraphQL: 5000 points/hour

---

## GitHub Packages

Хранилище пакетов: Docker, npm, Maven, NuGet, RubyGems.

```bash
# Docker
docker login ghcr.io -u <user> -p <token>
docker build -t ghcr.io/<user>/<package>:latest .
docker push ghcr.io/<user>/<package>:latest

# npm
npm publish --registry https://npm.pkg.github.com
npm install @<owner>/<package>

# Maven, NuGet, RubyGems — аналогично через package registries
```

---

## GitHub Apps / OAuth Apps

### GitHub Apps

```bash
# Создать GitHub App: Settings → Developer settings → GitHub Apps → New

# Установка через manifest
gh api orgs/{org}/app-manifests/{code}/conversions -X POST

# JWT-токен для App (для API-запросов)
# 1. Сгенерировать private key в настройках App
# 2. Создать JWT
# 3. Получить installation token
gh api app/installations
gh api app/installations/{id}/access_tokens -X POST
```

### OAuth Apps

```bash
# Авторизация через OAuth flow
gh auth login --hostname github.com --git-protocol https --web
```

### Differences

| Свойство | GitHub App | OAuth App |
|----------|-----------|-----------|
| Авторизация | Как приложение | Как пользователь |
| Scope | На уровне репо/орг | На уровне пользователя |
| Webhooks | Можно подписаться | Только глобальные |
| Установка | На организацию/репо | На пользователя |
| Rate limit | 5000+ per install | 5000 per user |

---

## Sponsors

Финансовая поддержка авторов open source.

```bash
# Включить Sponsors: https://github.com/sponsors
# Файл .github/FUNDING.yml:
# custom: ["https://www.paypal.me/user"]
# patreon: username
# open_collective: project
# github: username
# ko_fi: username
# tidelift: npm/package-name
# community_bridge: project-name
# liberapay: username
# issuehunt: username
# otechie: username
# lfx_crowdfunding: project-name
```
