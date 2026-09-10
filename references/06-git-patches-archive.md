# 06 — Патчи и архивы: format-patch, apply, am, archive, bundle

> Полный справочник по работе с патч-файлами, архивами и offline-переносу.

---

## Содержание
1. [git format-patch — создание патчей](#git-format-patch)
2. [git apply — применение патчей](#git-apply)
3. [git am — применение патчей как коммитов](#git-am)
4. [git archive — экспорт дерева](#git-archive)
5. [git bundle — офлайн-передача репо](#git-bundle)

---

## git format-patch

Создаёт патч-файлы (в формате email) для коммитов. Используется для отправки изменений по email или без push.

```bash
# Патч для последнего коммита
git format-patch -1 HEAD
# Файл: 0001-commit-subject.patch

# Патчи для последних 3 коммитов
git format-patch -3

# Патчи для всех коммитов ветки feature, которых нет в main
git format-patch main..feature
# Каждый коммит → отдельный .patch файл

# Патч для конкретного коммита
git format-patch -1 abc1234

# Патч для диапазона
git format-patch abc1234..def5678

# Вывод в stdout (объединённый)
git format-patch -1 --stdout

# В указанную директорию
git format-patch -3 -o /tmp/patches/

# С sign-off (для email-workflow)
git format-patch -3 --signoff
git format-patch -3 -s
```

### Формат патч-файла

```
From abc1234... Mon Sep 15 10:00:00 2025
From: Автор <author@example.com>
Date: Mon, 15 Sep 2025 10:00:00 +0300
Subject: [PATCH] feat: добавлена авторизация

Описание коммита...

Signed-off-by: Автор <author@example.com>
---
 file.txt | 10 +++++++++
 1 file changed, 10 insertions(+)

diff --git a/file.txt b/file.txt
...
```

---

## git apply

Применяет изменения из патч-файла к рабочей директории (без создания коммита).

```bash
# Применить патч
git apply 0001-feat-auth.patch

# Проверить, можно ли применить (dry-run)
git apply --check 0001-feat-auth.patch

# Применить и добавить в индекс
git apply --index 0001-feat-auth.patch

# Применить с указанием директории
git apply --directory=src/ 0001-feat.patch

# Игнорировать пробельные различия
git apply --whitespace=fix 0001-feat.patch

# Обратное применение (отменить патч)
git apply -R 0001-feat.patch

# Статистика
git apply --stat 0001-feat.patch
```

### Использование с diff

```bash
# Создать diff и применить его
git diff > my-changes.patch
git apply my-changes.patch

# diff конкретного файла
git diff -- path/to/file.txt > file.patch
git apply file.patch

# diff между ветками
git diff main..feature > branch-diff.patch
git checkout main
git apply branch-diff.patch
```

---

## git am

Apply Mail — применяет патч-файлы как полноценные коммиты (сохраняя автора, дату, сообщение).

```bash
# Применить один патч как коммит
git am 0001-feat-auth.patch

# Применить несколько патчей
git am *.patch
git am /tmp/patches/*.patch

# Из mbox-файла (почтовый формат)
git am mbox-file

# Из stdin
git format-patch -1 --stdout | git am

# Продолжить после разрешения конфликта
git add .
git am --continue
# Или --resolved (синоним)

# Пропустить текущий патч
git am --skip

# Отменить применение
git am --abort

# Настроить кодировку
git am --utf8
```

### Email-workflow (пример)

```bash
# 1. Автор создаёт патчи
git format-patch main..feature -o /tmp/patches/
# /tmp/patches/0001-feat-auth.patch
# /tmp/patches/0002-fix-bug.patch

# 2. Отправляет по email (или передаёт файлы)

# 3. Получатель применяет
git checkout -b feature
git am /tmp/patches/*.patch
# Каждый патч → отдельный коммит с оригинальным автором

# 4. При конфликте
# Редактировать файлы
git add .
git am --continue
```

---

## git archive

Экспортирует дерево (snapshot) коммита в архив. Без истории git — только файлы.

```bash
# Создать tar-архив HEAD
git archive --format=tar --output=snapshot.tar HEAD

# zip-архив
git archive --format=zip --output=snapshot.zip HEAD

# Указать префикс (директорию внутри архива)
git archive --format=tar --prefix=project-v1.0/ HEAD | gzip > project-v1.0.tar.gz
git archive --format=zip --prefix=project-v1.0/ -o project-v1.0.zip HEAD

# По тегу
git archive --format=tar.gz --output=release-1.0.tar.gz v1.0.0

# Только определённые пути
git archive --format=zip HEAD src/ docs/ > src-docs.zip

# Список файлов без создания архива
git archive --format=tar HEAD | tar -tf -
```

### Использование для релизов

```bash
# Создание release-архива
git archive --format=tar.gz --prefix=app-$(git describe --tags)/ \
  v$(git describe --tags) > app-$(git describe --tags).tar.gz
```

---

## git bundle

Упаковывает репозиторий (включая историю) в один файл. Для офлайн-передачи (USB, email).

```bash
# Создать bundle всей истории
git bundle create repo.bundle --all

# Bundle конкретной ветки
git bundle create feature.bundle feature

# Bundle диапазона коммитов
git bundle create changes.bundle main..feature

# Проверить bundle
git bundle verify repo.bundle

# Клонировать из bundle
git clone repo.bundle my-repo

# Fetch из bundle (добавить как remote)
git fetch repo.bundle 'refs/heads/*:refs/remotes/bundle/*'

# Проверить, какие ветки в bundle
git bundle list-heads repo.bundle
```

### Сценарий: офлайн-перенос

```bash
# На машине без интернета:
# 1. Создать bundle
git bundle create my-work.bundle main..feature

# 2. Перенести на флешке

# 3. На другой машине:
git fetch /path/to/my-work.bundle
git log FETCH_HEAD
git merge FETCH_HEAD
# Или
git pull /path/to/my-work.bundle feature
```
