# Git / GitHub / GitLab

**Git / GitHub / GitLab** (`git-github-gitlab`) — комплексный скилл для администрирования и повседневного использования `git`, GitHub и GitLab: от первичной настройки репозитория до продвинутого rebase, работы с платформами через `gh` и `glab` CLI, CI/CD, безопасности и AI-инструментов.

---

## Версия

`1.0.0`

---

## Назначение

`git-github-gitlab` используется, когда нужно:

- настроить git (имя, email, credential helper, SSH, дефолтная ветка);
- выполнить базовые операции: `init`, `clone`, `add`, `commit`, `push`, `pull`;
- работать с ветками, merge-стратегиями и rebase;
- применить продвинутые операции: `stash`, `cherry-pick`, `revert`, `rebase -i`, `tag`;
- расследовать историю: `log`, `diff`, `blame`, `bisect`, `reflog`;
- настроить хуки, submodules, патчи, архивы и обслуживание (`gc`, `fsck`, `sparse-checkout`);
- автоматизировать GitHub через `gh` и GitLab через `glab` CLI;
- настроить CI/CD, безопасность (Dependabot, Secret scanning, CodeQL, branch protection);
- использовать GitHub Copilot и AI-ассистенты на платформах.

---

## Основные возможности

- Полный справочник по git в 13 разделах (basics → maintenance → platform → CLI → security → AI).
- Маршрутизатор `scripts/git-router.sh` — bash-диспетчер, выполняющий последовательности git/gh/glab команд с проверками безопасности.
- Тесты `tests/test-router.sh` для проверки маршрутизатора.
- Шпаргалка по восстановлению состояния и откату операций.
- Три метода подключения к репозиториям: HTTPS + PAT, SSH, Deploy Token / CI Token.

---

## Ключевые принципы

1. **Безопасность прежде всего.**
   Деструктивные операции (`reset --hard`, `push --force`, `clean -fd`) требуют подтверждения.

2. **Понятные сообщения коммитов.**
   Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).

3. **Защита общей истории.**
   На общих ветках — `revert` вместо `reset`; `force push` только с `--force-with-lease`.

4. **Проверка перед push.**
   `git status`, `git diff --cached`, `git log` перед отправкой.

5. **Маленькие коммиты.**
   Атомарные изменения легче ревьюить и откатывать.

---

## Структура

```
git-github-gitlab-admin/
├── SKILL.md                       # Оглавление и быстрые ссылки
├── README.md                      # Документация для человека
├── references/                    # 13 справочников по темам
│   ├── 01-git-basics.md
│   ├── 02-git-branches-merge.md
│   ├── 03-git-advanced.md
│   ├── 04-git-investigation.md
│   ├── 05-git-config-hooks.md
│   ├── 06-git-patches-archive.md
│   ├── 07-git-maintenance.md
│   ├── 08-github-platform.md
│   ├── 09-gitlab-platform.md
│   ├── 10-gh-cli.md
│   ├── 11-glab-cli.md
│   ├── 12-security-cicd.md
│   └── 13-ai-assistants.md
├── scripts/
│   └── git-router.sh              # Маршрутизатор команд
└── tests/
    └── test-router.sh             # Тесты маршрутизатора
```

---

## Требования

- `git` >= 2.40
- `gh` (GitHub CLI)
- `glab` (GitLab CLI)

---

## Обновления

### 2026-09-10

**Исправлено (явные дефекты):**

- `SKILL.md` — frontmatter: многострочный `description` свёрнут в одну строку. Ранее перенос строки внутри значения ломал YAML-парсер и валидацию скилла.
- `SKILL.md` — `description_en`: убрана точка за закрывающей кавычкой (`"...tests".` → `"...tests."`).
- `SKILL.md` — `description_zh`: исправлена опечатка `agmin` → `admin`.

**Известные особенности (неявные, поведение не меняют):**

- Каталог-исходник называется `git-github-gitlab-admin`, а поле `name` в `SKILL.md` — `git-github-gitlab`. При публикации в витрину скиллов каталог следует называть `git-github-gitlab` — валидатор сверяет `name` с именем каталога.
- `glab` (GitLab CLI) — опциональная зависимость: команды раздела GitLab требуют отдельной авторизации `glab auth login`.
