# 04 — Расследование: log, diff, blame, bisect, reflog

> Полный справочник по инструментам исследования истории и состояния репозитория.

---

## Содержание
1. [git log — история коммитов](#git-log)
2. [git diff — различия](#git-diff)
3. [git blame — кто и когда](#git-blame)
4. [git bisect — бинарный поиск бага](#git-bisect)
5. [git reflog — журнал перемещений HEAD](#git-reflog)

---

## git log

### Базовые форматы

```bash
# Обычный лог
git log

# Компактный (онлайн)
git log --oneline

# Граф веток
git log --oneline --graph --all --decorate

# Краткий с датами
git log --oneline --format="%h %ad %s" --date=short

# Последние N коммитов
git log -5
git log --oneline -10

# Только коммиты конкретного автора
git log --author="Ivan"
```

### Фильтрация

```bash
# По дате
git log --since="2025-01-01"
git log --until="2025-06-30"
git log --since="2 weeks ago"
git log --since="yesterday"
git log --after="2025-03-15" --before="2025-04-01"

# По сообщению коммита
git log --grep="fix:"
git log --grep="auth" --regexp-ignore-case

# По файлу
git log -- path/to/file.txt
git log --follow -- path/to/file.txt   # отслеживать переименования

# По диапазону строк (кто менял строки 10-20)
git log -L 10,20:path/to/file.txt
git log -L :functionName:path/to/file.ts   # по имени функции

# По содержимому изменения (S_search)
git log -S "functionName"     # коммиты, где добавилось/убавилось это слово
git log -G "function.*Name"   # regex-поиск в diff

# По веткам
git log main..feature         # коммиты в feature, которых нет в main
git log feature..main         # коммиты в main, которых нет в feature
git log --all --graph         # все ветки
```

### Форматирование вывода

```bash
# Полный патч (diff)
git log -p
git log -p -2                  # последние 2 с diff

# Статистика изменений
git log --stat
git log --shortstat

# Кастомный формат
git log --format="%h %an %ad %s" --date=format:"%Y-%m-%d %H:%M"
git log --format="%C(green)%h%C(reset) %C(yellow)%an%C(reset) %s"

# Вывод в файл
git log --oneline > changelog.txt

# JSON-подобный вывод
git log --pretty=format:'{"hash":"%H","author":"%an","date":"%aI","message":"%s"}'
```

### Полезные алиасы

```bash
git config --global alias.lg "log --graph --oneline --decorate --all"
git config --global alias.ll "log --format=%h' '%an' '%ad' '%s --date=short"
```

---

## git diff

### Основные применения

```bash
# Рабочая директория vs индекс (unstaged)
git diff

# Индекс vs HEAD (staged)
git diff --cached
git diff --staged    # синоним

# Рабочая директория vs HEAD (все изменения)
git diff HEAD

# Конкретный файл
git diff path/to/file.txt

# Между коммитами/ветками
git diff abc1234 def5678
git diff main feature
git diff origin/main..HEAD

# Между тегами
git diff v1.0.0 v1.1.0
```

### Форматы вывода

```bash
# Стандартный (unified)
git diff

# Имена изменённых файлов
git diff --name-only
git diff --cached --name-only

# Имена + статус (A/M/D/R)
git diff --name-status
# M  modified.txt
# A  new-file.txt
# D  deleted-file.txt
# R  old.txt -> new.txt

# Статистика
git diff --stat
git diff --shortstat

# Word-diff (лучше для текста, не кода)
git diff --word-diff
git diff --word-diff-regex=.

# Только изменения без контекста
git diff --unified=0
```

### Сравнение с разными базами

```bash
# Слияние base (для merge conflict)
git diff --base
git diff --ours
git diff --theirs

# Дерево конкретного коммита
git diff abc1234 -- path/to/file.txt

# Сравнение веток без слияния
git diff main...feature    # от точки разветвления до feature tip
```

### Поиск в diff

```bash
# Только файлы, где есть изменения с словом "password"
git diff -G "password" --name-only

# Изменения, добавившие/удалившие строку
git diff -S "TODO" -- '*.py'
```

---

## git blame

Показывает, какой коммит и автор последним изменил каждую строку файла.

```bash
# Базовый
git blame path/to/file.txt

# С小时ами создания коммитов
git blame --date=short path/to/file.txt

# Конкретные строки
git blame -L 10,30 path/to/file.txt

# Игнорировать пробельные изменения
git blame -w path/to/file.txt

# Показать email автора
git blame -e path/to/file.txt

# С_rev (показать ревизию)
git blame --show-stats path/to/file.txt

# Слегка перемещённые строки (без копирования/перемещения)
git blame -M path/to/file.txt    # обнаружение перемещений внутри файла
git blame -C path/to/file.txt    # обнаружение копирования из других файлов
git blame -C -C path/to/file.txt # более агрессивный поиск
```

### Исследование истории строки

```bash
# Найти коммит, изменивший строку 42
git blame -L 42,42 path/to/file.txt

# Посмотреть что изменилось в этом коммите
git show <hash>

# Посмотреть предыдущую версию строки (до этого коммита)
git blame <hash>^ -L 42,42 path/to/file.txt

# Цикл: blame → show → blame предка → ...
# Полу-автоматический поиск причины бага в конкретной строке
```

---

## git bisect

Бинарный поиск коммита, который внёс баг. Сужает диапазон логарифмически.

### Ручной режим

```bash
# Начать bisect
git bisect start

# Указать плохой коммит (где баг есть)
git bisect bad                    # по умолчанию = HEAD
git bisect bad v1.0.0             # конкретный

# Указать хороший коммит (где бага нет)
git bisect good v0.9.0
git bisect good abc1234

# Git автоматически чекаутит средний коммит
# Проверяете, есть ли баг:
git bisect good    # бага нет
git bisect bad     # баг есть

# Повторяете, пока git не скажет "X is the first bad commit"

# Завершить
git bisect reset
```

### Автоматический режим

```bash
# Указать скрипт/команду для проверки (возврат 0=good, 1=bad, 125=skip)
git bisect start
git bisect bad HEAD
git bisect good v0.9.0
git bisect run npm test           # автоматически сужает
git bisect run ./scripts/check-bug.sh
git bisect reset
```

### Пример: найти коммит, сломавший тест

```bash
git bisect start
git bisect bad HEAD               # текущее состояние — сломано
git bisect good v1.0.0            # v1.0.0 работал

# Проверяем — тест падает?
pytest tests/test_auth.py
git bisect bad   # если упал
# или
git bisect good  # если прошёл

# Автоматически:
git bisect run pytest tests/test_auth.py
git bisect reset
```

### Пропуск коммитов

```bash
# Если коммит не собирается/не запускается
git bisect skip
```

### Визуализация

```bash
git bisect visualize
git bisect view --oneline    # синоним
```

---

## git reflog

Журнал всех перемещений HEAD. Спасает, когда случайно сделали `reset --hard`, `rebase`, удалили ветку.

```bash
# Полный reflog
git reflog
git reflog --all

# Последние 10
git reflog -10

# С датами
git reflog --date=iso

# По конкретной ветке
git reflog refs/heads/main
```

### Восстановление "потерянных" коммитов

```bash
# 1. Найти потерянный коммит в reflog
git reflog
# abc1234 HEAD@{0}: reset: moving to HEAD~3
# def5678 HEAD@{1}: commit: feat: важный фикс
# ghi9012 HEAD@{2}: commit: feat: ещё один фикс

# 2. Восстановить — создать ветку от потерянного коммита
git branch recovered-feature def5678
# Или вернуться к нему
git reset --hard def5678
# Или cherry-pick
git cherry-pick def5678

# 3. Если прошло время и reflog уже очищен
git fsck --lost-found    # найти "висящие" коммиты
```

### Восстановление после ошибочного reset

```bash
# Случайно сделали git reset --hard HEAD~3
git reflog
# Находим запись до reset
git reset --hard HEAD@{1}
```

### Восстановление удалённой ветки

```bash
git branch -D feature
# Ой, нужна!
git reflog
git branch feature HEAD@{1}
```

### Очистка reflog

```bash
# Удалить записи старше 90 дней (по умолчанию)
git reflog expire --expire=90.days --all

# Удалить все недостижимые записи
git reflog expire --expire-unreachable=now --all

# Принудительная сборка мусора
git gc --prune=now
```
