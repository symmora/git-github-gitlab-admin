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
├── .github/workflows/quality.yml # Автоматический прогон проверок
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
│   ├── test-router.sh             # Тесты маршрутизатора
│   └── test-install.sh            # Четыре сценария установки
└── quality/                       # Постоянная квалификация качества скилла
    ├── qualification.md            # Qualification pipeline и правила оценки
    ├── defect-registry.md          # Реестр дефектов и их жизненный цикл
    ├── regression-tests.md         # Политика regression coverage
    ├── score-history.md            # История квалификационных оценок
    └── skill-score.md              # Текущая проверка и открытые пункты
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
- `quality/skill-score.md` фиксирует проверенные сценарии, ограничения и условия следующей полной оценки.

Оперативный defect tracking ведётся через GitHub Issues. Файлы в `quality/` задают стандарт процесса и сохраняют историю квалификации рядом с кодом скилла.

Таким образом, высокий score (например, `9.8/10`) — не пожизненная отметка. Он должен подтверждаться эксплуатацией: `use → discover → register → fix → regression test → re-qualify → score`.

---

## Требования

- `git` >= 2.40
- `gh` для операций GitHub и `glab` для операций GitLab; авторизация для каждой платформы отдельно.
- Node.js и npm только для необязательной установки через `skills` CLI (команда `npx skills`).

## Установка инструментов и скилла

Для Ubuntu 24.04 / WSL2:

```bash
sudo apt update
sudo apt install git gh
sudo snap install glab
git --version
gh --version
glab --version
```

Если `snap` недоступен в WSL, установите `glab` по [официальным вариантам GitLab CLI](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation_options.md). Если пакетная версия `git` ниже 2.40, обновите её по [инструкции Git](https://git-scm.com/install/linux). Для GitHub и GitLab выполните соответственно `gh auth login` и `glab auth login` и проверьте `gh auth status`, `glab auth status`. Не помещайте токены в URL или shell history.

Для `skills` CLI установите [актуальный Node.js с npm](https://nodejs.org/en/download), затем проверьте `node --version` и `npm --version`. CLI можно вызвать без глобальной установки: `npx --yes skills --help`. Его пакет называется `skills`, а исполняемая команда — `skills`; здесь «skills-cli» обозначает этот способ установки. [Синтаксис и варианты источников](https://github.com/vercel-labs/skills#install-a-skill).

С `skills` CLI для этого самостоятельного git-репозитория:

```bash
npx skills add symmora/git-github-gitlab-admin --skill git-github-gitlab --agent codex --copy --yes
```

Для репозитория-каталога `skills/<имя>/SKILL.md` укажите его `<owner>/<skills-repo>` вместо `symmora/git-github-gitlab-admin`. Для приватного репозитория заранее настройте доступ через `git`/`gh`/SSH. После установки проверьте `.agents/skills/git-github-gitlab/SKILL.md` и `.agents/skills/git-github-gitlab/scripts/git-router.sh`; отсутствие второго файла означает неполную установку.

Без CLI клонируйте нужный репозиторий и скопируйте **весь каталог скилла** в `.agents/skills/git-github-gitlab/`: для каталога это `skills/git-github-gitlab/`, для данного самостоятельного репозитория — его корень. Например:

```bash
git clone git@github.com:symmora/git-github-gitlab-admin.git
mkdir -p .agents/skills/git-github-gitlab
cp -R git-github-gitlab-admin/. .agents/skills/git-github-gitlab/
bash .agents/skills/git-github-gitlab/scripts/git-router.sh help
```

В примере запускайте команды из проекта, в который устанавливаете скилл; клонированный каталог должен лежать отдельно от `.agents/skills/`. Для размещения внутри `skills`-репо используйте `cp -R <skills-repo>/skills/git-github-gitlab/. .agents/skills/git-github-gitlab/`.

Проверка: `bash tests/test-router.sh` и `bash tests/test-install.sh`. Для двух реальных CLI-сценариев задайте `SKILLS_CLI=/absolute/path/to/skills bash tests/test-install.sh`; без него скрипт сообщает о двух пропусках. CI устанавливает CLI и запускает все четыре сценария.

Если доступен отдельный `skill-creator`, путь к валидатору: `/path/to/skills/skill-creator/scripts/quick_validate.py`. Запускайте `python3 /path/to/skills/skill-creator/scripts/quick_validate.py .` из корня скилла; замените префикс на фактический путь. `skill-creator` не входит в этот репозиторий и не требуется для запуска маршрутизатора. При его отсутствии проверяйте frontmatter, ссылки и сценарии установки; не считайте это эквивалентом `quick_validate.py`.

---

## Обновления

### 2026-09-26

- Добавлены установка инструментов и скилла, путь `quick_validate.py` и две схемы размещения.
- Исправлены три ложных падения тестов маршрутизатора; добавлены четыре сценария установки и CI.
- Убраны примеры передачи токенов в URL и хранение через `credential.helper store` из SKILL.md.
- Текущий статус квалификации записан в `quality/skill-score.md`.

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
