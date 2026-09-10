# 05 — Конфигурация, хуки, подмодули

> Полный справочник по трёхуровневой конфигурации, Git Hooks и подмодулям.

---

## Содержание
1. [Трёхуровневая конфигурация](#трёхуровневая-конфигурация)
2. [Алиасы](#алиасы)
3. [Автозамена URL](#автозамена-url)
4. [Git Hooks](#git-hooks)
5. [git submodule](#git-submodule)

---

## Трёхуровневая конфигурация

| Уровень | Флаг | Файл | Область | Приоритет |
|---------|------|------|---------|-----------|
| System | `--system` | `/etc/gitconfig` | Все пользователи ОС | 1 (низший) |
| Global | `--global` | `~/.gitconfig` | Текущий пользователь | 2 |
| Local | `--local` (по умолчанию) | `.git/config` | Текущий репо | 3 (высший) |

```bash
# Чтение
git config --list --show-origin
git config user.name           # из всех уровней (победит высший)
git config --get user.email     # то же самое

# Запись
git config --global user.name "Иван"
git config --local user.name "Ivan (work)"   # только для этого репо

# Удаление
git config --global --unset alias.st
git config --local --unset-all user.name

# Редактирование файла конфига напрямую
git config --global --edit
git config --local --edit
```

### Ключевые настройки

```bash
# Идентификация
git config --global user.name "Иван Иванов"
git config --global user.email "ivan@example.com"

# Поведение
git config --global init.defaultBranch main
git config --global pull.rebase true          # rebase при pull
git config --global push.default current       # push текущей ветки
git config --global push.autoSetupRemote true  # автоматически устанавливать upstream
git config --global core.autocrlf input        # LF в репо, CRLF на Windows checkout
git config --global core.editor "code --wait"
git config --global color.ui auto

# Безопасность
git config --global fetch.fsckobjects true     # проверка целостности при fetch
git config --global transfer.fsckobjects true  # проверка при clone/fetch

# Производительность
git config --global feature.manyFiles true     # оптимизация для больших репо
git config --global index.version 2

# Дифф/merge инструменты
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```

---

## Алиасы

```bash
# Командные алиасы
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.sw switch
git config --global alias.unstage 'restore --staged'
git config --global alias.last 'log -1 HEAD'
git config --global alias.uncommit 'reset --soft HEAD~1'

# Визуальные алиасы
git config --global alias.lg "log --graph --oneline --decorate --all"
git config --global alias.ls "log --name-status"
git config --global alias.visual '!gitk'    # ! — запустить внешнюю команду

# Полезные составные алиасы
git config --global alias.amend 'commit --amend --no-edit'
git config --global alias.aliases 'config --get-regexp ^alias\.'
git config --global alias.cleanup 'remote prune origin && fetch --prune'
git config --global alias.wip 'commit -am "WIP" --no-verify'
git config --global alias.pop 'stash pop'
git config --global alias.save 'stash push -u -m'

# Алиас с shell-скриптом
git config --global alias.newbranch '!git switch -c $(date +%Y%m%d)-$1'
# Использование: git newbranch feature
```

---

## Автозамена URL

```bash
# HTTPS → SSH для GitHub
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Push по другому протоколу
git config --global url."git@github.com:".pushInsteadOf "https://github.com/"

# Для корпоративного GitHub Enterprise
git config --global url."git@git.company.com:".insteadOf "https://git.company.com/"

# Замена для нескольких хостов
git config --global url."git@github.com:org/".insteadOf "https://github.com/org/"
```

---

## Git Hooks

Хуки — скрипты, которые выполняются автоматически при определённых событиях git. Находятся в `.git/hooks/`.

### Клиентские хуки

| Хук | Когда срабатывает | Типичное применение |
|-----|-------------------|---------------------|
| `pre-commit` | Перед созданием коммита | Линтинг, форматирование, проверка секретов |
| `pre-push` | Перед push на remote | Запуск тестов, проверка ветки |
| `commit-msg` | После ввода сообщения коммита | Проверка формата (Conventional Commits) |
| `prepare-commit-msg` | Перед редактором коммита | Шаблон сообщения, генерация |
| `post-commit` | После создания коммита | Уведомления, логирование |
| `pre-rebase` | Перед rebase | Защита от rebase определённых веток |
| `post-merge` | После merge (pull) | Обновление подмодулей, зависимостей |
| `post-checkout` | После checkout | Настройка окружения |
| `applypatch-msg` | При git am | Проверка патч-сообщения |
| `pre-applypatch` | При git am | Линтинг перед применением патча |

### Серверные хуки

| Хук | Когда срабатывает | Типичное применение |
|-----|-------------------|---------------------|
| `pre-receive` | Перед приёмом push | Проверка прав, branch protection |
| `update` | Для каждого обновляемого ref | Дополнительные проверки |
| `post-receive` | После приёма push | Уведомления, деплой |

### Пример: pre-commit (линтинг)

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "==> Проверка кода перед коммитом..."

# Проверить staged файлы
STAGED=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|py)$')

if [ -z "$STAGED" ]; then
  exit 0
fi

# Запустить линтер
echo "$STAGED" | xargs eslint --fix
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "❌ Линтинг не прошёл. Исправьте ошибки или сделайте commit с --no-verify."
  exit 1
fi

# Проверка на секреты
if git diff --cached | grep -qiE "(password|secret|token)\s*=\s*['\"]"; then
  echo "❌ Обнаружен возможный секрет в коде!"
  exit 1
fi

echo "✅ Проверки пройдены"
exit 0
```

### Пример: commit-msg (Conventional Commits)

```bash
#!/bin/bash
# .git/hooks/commit-msg

MSG=$(cat "$1")
PATTERN='^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)(\(.+\))?: .{1,100}'

if ! echo "$MSG" | grep -qE "$PATTERN"; then
  echo "❌ Сообщение коммита не соответствует Conventional Commits!"
  echo "   Формат: type(scope): description"
  echo "   Пример: feat(auth): добавлена регистрация"
  exit 1
fi
```

### Пример: pre-push (тесты)

```bash
#!/bin/bash
# .git/hooks/pre-push

echo "==> Запуск тестов перед push..."
npm test
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "❌ Тесты не прошли. Push отменён."
  exit 1
fi

echo "✅ Тесты прошли, push разрешён"
exit 0
```

### Пример: post-merge (обновление зависимостей)

```bash
#!/bin/bash
# .git/hooks/post-merge

echo "==> Обновление зависимостей после merge/pull..."
if [ -f package-lock.json ]; then
  npm ci
fi
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi
```

### Управление хуками

```bash
# Установка хуков (git использует .git/hooks/ по умолчанию)
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Использовать хуки из произвольной директории
git config --local core.hooksPath hooks/

# Пропустить хуки для одного коммита (ОСТОРОЖНО)
git commit --no-verify -m "WIP"

# Проверить, какие хуки есть
ls -la .git/hooks/
```

### Husky — управление хуками в проекте

```bash
# Установка husky (Node.js проект)
npm install --save-dev husky
npx husky init

# Добавить pre-commit хук
npx husky add .husky/pre-commit "npm run lint"

# Добавить commit-msg хук
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

---

## git submodule

Подмодули — встраивание одного git-репозитория внутрь другого. Полезно для общих библиотек, vendor-кода.

### Добавление

```bash
# Добавить подмодуль
git submodule add https://github.com/user/shared-lib.git libs/shared-lib

# Это создаст .gitmodules и закоммитит
git commit -m "chore: добавлен shared-lib как подмодуль"
```

### Клонирование с подмодулями

```bash
# Рекурсивно (все подмодули инициализируются)
git clone --recurse-submodules https://github.com/user/main-repo.git

# Если уже склонировали без --recurse-submodules:
git submodule update --init --recursive
```

### Обновление подмодулей

```bash
# Обновить все подмодули до коммита, на который они указывают
git submodule update --init --recursive

# Обновить подмодули до последних коммитов их remote
git submodule update --remote
git submodule update --remote --merge    # смержить изменения
git submodule update --remote --rebase    # перебазировать

# Обновить конкретный подмодуль
git submodule update --remote libs/shared-lib
```

### Выполнение команды во всех подмодулях

```bash
# forall — выполнить команду в каждом подмодуле
git submodule foreach 'git status'
git submodule foreach 'git pull origin main'
git submodule foreach --recursive 'git checkout main'
```

### Удаление подмодуля

```bash
# 1. Деинициализация
git submodule deinit -f libs/shared-lib

# 2. Удаление из .git/modules
rm -rf .git/modules/libs/shared-lib

# 3. Удаление записи из .gitmodules и индекса
git rm -f libs/shared-lib

# 4. Коммит
git commit -m "chore: удалён подмодуль shared-lib"
```

### Переключение ветки подмодуля

```bash
cd libs/shared-lib
git checkout main
cd ../..
git add libs/shared-lib
git commit -m "chore: подмодуль shared-lib переключён на main"
```

### Просмотр статуса

```bash
git submodule status
git submodule summary
```
