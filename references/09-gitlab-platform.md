# 09 — GitLab: платформенные возможности

> Полный справочник по платформенным возможностям GitLab.

---

## Содержание
1. [Issues](#issues)
2. [Merge Requests (MR)](#merge-requests-mr)
3. [Labels & Milestones](#labels--milestones)
4. [Boards (канбан)](#boards-канбан)
5. [CI/CD Pipelines](#cicd-pipelines)
6. [Environments & Deployments](#environments--deployments)
7. [Container Registry](#container-registry)
8. [GitLab Pages](#gitlab-pages)
9. [Wiki](#wiki)
10. [Releases](#releases)
11. [Snippets](#snippets)
12. [Groups & Subgroups](#groups--subgroups)
13. [Webhooks](#webhooks)
14. [API](#api)
15. [GitLab Agent for Kubernetes](#gitlab-agent-for-kubernetes)

---

## Issues

```bash
# Создать issue
glab issue create --title "Баг: поиск не работает" --description "Описание..."
glab issue create --title "Фича: экспорт в PDF" --label "enhancement" --assignee "@me"
glab issue create --title "Задача" --milestone "v2.0"

# Список
glab issue list
glab issue list --label "bug"
glab issue list --assignee "@me"
glab issue list --closed

# Просмотр
glab issue view 42
glab issue view 42 --comments

# Комментирование
glab issue comment 42 --message "Подтверждаю"
glab issue comment 42 --file comment.md

# Закрыть / открыть
glab issue close 42
glab issue reopen 42

# Назначение
glab issue update 42 --assignee "user1"
```

---

## Merge Requests (MR)

Аналог PR в GitHub.

```bash
# Создать MR
glab mr create --title "feat: добавлена авторизация" --description "..." --target-branch main --source-branch feature/auth
glab mr create --fill                  # авто-заполнение
glab mr create --draft                 --title "WIP: эксперимент"
glab mr create --reviewer "user1,user2" --assignee "@me"

# Список
glab mr list
glab mr list --state opened
glab mr list --author "@me"
glab mr list --label "review-required"

# Просмотр
glab mr view 42
glab mr diff 42

# Checkout MR локально
glab mr checkout 42

# Слияние
glab mr merge 42
glab mr merge 42 --squash
glab mr merge 42 --rebase
glab mr merge 42 --remove-source-branch

# Закрыть без merge
glab mr close 42
glab mr reopen 42

# Code review
glab mr review 42 --approve
glab mr review 42 --request-changes --comment "Нужны тесты"
glab mr note 42 --message "Комментарий"

# Запрос ревью
glab mr update 42 --reviewer "user1,user2"
```

---

## Labels & Milestones

```bash
# Labels
glab label create "priority-critical" --color "#B60205" --description "Критический"
glab label list

# Milestones
glab api projects/:id/milestones --method POST -f title="v2.0" -f due_date="2025-12-31"
glab issue update 42 --milestone "v2.0"
```

---

## Boards (канбан)

GitLab Issue Boards — канбан-доски для управления задачами.

```bash
# Создать board (через API)
glab api projects/:id/boards --method POST -f name="Sprint Board"

# Список boards
glab api projects/:id/boards

# Создать список (колонку) в board
glab api projects/:id/boards/:board_id/lists --method POST -f label_id=<label_id>
```

**Features:**
- Несколько boards на проект
- Колонки по меткам
- Drag-and-drop
- Связь с issues и MR
- фильтры и группировки

---

## CI/CD Pipelines

GitLab CI/CD — встроенная система непрерывной интеграции и деплоя.

### Конфигурация `.gitlab-ci.yml`

```yaml
# Стадии
stages:
  - build
  - test
  - deploy

# Переменные
variables:
  IMAGE_NAME: "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME"

# Сборка
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $IMAGE_NAME .
    - docker push $IMAGE_NAME
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

# Тесты
test:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm test
  coverage: '/Lines.*\s+(\d+\.\d+)\%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/

# Деплой
deploy:prod:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl apply -f k8s/
  environment:
    name: production
    url: https://app.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  when: manual    # ручной запуск
```

### Управление через CLI

```bash
# Список pipeline
glab ci list
glab ci view

# Просмотр пайплайна
glab ci view --branch=main

# Повторный запуск
glab ci retry
glab ci retry --branch=main

# Логи конкретного job
glab ci trace
glab ci trace --branch=main --job=build

# Запуск нового pipeline
glab ci run --branch=feature/auth
glab ci run --variables "KEY=value"
```

### Runners

```bash
# Регистрация runner
glab runner register \
  --url https://gitlab.com \
  --token <token> \
  --description "my-runner" \
  --executor docker \
  --docker-image "alpine:latest"

# Список runners
glab runner list

# Статус
glab runner list --all
```

---

## Environments & Deployments

```bash
# Список environments (через API)
glab api projects/:id/environments

# Остановить/запустить environment
glab api projects/:id/environments/:env_id/stop --method POST
glab api projects/:id/environments/:env_id/start --method POST

# Защищённые environments (approval gates)
# В .gitlab-ci.yml:
# deploy:prod:
#   environment:
#     name: production
#   rules:
#     - if: $CI_COMMIT_BRANCH == "main"
#       when: manual
```

---

## Container Registry

GitLab Container Registry — встроенное хранилище Docker-образов.

```bash
# Логин
docker login registry.gitlab.com -u <username> -p <token>

# Сборка и push
docker build -t registry.gitlab.com/<group>/<project>:latest .
docker push registry.gitlab.com/<group>/<project>:latest

# В CI/CD (автоматическая авторизация)
# script:
#   - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
#   - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
#   - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

# Удаление тегов
glab api projects/:id/registry/repositories/:repository_id/tags/:tag_name --method DELETE
```

---

## GitLab Pages

Хостинг статических сайтов.

```yaml
# .gitlab-ci.yml
pages:
  stage: deploy
  image: node:20
  script:
    - npm run build
    - mv dist public
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

URL: `https://<username>.gitlab.io/<project>/`

---

## Wiki

```bash
# Клонировать wiki
git clone https://gitlab.com/user/repo.wiki.git

# Структура — как у GitHub Wiki
# Home.md → главная
```

---

## Releases

```bash
# Создать release
glab release create v1.0.0 --name "Релиз 1.0.0" --notes "Описание"
glab release create v1.0.0 --notes-file CHANGELOG.md
glab release create v1.0.0 --assets ./dist/app.tar.gz

# Список
glab release list

# Просмотр
glab release view v1.0.0

# Скачать
glab release download v1.0.0

# Удалить
glab release delete v1.0.0
```

---

## Snippets

Аналог Gists в GitHub.

```bash
# Создать
glab snippet create snippet.py --title "Полезный сниппет" --visibility public
glab snippet create --file snippet.py --title "Приватный" --visibility private

# Из stdin
echo "print('hello')" | glab snippet create --title "Hello"

# Список
glab snippet list

# Просмотр
glab snippet view <id>

# Удалить
glab snippet delete <id>
```

---

## Groups & Subgroups

```bash
# Создать группу
glab api groups --method POST -f name="my-org" -f path="my-org" -f visibility="private"

# Создать подгруппу
glab api groups --method POST -f name="backend" -f path="backend" -f parent_id=<parent_group_id> -f visibility="private"

# Список членов группы
glab api groups/:group/members

# Добавить члена
glab api groups/:group/members --method POST -f user_id=<id> -f access_level=30

# Access levels:
# 10  — Guest
# 20  — Reporter
# 30  — Developer
# 40  — Maintainer
# 50  — Owner
```

---

## Webhooks

```bash
# Создать webhook
glab api projects/:id/hooks --method POST \
  -f url="https://example.com/webhook" \
  -f push_events=true \
  -f merge_requests_events=true \
  -f issues_events=true

# Список
glab api projects/:id/hooks

# Удалить
glab api projects/:id/hooks/:hook_id --method DELETE
```

**События:** `push_events`, `merge_requests_events`, `issues_events`, `tag_push_events`, `release_events`, `pipeline_events`, `job_events`

---

## API

```bash
# REST API v4
glab api projects
glab api projects/:id
glab api groups
glab api user

# Поиск
glab api search --method GET -f scope=projects -f search="keyword"

# Пагинация
glab api projects --paginate

# Rate limits:
# Аутентифицированный: 2000 req/min
# GraphQL: 100 req/min
```

### GraphQL API

```bash
glab api graphql -f query='
query {
  currentUser {
    username
    projectMemberships {
      nodes {
        project {
          name
        }
      }
    }
  }
}'
```

---

## GitLab Agent for Kubernetes

```bash
# Регистрация агента
glab api projects/:id/cluster_agents --method POST -f name="production-cluster"

# Получение токена
glab api projects/:id/cluster_agents/:agent_id --method GET

# Конфигурация: .gitlab/agents/<agent-name>/config.yaml
```

```yaml
# .gitlab/agents/production/config.yaml
ci_access:
  projects:
    - id: group/project
      access: as_container_image_deployer
```
