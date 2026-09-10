# 03 — Продвинутые операции: stash, cherry-pick, revert, rebase -i, tag

> Полный справочник по продвинутым операциям Git.

---

## Содержание
1. [git stash — временное хранение](#git-stash)
2. [git cherry-pick — точечное применение коммитов](#git-cherry-pick)
3. [git revert — безопасная отмена](#git-revert)
4. [git rebase -i — интерактивный rebase](#git-rebase--i)
5. [git tag — теги и релизы](#git-tag)

---

## git stash

Stash прячет незакоммиченные изменения (staged + unstaged) и возвращает рабочую директорию в состояние HEAD.

### Базовые операции

```bash
# Спрятать изменения (tracked файлы)
git stash
git stash push -m "WIP: эксперимент с авторизацией"

# Спрятать включая untracked файлы
git stash -u
git stash --include-untracked

# Спрятать включая игнорируемые файлы
git stash -a
git stash --all

# Только конкретные файлы
git stash push -m "только конфиг" -- config/local.env

# Спрятать только staged ( unstaged остаются)
git stash --keep-index
```

### Просмотр и применение

```bash
# Список stash
git stash list
# stash@{0}: WIP on feature: abc1234 feat: добавлен логин
# stash@{1}: WIP on main: def5678 fix: исправлен баг

# Применить последний stash (и оставить в списке)
git stash apply

# Применить конкретный stash
git stash apply stash@{2}

# Применить и удалить из списка (рекомендуется)
git stash pop

# Посмотреть содержимое stash
git stash show
git stash show -p          # полный diff
git stash show stash@{1}   # конкретный

# Посмотреть файлы в stash
git stash show --stat
```

### Удаление

```bash
# Удалить конкретный stash
git stash drop stash@{1}

# Удалить все stash
git stash clear
```

### Создать ветку из stash

```bash
# Если stash конфликтует с текущей веткой — создать новую ветку
git stash branch feature-from-stash stash@{0}
```

### Частичный stash (патч)

```bash
# Интерактивный выбор частей для stash
git stash push -p -m "частичный stash"
```

---

## git cherry-pick

Применяет один (или несколько) коммитов из другой ветки к текущей.

```bash
# Применить один коммит
git cherry-pick abc1234

# Применить несколько коммитов
git cherry-pick abc1234 def5678 ghi9012

# Применить диапазон коммитов (не включая start)
git cherry-pick A..B
# Включая start:
git cherry-pick A^..B

# Только изменения, без коммита (оставить в индексе)
git cherry-pick --no-commit abc1234
git cherry-pick -n abc1234

# Изменить сообщение при cherry-pick
git cherry-pick --edit abc1234

# Сохранить исходный автор коммита
git cherry-pick -x abc1234
# Добавляет "cherry picked from commit ..." в сообщение

# Добавить подпись (sign-off)
git cherry-pick -s abc1234

# При конфликте
git cherry-pick --continue    # продолжить после разрешения
git cherry-pick --abort       # отменить
git cherry-pick --skip         # пропустить текущий, перейти к следующему
```

**Сценарий:** исправили баг в main, нужно применить тот же фикс в develop:

```bash
git checkout develop
git cherry-pick <hash-фикса-из-main>
git push origin develop
```

---

## git revert

Создаёт **новый коммит**, который отменяет изменения указанного коммита. Безопасно для общих веток — не переписывает историю.

```bash
# Отменить последний коммит
git revert HEAD

# Отменить конкретный коммит
git revert abc1234

# Отменить несколько коммитов
git revert abc1234 def5678

# Отменить диапазон
git revert HEAD~3..HEAD

# Без автоматического коммита (сначала проверить)
git revert --no-commit abc1234

# Отмена merge commit
git revert -m 1 <merge-commit-hash>
# -m 1 = основная линия (main), -m 2 = сливаемая ветка

# При конфликте
git revert --continue
git revert --abort
git revert --skip
```

**revert vs reset:**

| Свойство | `git revert` | `git reset --hard` |
|----------|-------------|---------------------|
| История | Сохраняет (новый коммит отмены) | Переписывает |
| Безопасность | Безопасно для общих веток | Опасно |
| Видимость | Видно в логе | Не видно |
| Использовать | На `main`, `develop` | На локальных feature-ветках |

---

## git rebase -i

См. раздел [02-git-branches-merge.md → Rebase](02-git-branches-merge.md) для полного руководства по интерактивному rebase.

### Дополнительно: autosquash

```bash
# При rebase -i автоматически обрабатывать fixup! и squash! коммиты
git rebase -i --autosquash HEAD~10

# При коммите можно указать, что это fixup конкретного коммита
git commit --fixup=abc1234    # создаст "fixup! <subject of abc1234>"
git commit --squash=abc1234  # создаст "squash! <subject of abc1234>"

# Тогда --autosquash расставит их правильно
```

### Дополнительно: exec

```bash
# Запустить тесты после определённого коммита
git rebase -i HEAD~5
# pick abc1234 feat: логин
# exec npm test
# pick def5678 feat: регистрация
# exec npm test
```

---

## git tag

Теги — метки версий. Бывают двух типов:

### Легковесные (lightweight)

```bash
# Просто указатель на коммит
git tag v1.0.0
git tag v1.0.0 abc1234   # на конкретный коммит
```

### Аннотированные (annotated) — рекомендуется

```bash
# С сообщением, автором, датой, GPG-подписью
git tag -a v1.0.0 -m "Релиз версии 1.0.0"
git tag -a v1.0.0 abc1234 -m "Релиз 1.0.0"

# Подписанный тег (GPG)
git tag -s v1.0.0 -m "Релиз 1.0.0"
```

### Просмотр и операции

```bash
# Список тегов
git tag
git tag -l "v1.*"
git tag -l --sort=-v:refname    # отсортированный по версии

# Посмотреть детали аннотированного тега
git show v1.0.0

# Push тегов на remote
git push origin v1.0.0           # конкретный
git push origin --tags          # все
git push origin --follow-tags   # теги, достижимые из запушенных коммитов

# Удалить тег
git tag -d v1.0.0               # локально
git push origin --delete v1.0.0 # на remote

# Checkout на тег (отсоединённый HEAD)
git checkout v1.0.0

# Создать ветку от тега
git switch -c release/v1.0 v1.0.0
```

### Semver-соглашения

```
v1.0.0     → первый стабильный релиз
v1.1.0     → новая фича (minor)
v1.1.1     → багфикс (patch)
v2.0.0     → breaking change (major)
v1.0.0-rc.1 → release candidate
v1.0.0-beta.1 → бета
```

### Создание Release на платформах

```bash
# GitHub через gh
gh release create v1.0.0 --title "Релиз 1.0.0" --notes "Первая стабильная версия" ./dist/app.tar.gz

# GitLab через glab
glab release create v1.0.0 --name "Релиз 1.0.0" --notes "Первая стабильная версия" ./dist/app.tar.gz
```
