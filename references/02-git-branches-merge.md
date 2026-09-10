# 02 — Ветки и слияние (merge, rebase)

> Полный справочник по работе с ветками, стратегиям слияния и rebase.

---

## Содержание
1. [Основы веток](#основы-веток)
2. [Стратегии merge](#стратегии-merge)
3. [Rebase](#rebase)
4. [Конфликты и их разрешение](#конфликты-и-их-разрешение)
5. [git worktree](#git-worktree)
6. [Шпаргалка по веткам](#шпаргалка-по-веткам)

---

## Основы веток

```bash
# Создать ветку (без переключения)
git branch feature/auth

# Создать и переключиться
git checkout -b feature/auth
# Современный синтаксис
git switch -c feature/auth

# Переключиться на существующую ветку
git checkout main
git switch main

# Переключиться на предыдущую ветку
git switch -

# Список веток
git branch              # локальные
git branch -r           # удалённые
git branch -a           # все
git branch -vv          # с информацией об upstream и опережении

# Переименовать ветку
git branch -m old-name new-name       # текущую
git branch -m new-name                 # текущую, не указывая старое имя
git branch -m old-name new-name       # любую

# Удалить локальную ветку
git branch -d feature/auth     # безопасное (проверяет, слита ли)
git branch -D feature/auth     # принудительное

# Удалить удалённую ветку
git push origin --delete feature/auth
# Или
git push origin :feature/auth

# Отследить удалённую ветку
git branch --track feature/auth origin/feature/auth
# Или
git checkout -b feature/auth origin/feature/auth
# Или (коротко, если имя совпадает)
git checkout feature/auth

# Удалить локальные ссылки на несуществующие удалённые ветки
git fetch --prune
git remote prune origin
```

---

## Стратегии merge

### Fast-forward (по умолчанию, если возможно)

```
До:     A---B---C (main)
                  \
                   D---E (feature)

После:  A---B---C---D---E (main, feature)
```

```bash
# Обычный merge — fast-forward если возможно, иначе создаёт merge commit
git merge feature
```

### --no-ff (всегда создаёт merge commit)

```
До:     A---B---C (main)
                  \
                   D---E (feature)

После:  A---B---C---F (main)
                  \   /
                   D---E (feature)
```

```bash
# Всегда создаёт merge commit — сохраняет историю ветки
git merge --no-ff feature -m "merge: интеграция feature-ветки в main"

# Рекомендуется для feature-веток — видно, что было отдельной разработкой
```

### --ff-only (только fast-forward)

```bash
# Не создаёт merge commit. Если FF невозможен — ошибка
git merge --ff-only feature
# Полезно для защиты от случайных merge-коммитов
```

### --squash (объединяет все коммиты в один)

```bash
# Берёт все коммиты ветки и создаёт один новый коммит
git merge --squash feature
git commit -m "feat: реализована авторизация (из feature/auth)"

# История коммитов feature-ветки не сохраняется
# Полезно когда в feature-ветке много мелких WIP-коммитов
```

### Recursive / Octopus / Ours / Theirs

```bash
# Recursive — стратегия по умолчанию для двух веток
git merge -s recursive feature

# Octopus — для слияния 3+ веток одновременно
git merge branchA branchB branchC

# ours — сохранить версию текущей ветки, проигнорировать конфликты
git merge -s ours feature
# (просто помечает, что feature слита, но не берёт изменения)

# theirs — взять версию сливаемой ветки при конфликте
git merge -X theirs feature

# ours — при конфликте взять версию текущей ветки
git merge -X ours feature
```

### --abort / --continue

```bash
# Отмена незавершённого слияния (ВНИМАНИЕ: теряет изменения merge)
git merge --abort

# Продолжить слияние после разрешения конфликтов
git add .
git merge --continue
# Или (классический способ)
git add .
git commit    # git создаст merge commit автоматически
```

---

## Rebase

Rebase перемещает коммиты текущей ветки поверх указанной ветки. Создаёт линейную историю.

```
До:     A---B---C (main)
              \
               D---E---F (feature)

После:  A---B---C---D'---E'---F' (feature)
```

### Базовый rebase

```bash
# Перебазировать текущую ветку поверх main
git checkout feature
git rebase main

# После rebase — force push (история переписана)
git push --force-with-lease origin feature
```

### Интерактивный rebase (rebase -i)

```bash
# Интерактивный rebase последних 5 коммитов
git rebase -i HEAD~5

# Откроется редактор со списком коммитов:
# pick   abc1234 feat: добавлен логин
# pick   def5678 feat: добавлен регистрация
# pick   ghi9012 WIP: эксперимент
# pick   jkl3456 fix: исправлен баг
# pick   mno7890 docs: обновлён README
```

**Команды интерактивного rebase:**

| Команда | Сокращение | Действие |
|---------|-----------|----------|
| `pick` | `p` | Оставить коммит как есть |
| `reword` | `r` | Оставить коммит, изменить сообщение |
| `edit` | `e` | Остановиться для правки (amend) |
| `squash` | `s` | Объединить с предыдущим коммитом |
| `fixup` | `f` | Объединить с предыдущим, отбросить сообщение |
| `exec` | `x` | Выполнить команду shell |
| `break` | `b` | Остановиться здесь |
| `drop` | `d` | Удалить коммит |
| `label` | `l` | Поставить метку |
| `reset` | `t` | Сбросить HEAD к метке |
| `merge` | `m` | Создать merge commit |

**Пример — squash 5 коммитов в 1:**
```
pick   abc1234 feat: добавлен логин
squash def5678 feat: добавлен регистрация
fixup  ghi9012 WIP: эксперимент
fixup  jkl3456 fix: исправлен баг
reword mno7890 docs: обновлён README
```

### Rebase --onto

```bash
# Перенести коммиты с одной базы на другую
# git rebase --onto <new-base> <old-base> <branch>
git rebase --onto main old-base feature

# Пример: отсечь первые коммиты ветки
git rebase --onto main feature~3 feature
# Берёт 3 последних коммита feature и переносит их на main
```

### Rebase --autostash

```bash
# Автоматический stash перед rebase, pop после
git rebase --autostash main
# Не нужно вручную stash/unstash
```

### Rebase --abort / --continue / --skip

```bash
git rebase --abort     # отменить rebase, вернуться к состоянию до
git rebase --continue  # продолжить после разрешения конфликтов
git rebase --skip      # пропустить текущий коммит (если он пустой после разрешения)
```

---

## Конфликты и их разрешение

При конфликте git добавляет маркеры в файл:

```text
<<<<<<< HEAD
Текущая версия (нааша ветка)
=======
Входящая версия (сливаемая ветка)
>>>>>>> feature-branch
```

### Ручное разрешение

```bash
# 1. Посмотреть конфликтующие файлы
git status

# 2. Открыть файл, удалить маркеры, оставить нужную версию
# 3. Добавить разрешённый файл
git add path/to/file.txt

# 4. Продолжить merge или rebase
git merge --continue
# или
git rebase --continue
```

### Инструменты разрешения

```bash
# Визуальный mergetool
git mergetool
# Настройка mergetool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# Стратегии авторазрешения
git merge -X ours feature      # при конфликте — брать нашу версию
git merge -X theirs feature    # при конфликте — брать их версию

# Просмотреть конфликт в терминале
git diff --name-only --diff-filter=U    # только конфликтующие файлы
git diff --ours                          # наша версия
git diff --theirs                        # их версия
git diff --base                          # базовая версия
```

###checkout конкретных версий

```bash
# Взять нашу версию файла целиком
git checkout --ours path/to/file.txt
# Взять их версию
git checkout --theirs path/to/file.txt
# Затем добавить
git add path/to/file.txt
```

---

## git worktree

Позволяет иметь несколько рабочих деревьев одного репо — без stash, clone или переключения веток.

```bash
# Создать новое рабочее дерево с новой веткой
git worktree add ../project-feature feature/new-api

# Создать рабочее дерево с существующей веткой
git worktree add ../project-hotfix hotfix-branch

# Создать рабочее дерево с отсоединённым HEAD (для экспериментов)
git worktree add --detach ../project-experiment abc1234

# Список рабочих деревьев
git worktree list

# Удалить рабочее дерево
git worktree remove ../project-feature

# Очистка записей об удалённых директориях
git worktree prune

# Перенос рабочего дерева
git worktree move ../project-feature ../new-location/project-feature
```

**Сценарий:** работаете над feature, нужно срочно исправить баг в main — вместо stash создаёте worktree:

```bash
git worktree add ../project-hotfix main
cd ../project-hotfix
# ... чините баг, коммитите, пушите ...
git worktree remove ../project-hotfix
```

---

## Шпаргалка по веткам

| Задача | Команда |
|--------|---------|
| Создать ветку | `git switch -c feature` |
| Переключиться | `git switch main` |
| Удалить локальную | `git branch -d feature` |
| Удалить удалённую | `git push origin --delete feature` |
| Слить без merge commit | `git merge --ff-only feature` |
| Слить с merge commit | `git merge --no-ff feature` |
| Склеить коммиты ветки | `git merge --squash feature` |
| Перебазировать | `git rebase main` |
| Отменить merge | `git merge --abort` |
| Отменить rebase | `git rebase --abort` |
| Создать worktree | `git worktree add ../dir branch` |
| Force push безопасно | `git push --force-with-lease` |
