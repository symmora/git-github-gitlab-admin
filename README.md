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
├── assets/
│   └── how-to-authorize.md         # Authentication flow, credentials и tokens
├── scripts/
│   └── git-router.sh              # Маршрутизатор команд
├── tests/
│   └── test-router.sh             # Тесты маршрутизатора
└── quality/                       # Постоянная квалификация качества скилла
    ├── qualification.md            # Qualification pipeline и правила оценки
    ├── defect-registry.md          # Реестр дефектов и их жизненный цикл
    ├── regression-tests.md         # Политика regression coverage
    └── score-history.md            # История квалификационных оценок
```

---

## Authentication briefing

Подробная схема operational authentication этого skill — от выбора GitHub/GitLab и транспорта HTTPS/SSH до создания, передачи, проверки, обновления и хранения credentials — вынесена в [`assets/how-to-authorize.md`](assets/how-to-authorize.md). Документ основан на реальном поведении `scripts/git-router.sh`, сопоставлен с reference-документацией и отдельно фиксирует риски и неопределённости.

---

## Quality & Qualification

Каталог `quality/` нужен для того, чтобы качество скилла подтверждалось не только разовой экспертной оценкой, но и его реальным использованием. Скилл должен постоянно проверяться в рабочих сценариях, а найденные проблемы должны становиться входом в следующий цикл улучшения.

- `quality/qualification.md` описывает единый qualification pipeline: structural и dependency validation, scenario/failure-path/safety/portability tests, regression и повторный scoring.
- `quality/defect-registry.md` задаёт правила регистрации найденных косяков: контекст обнаружения, expected/actual behavior, severity, reproduction, исправление и связь с regression test.
- `quality/regression-tests.md` описывает принцип: воспроизводимый исправленный дефект по возможности превращается в regression test, чтобы он не появился снова.
- `quality/score-history.md` хранит историю оценок. Score отражает подтверждённое состояние скилла на момент квалификации и может как расти, так и снижаться после обнаружения новых дефектов.

Оперативный defect tracking ведётся через GitHub Issues. Файлы в `quality/` задают стандарт процесса и сохраняют историю квалификации рядом с кодом скилла.

Таким образом, высокий score (например, `9.8/10`) — не пожизненная отметка. Он должен подтверждаться эксплуатацией: `use → discover → register → fix → regression test → re-qualify → score`.

---

## Требования

- `git` >= 2.40
- `gh` (GitHub CLI)
- `glab` (GitLab CLI)

---

## Обновления

### 2026-09-14

**Исправлено (рассинхрон структуры документации):**

- `SKILL.md` — блок «Структура скилла» приведён к фактическому состоянию: добавлены
  `README.md` и каталог `quality/` (4 файла), отсутствовавшие в дереве.
- `SKILL.md` — добавлен раздел «Quality & Qualification» со ссылками на
  `quality/qualification.md`, `quality/defect-registry.md`, `quality/regression-tests.md`,
  `quality/score-history.md`: ранее агент не знал о правилах квалификации и реестре дефектов.
- `README.md` — в блок «Структура» добавлен каталог `assets/` (`how-to-authorize.md`),
  отсутствовавший в дереве (хотя упоминался отдельной секцией).
- Сверены все текстовые ссылки: файлы `references/01…13`, `scripts/git-router.sh`,
  `tests/test-router.sh`, `assets/how-to-authorize.md`, `quality/*` существуют на диске.

### 2026-09-13

- Добавлен раздел `quality/` для постоянной квалификации скилла.
- Введён defect registry для проблем, обнаруженных при тестировании и реальном использовании.
- Добавлена история score: оценка теперь рассматривается как подтверждаемое состояние качества, а не постоянная отметка.
- README описывает цикл `use → discover → register → fix → regression test → re-qualify → score`.

### 2026-09-10

**Исправлено (явные дефекты):**

- `SKILL.md` — frontmatter: многострочный `description` свёрнут в одну строку. Ранее перенос строки внутри значения ломал YAML-парсер и валидацию скилла.
- `SKILL.md` — `description_en`: убрана точка за закрывающей кавычкой (`"...tests".` → `"...tests."`).
- `SKILL.md` — `description_zh`: исправлена опечатка `agmin` → `admin`.

**Известные особенности (неявные, поведение не меняют):**

- Каталог-исходник называется `git-github-gitlab-admin`, а поле `name` в `SKILL.md` — `git-github-gitlab`. При публикации в витрину скиллов каталог следует называть `git-github-gitlab` — валидатор сверяет `name` с именем каталога.
- `glab` (GitLab CLI) — опциональная зависимость: команды раздела GitLab требуют отдельной авторизации `glab auth login`.

### SkillSpector (NVIDIA) — 2026-09-10

Статический скан (`--no-llm`): 65 находок, score **100/100 CRITICAL**, вердикт «DO NOT INSTALL».

По существу это ложные срабатывания: скилл — справочник по git/GitHub/GitLab, где упоминания
`--force`, credential-путей, `rm -rf`, токенов и сетевых URL являются документацией, а не
инструкциями агенту. Реальных вредоносных паттернов (эксфильтрация, reverse shell, `curl | bash`)
не обнаружено.

Замечания по безопасности (не критические, учтены):

- Деструктивные команды (`git push --force-with-lease`, `git reset --hard`, `rm -rf`) в
  `git-router.sh` уже защищены `confirm()`.
- `AUTO_CONFIRM=yes` отключает подтверждения — включать только осознанно (CI / неинтерактивный режим).
- `allowed-tools` во frontmatter не декларирует сетевую capability, хотя скилл использует
  `git push` / `gh` / `glab` (сеть). Декларация прав неполна.
- Кириллица даёт 18 ложных находок «analysis-evasion» (mixed-script) — артефакт языка, не риск.
