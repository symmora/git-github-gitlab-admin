# 12 — Безопасность и CI/CD на платформах

> Полный справочник по средствам безопасности и CI/CD на GitHub и GitLab.

---

## Содержание
1. [GitHub: Dependabot](#github-dependabot)
2. [GitHub: Secret Scanning](#github-secret-scanning)
3. [GitHub: CodeQL](#github-codeql)
4. [GitHub: Branch Protection](#github-branch-protection)
5. [GitHub Actions — CI/CD](#github-actions)
6. [GitHub Environments](#github-environments)
7. [GitLab CI/CD Security](#gitlab-cicd-security)
8. [GitLab Branch Protection](#gitlab-branch-protection)
9. [Сравнение возможностей](#сравнение-возможностей)

---

## GitHub Dependabot

Автоматические PR на обновление уязвимых и устаревших зависимостей.

### Конфигурация `.github/dependabot.yml`

```yaml
version: 2
updates:
  # npm
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Europe/Moscow"
    open-pull-requests-limit: 10
    reviewers:
      - "user1"
    assignees:
      - "@me"
    commit-message:
      prefix: "chore"
      include: "scope"
    labels:
      - "dependencies"
      - "npm"
    target-branch: "develop"

  # Docker
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

  # pip (Python)
  - package-ecosystem: "pip"
    directory: "/requirements"
    schedule:
      interval: "daily"

  # Maven, Gradle, NuGet, Cargo, Go, Terraform, etc.
```

### Управление

```bash
# Просмотр alerts безопасности
gh api repos/{owner}/{repo}/dependabot/alerts
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[] | select(.state=="open") | .security_advisory.summary'

# Обновить alerts (auto-dismiss, reopen)
gh api repos/{owner}/{repo}/dependabot/alerts/{alert-number} -X PATCH -f state="dismissed" -f dismissed_reason="tolerable_risk"
```

---

## GitHub Secret Scanning

Автоматическое обнаружение токенов, паролей, ключей в коде.

### Включение

```bash
# Через API
gh api repos/{owner}/{repo} -X PATCH -f security_and_analysis='{"secret_scanning":{"status":"enabled"}}'
gh api repos/{owner}/{repo} -X PATCH -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"advanced_security":{"status":"enabled"}}'
```

### Push Protection

GitHub блокирует push, если в нём обнаружен секрет:

```bash
# Push protection включается в Settings → Code security
# При попытке push секрета:
# remote: ! pushing commit abc1234
# remote: rejected — contains secret
# remote: To push anyway, use: git push --option push_option=...
# Или удалить секрет и закоммитить заново

# Обход (только если секрет — тестовый/false positive):
git push --push-option=push_option-from-secret-scanning
```

### Custom patterns

```bash
# Добавить кастомный pattern для секретов
gh api repos/{owner}/{repo}/secret-scanning/autosearch -X POST \
  -f name="Internal API Key" \
  -f pattern="INT_KEY_[a-zA-Z0-9]{32}"
```

---

## GitHub CodeQL

Статический анализ кода на уязвимости.

### Настройка через Actions

```yaml
# .github/workflows/codeql.yml
name: "CodeQL"

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 0 * * 1"  # каждый понедельник

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    strategy:
      matrix:
        language: [javascript, python, go, java]
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-and-quality
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
```

### Управление

```bash
# Просмотр Code Scanning alerts
gh api repos/{owner}/{repo}/code-scanning/alerts
gh api repos/{owner}/{repo}/code-scanning/alerts --jq '.[] | select(.state=="open") | .rule.description'

# Закрыть alert
gh api repos/{owner}/{repo}/code-scanning/alerts/{alert-number} -X PATCH -f state="dismissed" -f dismissed_reason="false positive"
```

---

## GitHub Branch Protection

Защита веток от несанкционированных изменений.

```bash
# Установить правила защиты ветки main
gh api repos/{owner}/{repo}/branches/main/protection -X PUT \
  -f required_status_checks='{"strict":true,"contexts":["CI / build","CI / test"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  -f restrictions='{"users":[],"teams":[]}' \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false

# Просмотр
gh api repos/{owner}/{repo}/branches/main/protection

# Удалить защиту
gh api repos/{owner}/{repo}/branches/main/protection -X DELETE
```

**Ключевые параметры:**

| Параметр | Описание |
|----------|----------|
| `required_status_checks.strict` | Требуется успешный CI перед merge |
| `required_pull_request_reviews` | Обязательный PR review |
| `required_approving_review_count` | Количество одобрений |
| `require_code_owner_reviews` | CODEOWNERS обязаны ревьюить |
| `enforce_admins` | Правила распространяются на админов |
| `required_linear_history` | Запрет merge-commits (только rebase/squash) |
| `allow_force_pushes` | Разрешить/запретить force push |
| `allow_deletions` | Разрешить/запретить удаление ветки |
| `restrictions` | Кто может пушить (users/teams) |

---

## GitHub Actions

### Базовая структура workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:        # ручной запуск

env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # полная история

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build

      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
          retention-days: 7

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
      - run: ./deploy.sh
```

### Matrix builds

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [18, 20, 22]
    exclude:
      - os: windows-latest
        node: 18
    include:
      - os: ubuntu-latest
        node: 20
        experimental: true
```

### Reusable workflows

```yaml
# .github/workflows/reusable-build.yml
on:
  workflow_call:
    inputs:
      env-name:
        required: true
        type: string
    secrets:
      deploy-token:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building for ${{ inputs.env-name }}"
```

```yaml
# Использование
jobs:
  call-build:
    uses: ./.github/workflows/reusable-build.yml
    with:
      env-name: production
    secrets:
      deploy-token: ${{ secrets.DEPLOY_TOKEN }}
```

### Секреты и переменные

```bash
# Секреты (зашифрованы, не видны в логах)
gh secret set DATABASE_URL --body "postgresql://..."
gh secret set API_KEY < key.txt

# Переменные (открытый текст, видны в логах)
gh variable set NODE_ENV --body "production"

# В workflow:
# ${{ secrets.DATABASE_URL }}
# ${{ vars.NODE_ENV }}
```

### Кэширование

```yaml
# Кэш npm
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'       # автоматический кэш

# Ручной кэш
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

---

## GitHub Environments

Среды деплоя с approval gates и секретами.

```bash
# Создать environment
gh api repos/{owner}/{repo}/environments/production -X PUT

# Установить правила
gh api repos/{owner}/{repo}/environments/production -X PUT \
  -f deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":true}'

# Установить reviewers (approval required)
gh api repos/{owner}/{repo}/environments/production/deployment_protection_rules -X POST \
  -f environment_name=production \
  -f reviewers='[{"type":"User","id":12345},{"type":"Team","id":67890}]'

# Установить wait timer (задержка перед деплоем)
gh api repos/{owner}/{repo}/environments/production -X PUT \
  -f wait_timer=15
```

### В workflow

```yaml
deploy:prod:
  environment:
    name: production
    url: https://app.example.com
  # Требуется approval перед выполнением
```

---

## GitLab CI/CD Security

### SAST (Static Application Security Testing)

```yaml
# .gitlab-ci.yml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml

sast:
  variables:
    SAST_EXCLUDED_PATHS: "spec, test, tests, tmp, vendor"
```

### Dependency Scanning

```yaml
gemnasium-dependency_scanning:
  extends: .dependency_scanning
  variables:
    DS_EXCLUDED_ANALYZERS: "gemnasium-maven"
```

### Container Scanning

```yaml
container_scanning:
  variables:
    CS_IMAGE: "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
```

### Secret Detection

```yaml
secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

---

## GitLab Branch Protection

```bash
# Защита ветки
glab api projects/:id/protected_branches --method POST \
  -f name=main \
  -f push_access_level=40 \
  -f merge_access_level=40 \
  -f allow_force_push=false \
  -f code_owner_approval_required=true

# Обязательные статусы (CI/CD)
glab api projects/:id/protected_branches --method POST \
  -f name=main \
  -f push_access_level=0 \
  -f merge_access_level=30 \
  -f unprotect_access_level=40

# Список защищённых веток
glab api projects/:id/protected_branches

# Удалить защиту
glab api projects/:id/protected_branches/main --method DELETE
```

### Access Levels

| Уровень | Роль | Значение |
|---------|------|----------|
| No access | — | 0 |
| Minimal | Guest | 5 |
| Read | Reporter | 10 |
| Write | Developer | 20 |
| Admin | Maintainer | 30 |
| Full | Owner | 40 |
| — | Admin | 50 |

---

## Сравнение возможностей

| Возможность | GitHub | GitLab |
|-------------|--------|--------|
| CI/CD | GitHub Actions | GitLab CI/CD |
| Файл конфигурации | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Runners | GitHub-hosted + self-hosted | GitLab-hosted + self-hosted |
| Environments | ✅ с approval gates | ✅ protected environments |
| Container Registry | GitHub Container Registry (ghcr.io) | GitLab Container Registry |
| Dependency Scanning | Dependabot | Dependency Scanning |
| Secret Scanning | ✅ + Push Protection | ✅ Secret Detection |
| SAST | CodeQL | GitLab SAST |
| Packages | GitHub Packages | GitLab Package Registry |
| Pages | GitHub Pages | GitLab Pages |
| Branch Protection | ✅ | ✅ |
| Merge Strategies | merge, squash, rebase | merge, squash, rebase, cherry-pick |
| Code Review | PR + inline + suggestions | MR + inline + suggestions |
| CODEOWNERS | ✅ | ✅ |
| Templates | Issue, PR, Repo | Issue, MR templates |
| Security Dashboard | ✅ (Advanced Security) | ✅ (Ultimate) |
