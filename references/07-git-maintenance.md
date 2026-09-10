# 07 — Обслуживание и оптимизация: gc, fsck, repack, sparse-checkout, notes, replace

> Полный справочник по обслуживанию репозитория, оптимизации и специализированным командам.

---

## Содержание
1. [git gc — сборка мусора](#git-gc)
2. [git fsck — проверка целостности](#git-fsck)
3. [git repack — переупаковка](#git-repack)
4. [git sparse-checkout — частичное клонирование](#git-sparse-checkout)
5. [git notes — метаданные коммитов](#git-notes)
6. [git bundle — см. 06](#)
7. [git replace — подмена объектов](#git-replace)

---

## git gc

Сборка мусора: удаляет недостижимые объекты, сжимает (packs) оставшиеся.

```bash
# Базовая сборка мусора
git gc

# Агрессивная (более тщательная, но медленнее)
git gc --aggressive
git gc -a

# Немедленная очистка (без ожидания)
git gc --prune=now

# Только сжатие, без удаления
git gc --auto

# Очистка с указанным сроком
git gc --prune=2.weeks.ago
```

Git автоматически запускает `gc --auto` при определённых операциях (commit, fetch, merge), когда количество loose-объектов превышает порог.

### Настройка автоматического gc

```bash
# Частота авто-gc (по умолчанию 6700 = ~раз в день)
git config --global gc.auto 6700

# Порог для loose-объектов (по умолчанию 7000)
git config --global gc.auto 7000

# Отключить авто-gc
git config --global gc.auto 0
```

---

## git fsck

Проверка целостности: находит повреждённые объекты, "висящие" (dangling) коммиты и blobs.

```bash
# Базовая проверка
git fsck

# Показать висящие объекты (потерянные коммиты и blobs)
git fsck --lost-found

# Проверка без вывода висящих
git fsck --no-dangling

# Подробный вывод
git fsck -v

# Проверка целостности connectivity (быстрая)
git fsck --connectivity-only

# Строгая проверка (медленнее, но тщательнее)
git fsck --strict

# Полная проверка reflog (обычно отключена для скорости)
git fsck --unreachable
```

### Восстановление потерянных коммитов

```bash
# Найти недостижимые коммиты
git fsck --lost-found
# dangling commit abc1234...
# dangling commit def5678...

# Посмотреть, что в них
git show abc1234
git log abc1234

# Восстановить — создать ветку
git branch recovered abc1234
```

---

## git repack

Переупаковка объектов. Обычно `git gc` вызывает `git repack` автоматически, но можно вручную.

```bash
# Переупаковка всех объектов
git repack

# С удалением избыточных объектов
git repack -d

# Оптимизация для больших репозиториев
git repack -a -d --depth=250 --window=250

# Удаление loose-объектов после переупаковки
git repack -ad

# Прогресс-бар
git repack --progress
```

### Настройка сжатия

```bash
# Уровень сжатия (1-9, по умолчанию 2)
git config --global core.compression 0    # без сжатия (быстро)
git config --global core.compression 9    # максимальное сжатие

# Параметры дельта-сжатия
git config --global pack.depth 50
git config --global pack.window 50
git config --global pack.windowMemory 256m
```

---

## git sparse-checkout

Позволяет клонировать репо, но выгружать только нужные директории. Для монорепозиториев.

```bash
# Клонирование без blob-данных (только структура)
git clone --filter=blob:none --sparse https://github.com/user/big-repo.git

# Включить sparse-checkout
git sparse-checkout init

# Указать, какие директории нужны
git sparse-checkout set src/auth src/api docs

# Добавить директорию
git sparse-checkout add src/models

# Посмотреть текущую конфигурацию
git sparse-checkout list

# Отключить sparse-checkout (выгрузить всё)
git sparse-checkout disable

# Режим cone (по умолчанию с Git 2.27)
git sparse-checkout set --cone src/auth src/api

# Режим без cone (полные паттерны)
git sparse-checkout set --no-cone "src/*/tests" "docs/**"
```

### Пример: работа с монорепо

```bash
# Клонировать только нужное
git clone --filter=blob:none --sparse https://github.com/user/monorepo.git
cd monorepo

# Нужны только два пакета
git sparse-checkout set packages/auth packages/api

# Теперь рабочая директория содержит только:
# .git/
# packages/auth/
# packages/api/
# остальное не выгружено, но доступно через git

# Добавить ещё пакет
git sparse-checkout add packages/shared
```

---

## git notes

Привязка метаданных (текста) к коммиту без изменения самого коммита. Не переписывает историю.

```bash
# Добавить заметку к коммиту
git notes add -m "Code review: одобрено, но нужно добавить тесты" abc1234

# Добавить заметку с файлом
git notes add -F review.txt abc1234

# Посмотреть заметку
git notes show abc1234

# Посмотреть все заметки
git notes list

# Показать заметки в git log
git log --show-notes

# Заметки с конкретным ref
git log --notes=review
git notes --ref=review add -m "Review: OK" abc1234

# Редактировать заметку
git notes edit abc1234

# Удалить заметку
git notes remove abc1234

# Push заметок на remote
git push origin refs/notes/commits

# Fetch заметок
git fetch origin refs/notes/*:refs/notes/*
```

### Использование

- Code review-комментарии без необходимости коммита
- CI/CD результат сборки для коммита
- Дополнительные метаданные (JIRA ticket, reviewer, deploy status)
- Альтернатива amend, когда нельзя переписывать историю

---

## git replace

Подмена объекта в истории без переписывания. Git подменяет объект при чтении, но оригинал остаётся.

```bash
# Заменить коммит B на B' в истории
git replace <original-commit> <replacement-commit>

# Заменить файл-дерево
git replace --edit <commit>
git replace --graft <commit> <parent1> [<parent2>...]

# Удалить замену
git replace -d <original-commit>

# Список замен
git replace -l

# Push замен на remote (нужно явно)
git push origin refs/replace/<hash>

# Fetch замен
git fetch origin 'refs/replace/*:refs/replace/*'
```

### Сценарий: "graft" — скрыть parent

```bash
# Склеить две ветки, изменив parent
git replace --graft <commit> <new-parent>

# Пример: сделать так, чтобы feature выглядела как идущая от main, а не от develop
git replace --graft abc1234 main-commit-hash
```

### Сценарий: исправить старый коммит (без переписывания истории)

```bash
# Создать исправленную версию коммита
git checkout abc1234^
# ... внести исправления ...
git commit --amend    # новый хеш: def5678
# Заменить
git replace abc1234 def5678
# Теперь git показывает исправленную версию, но оригинал остаётся
```
