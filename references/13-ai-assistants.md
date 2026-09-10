# 13 — AI-ассистенты и Copilot

> Обзор AI-инструментов на платформах GitHub и GitLab.

---

## Содержание
1. [GitHub Copilot — обзор](#github-copilot)
2. [GitHub Copilot CLI](#github-copilot-cli)
3. [GitHub Copilot в редакторах](#github-copilot-в-редакторах)
4. [Copilot Enterprise/Workspace](#copilot-enterpriseworkspace)
5. [AI-агенты на платформах](#ai-агенты-на-платформах)
6. [GitLab AI](#gitlab-ai)
7. [Сравнение AI-возможностей](#сравнение-ai-возможностей)

---

## GitHub Copilot

GitHub Copilot — AI-ассистент для написания кода на базе моделей от OpenAI. Интегрирован в редакторы и предоставляет:

- **Autocomplete** — автодополнение кода в реальном времени
- **Chat** — чат с кодом, ответы на вопросы о кодовой базе
- **Inline chat** — чат прямо в редакторе (Alt+I / Cmd+I)
- **PR review** — AI-ревью pull requests
- **Commit messages** — генерация сообщений коммитов
- **Code explanation** — объяснение сложных участков кода
- **Test generation** — автоматическая генерация тестов
- **Fix suggestions** — предложения исправления ошибок

### Планы

| План | Для кого | Возможности |
|------|----------|-------------|
| **Free** | Студенты, контрибьюторы OSS | Автодополнение, базовый чат |
| **Pro** | Индивидуальные разработчики | + Chat, inline chat, PR review |
| **Business** | Команды | + Управление, политика, аналитика |
| **Enterprise** | Организации | + Copilot Enterprise features, настраиваемость |

### Включение

```bash
# Проверить доступность
gh copilot --version

# Настройка через VS Code
# Extensions → install "GitHub Copilot"
# Sign in with GitHub account

# Настройка через JetBrains
# Settings → Plugins → "GitHub Copilot"
# Sign in with GitHub account
```

---

## GitHub Copilot CLI

`gh copilot` — CLI-интерфейс для Copilot. Помогает с shell-командами и объяснением.

```bash
# Объяснить команду
gh copilot explain "awk '{print $2}' file.txt | sort | uniq -c"

# Предложить команду
gh copilot suggest "найди все файлы больше 100MB и удали пустые"

# Интерактивный режим
gh copilot suggest -t shell "удалить все ветки кроме main"

# Типы:
# -t shell    → shell-команды
# -t gh       → gh-команды
```

### Алиасы для удобства

```bash
# .bashrc / .zshrc
eval "$(gh copilot alias -- bash)"
eval "$(gh copilot alias -- zsh)"

# Теперь:
ghcs    # gh copilot suggest
ghce    # gh copilot explain
```

---

## GitHub Copilot в редакторах

### VS Code

- **Tab** — принять автодополнение
- **Esc** — отклонить
- **Alt+]** / **Alt+[** — следующее/предыдущее предложение
- **Ctrl+Enter** — показать 10 предложений
- **Alt+/** — inline-чат в редакторе
- **Ctrl+Shift+P → "GitHub Copilot"** — команды

### JetBrains (IntelliJ, PyCharm, WebStorm)

- **Tab** — принять
- **Alt+Enter** → "Show Copilot" — открыть панель
- **Ctrl+Shift+A → "Copilot"** — команды

### Neovim

```lua
-- plugins.lua
use { 'zbirenbaum/copilot.lua' }
require('copilot').setup({
  suggestion = { enabled = true, auto_trigger = true },
})
```

### Промпт-инжиниринг для Copilot

```python
# Copilot генерирует лучше, если в комментарии указать:
# - Тип данных (входные/выходные)
# - Что функция делает
# - Крайние случаи
# - Стиль кодирования

# Плохо:
# Функция валидации

# Хорошо:
# Валидация email-адреса.
# Вход: string, выход: boolean.
# Использует regex RFC 5322.
# Возвращает False для пустой строки.
```

---

## Copilot Enterprise/Workspace

### GitHub Copilot Enterprise

- **Knowledge base** — индексация приватной документации и wiki
- **Chat в организации** — ответы с учётом контекста организации
- **PR summaries** — автоматические описания PR
- **Code review** — автоматический review PR
- **Onboarding** — ответы на вопросы новых разработчиков о кодовой базе

```bash
# Управление через API
gh api orgs/{org}/copilot/billing --method GET
gh api orgs/{org}/copilot/seats --method GET
```

### GitHub Copilot Workspace

- Агентная среда для выполнения задач
- От issue → к плану → к коду → к PR
- Автономно: читает issue, предлагает план, пишет код, создаёт PR

```bash
# Workspace доступен через web-интерфейс GitHub
# Settings → Copilot → Workspace → Enable
```

---

## AI-агенты на платформах

### GitHub Models

GitHub предоставляет доступ к LLM-моделям через API:

```bash
# Список доступных моделей
gh api /models

# Использование через REST
gh api /models/gpt-4o/chat/completions -X POST \
  -f messages='[{"role":"user","content":"Объясни этот код"}]'

# Через GitHub Models playground
# https://github.com/marketplace/models
```

**Доступные модели:**
- GPT-4o, GPT-4o-mini (OpenAI)
- Llama 3.1 (Meta)
- Mistral Large (Mistral AI)
- Phi-3 (Microsoft)
- Cohere Command R (Cohere)

### GitHub Copilot API

```bash
# Chat completion через Copilot
gh api /copilot/chat/completions -X POST \
  -f messages='[{"role":"system","content":"Ты эксперт по git"},{"role":"user","content":"Как сделать rebase?"}]'

# Embeddings
gh api /copilot/embeddings -X POST \
  -f input="git rebase main"
```

### GitHub Copilot Extensions

Сторонние расширения Copilot — интеграции с внешними сервисами:

```bash
# Установка расширения
gh extension install owner/copilot-extension-name

# Известные расширения:
# - Docker Copilot — контейнеризация
# - MongoDB Copilot — работа с MongoDB
# - Sentry Copilot — анализ ошибок
# - Datadog Copilot — мониторинг
# - LambdaTest Copilot — тестирование
```

---

## GitLab AI

### GitLab Duo

GitLab Duo — набор AI-возможностей GitLab:

| Возможность | Описание |
|-------------|----------|
| **Code Suggestions** | Автодополнение кода в редакторе |
| **Chat** | Чат с кодом и CI/CD |
| **MR Summary** | Авто-описание Merge Requests |
| **Issue Description** | Генерация описаний issues |
| **Code Review** | AI-ревью MR |
| **Test Generation** | Генерация тестов |
| **Vulnerability Explanation** | Объяснение уязвимостей и код исправления |
| **Root Cause Analysis** | Анализ причин неудачных пайплайнов |

### Настройка

```bash
# Включение Duo
glab api groups/:id/duo_features --method PUT -f duo_features_enabled=true

# Проверка доступа
glab api groups/:id/duo_seat_assignments

# Code Suggestions в VS Code:
# Extensions → "GitLab Workflow" → Install
# Settings → GitLab: Enable Code Suggestions
```

### GitLab Duo Chat

```bash
# Через glab (если доступно)
glab duo ask "Как настроить CI/CD pipeline для Python проекта?"

# Через VS Code extension
# Открыть GitLab panel → Duo Chat
# Задать вопрос о коде, пайплайне, issue
```

### GitLab Duo in CI/CD

```yaml
# .gitlab-ci.yml — AI-генерация MR описания
include:
  - template: 'Duo/Description-Generation.gitlab-ci.yml'

# AI root cause analysis
test:
  script:
    - npm test
  allow_failure: false
  # При неудаче — Duo предложит анализ причины
```

---

## Сравнение AI-возможностей

| Возможность | GitHub Copilot | GitLab Duo |
|-------------|---------------|------------|
| Автодополнение | ✅ | ✅ Code Suggestions |
| Чат | ✅ Chat | ✅ Duo Chat |
| Inline-чат | ✅ | ✅ |
| PR/MR Summary | ✅ (Enterprise) | ✅ |
| Code Review | ✅ (Enterprise) | ✅ |
| Тесты | ✅ | ✅ |
| Объяснение уязвимостей | ✅ (CodeQL) | ✅ |
| CLI | ✅ gh copilot | ⚠️ ограничено |
| API | ✅ Copilot API + Models | ✅ Duo API |
| Расширения | ✅ сторонние | ❌ |
| Кастомные модели | ✅ Models marketplace | ❌ |
| Self-hosted | ❌ | ✅ (Self-managed GitLab) |
| План Free | ✅ (ограниченный) | ❌ (Premium+) |

---

## Практические советы

1. **Контекст решает** — Copilot/Duo работают лучше, когда в файле есть типы, комментарии и согласованный стиль
2. **Ревью обязателен** — AI-код нужно ревьюить так же, как человеческий
3. **Безопасность** — не вставляйте секреты в промпты; AI может их запомнить
4. **Тестируйте** — AI-сгенерированный код требует тестов; не доверяйте слепо
5. **Учитесь** — используйте AI для обучения: просите объяснить сложный код, паттерны, алгоритмы
6. **Автоматизируйте рутины** — генерация boilerplate, тестов, документации, коммит-сообщений
