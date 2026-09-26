#!/usr/bin/env bash
# ============================================================================
#  test-router.sh — Тесты для Маршрутизатора git-router.sh
# ============================================================================
#  Версия: 1.0.0
#  Запуск:  bash test-router.sh
#  Результат: PASS/FAIL по каждой группе тестов + итоговая оценка
# ============================================================================
set -uo pipefail  # -e убран: провал одного теста не должен убивать весь скрипт

# Путь к Маршрутизатору
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROUTER="$SCRIPT_DIR/../scripts/git-router.sh"

# Временная директория для тестов
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Счётчики
PASSED=0
FAILED=0
TOTAL=0

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
#  Вспомогательные функции
# ============================================================================

# Заголовок группы тестов
group() {
    echo ""
    echo -e "${CYAN}${BOLD}=== $1 ===${NC}"
}

# Отдельный тест
# Использование: test_case "описание" команда [аргументы...]
test_case() {
    local description="$1"
    shift
    TOTAL=$((TOTAL + 1))

    echo -n "  [TEST] $description ... "

    if "$@" </dev/null >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
}

# Тест с проверкой вывода (grep)
test_case_grep() {
    local description="$1"
    local pattern="$2"
    shift 2
    TOTAL=$((TOTAL + 1))

    echo -n "  [TEST] $description ... "

    local output
    local status=0
    output=$("$@" </dev/null 2>&1) || status=$?

    # Here-string avoids SIGPIPE from grep -q on long output under pipefail.
    if [ "$status" -eq 0 ] && grep -qE "$pattern" <<< "$output"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Ожидалось совпадение: $pattern"
        echo "    Код выхода: $status; получено: ${output:0:100}"
        FAILED=$((FAILED + 1))
    fi
}

# Тест ожидания ошибки (команда должна НЕ выполниться)
test_case_fail() {
    local description="$1"
    shift
    TOTAL=$((TOTAL + 1))

    echo -n "  [TEST] $description ... "

    if ! "$@" </dev/null >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
}

# ============================================================================
#  Подготовка тестового окружения
# ============================================================================

setup_test_repo() {
    cd "$TMPDIR"

    # Создаём тестовый git-репозиторий
    git init test-repo >/dev/null 2>&1
    cd test-repo

    # Настройка локального git (без --global)
    git config user.name "Тест Тестов"
    git config user.email "test@example.com"
    git config init.defaultBranch main

    # Если ветка master вместо main, переименуем
    git branch -m master main 2>/dev/null || true

    # Создаём файлы и первый коммит
    echo "# Тестовый проект" > README.md
    echo "node_modules/" > .gitignore
    echo "print('hello')" > app.py
    git add .
    git commit -m "chore: начальная структура" >/dev/null 2>&1

    # Создаём вторую версию файла
    echo "print('hello world')" > app.py
    git add .
    git commit -m "feat: обновлён вывод" >/dev/null 2>&1

    # Создаём третью версию
    echo "print('hello world!')" > app.py
    git add .
    git commit -m "feat: добавлен восклицательный знак" >/dev/null 2>&1
}

# ============================================================================
#  ТЕСТЫ
# ============================================================================

main() {
    echo -e "${BOLD}Тесты Маршрутизатора git-router.sh${NC}"
    echo -e "Версия: $($ROUTER version 2>/dev/null || echo '1.0.0')"
    echo "Временная директория: $TMPDIR"

    # --- Группа 1: Справка и версия ---
    group "Справка и версия"

    test_case "version выводит версию" \
        bash "$ROUTER" version

    test_case "help работает (без аргументов)" \
        bash "$ROUTER" help

    test_case_grep "help показывает список команд" "init|commit|merge|stash" \
        bash "$ROUTER" help

    test_case_grep "help по конкретной команде" "commit" \
        bash "$ROUTER" help commit

    test_case_grep "help содержит Conventional Commits" "Conventional" \
        bash "$ROUTER" help

    # --- Группа 2: Базовая структура скрипта ---
    group "Структура скрипта"

    test_case "Скрипт существует" \
        test -f "$ROUTER"

    test_case "Скрипт исполняемый" \
        test -x "$ROUTER"

    test_case_grep "Скрипт содержит shebang" "^#!/usr/bin/env bash" \
        cat "$ROUTER"

    test_case_grep "Содержит set -euo pipefail" "set -euo pipefail" \
        cat "$ROUTER"

    test_case_grep "Содержит функции безопасности (confirm)" "confirm\(\)" \
        cat "$ROUTER"

    # --- Группа 3: Настройка в тестовом репо ---
    group "Базовые операции в тестовом репо"

    setup_test_repo

    test_case_grep "status показывает текущую ветку" "main|master" \
        bash "$ROUTER" status

    test_case_grep "log показывает коммиты" "chore|feat" \
        bash "$ROUTER" log 5

    test_case_grep "log-detailed работает" "chore|feat" \
        bash "$ROUTER" log-detailed

    # --- Группа 4: Файлы и коммиты ---
    group "Файлы и коммиты"

    # Добавляем новый файл
    echo "def add(a, b): return a + b" > utils.py
    test_case "add добавляет файл в индекс" \
        bash "$ROUTER" add utils.py

    test_case_grep "status показывает staged файл" "utils.py" \
        bash "$ROUTER" status

    # Коммит
    test_case "commit создаёт коммит" \
        bash "$ROUTER" commit "feat: добавлена функция add"

    test_case_grep "log показывает новый коммит" "функция add" \
        bash "$ROUTER" log 5

    # Unstage
    echo "def sub(a, b): return a - b" >> utils.py
    bash "$ROUTER" add utils.py >/dev/null 2>&1
    test_case "unstage убирает из индекса" \
        bash "$ROUTER" unstage utils.py

    # Коммит без сообщения должен ошибаться
    test_case_fail "commit без сообщения — ошибка" \
        bash "$ROUTER" commit

    # --- Группа 5: Ветки ---
    group "Ветки"

    test_case "branch-create создаёт ветку" \
        bash "$ROUTER" branch-create feature/test

    test_case_grep "branch-list показывает новую ветку" "feature/test" \
        bash "$ROUTER" branch-list

    test_case "branch-switch на main" \
        bash "$ROUTER" branch-switch main

    # Создаём ветку для удаления
    bash "$ROUTER" branch-create temp-branch >/dev/null 2>&1
    bash "$ROUTER" branch-switch main >/dev/null 2>&1

    test_case "branch-delete удаляет ветку" \
        bash "$ROUTER" branch-delete temp-branch

    # --- Группа 6: Stash ---
    group "Stash"

    # Создаём изменения для stash
    echo "temporary change" >> app.py

    test_case "stash save прячет изменения" \
        bash "$ROUTER" stash save "WIP тест"

    test_case_grep "stash list показывает запись" "WIP тест" \
        bash "$ROUTER" stash list

    test_case "stash pop возвращает изменения" \
        bash "$ROUTER" stash pop

    # --- Группа 7: Undo / Revert ---
    group "Undo / Revert"

    # Создаём коммит для отмены
    echo "test line" > temp.txt
    git add temp.txt
    git commit -m "chore: временный файл" >/dev/null 2>&1

    test_case "undo-last отменяет коммит (soft)" \
        env AUTO_CONFIRM=yes bash "$ROUTER" undo-last

    # Коммит снова
    git add temp.txt
    git commit -m "chore: временный файл" >/dev/null 2>&1

    test_case "revert создаёт коммит отмены" \
        bash "$ROUTER" revert HEAD

    # --- Группа 8: Diff и Blame ---
    group "Diff и Blame"

    test_case "diff показывает изменения" \
        bash "$ROUTER" diff

    test_case "blame показывает авторов строк" \
        bash "$ROUTER" blame app.py

    test_case "reflog показывает историю" \
        bash "$ROUTER" reflog

    # --- Группа 9: Tag ---
    group "Tag"

    test_case "tag создаёт аннотированный тег" \
        env AUTO_CONFIRM=yes bash "$ROUTER" tag v0.1.0 "Тестовый тег"

    test_case_grep "tag-list показывает тег" "v0.1.0" \
        bash "$ROUTER" tag-list

    # --- Группа 10: Обслуживание ---
    group "Обслуживание"

    test_case "gc выполняет сборку мусора" \
        bash "$ROUTER" gc

    test_case "fsck проверяет целостность" \
        bash "$ROUTER" fsck

    # --- Группа 11: Archive и Bundle ---
    group "Archive и Bundle"

    test_case "archive создаёт tar" \
        bash "$ROUTER" archive tar "$TMPDIR/snapshot.tar"

    test_case "archive файл создан" \
        test -f "$TMPDIR/snapshot.tar"

    test_case "bundle создаёт файл" \
        bash "$ROUTER" bundle "$TMPDIR/repo.bundle"

    test_case "bundle файл создан" \
        test -f "$TMPDIR/repo.bundle"

    # --- Группа 12: Notes ---
    group "Notes"

    test_case "notes-add добавляет заметку" \
        bash "$ROUTER" notes-add "Тестовая заметка"

    test_case_grep "git log показывает notes" "Тестовая заметка" \
        git log --show-notes -1

    # --- Группа 13: File at date ---
    group "File at date"

    test_case_grep "file-at-date показывает версию файла" "hello" \
        bash "$ROUTER" file-at-date "2099-12-31" app.py

    # --- Группа 14: Patch ---
    group "Patch"

    test_case "patch-create создаёт патч-файлы" \
        bash "$ROUTER" patch-create 1

    # --- Группа 15: Worktree ---
    group "Worktree"

    test_case "worktree-add создаёт рабочее дерево" \
        bash "$ROUTER" worktree-add "$TMPDIR/wt-test" feature/test

    test_case_grep "worktree-list показывает дерево" "wt-test" \
        bash "$ROUTER" worktree-list

    test_case "worktree-remove удаляет дерево" \
        env AUTO_CONFIRM=yes bash "$ROUTER" worktree-remove "$TMPDIR/wt-test"

    # --- Группа 16: Безопасность (деструктивные операции) ---
    group "Проверки безопасности"

    # undo-hard без подтверждения должен быть отменён
    test_case_fail "undo-hard без AUTO_CONFIRM отменяется" \
        bash "$ROUTER" undo-hard

    # undo-hard с AUTO_CONFIRM выполняется
    test_case "undo-hard с AUTO_CONFIRM выполняется" \
        env AUTO_CONFIRM=yes bash "$ROUTER" undo-hard

    # --- Группа 17: Submodule ---
    group "Submodule"

    # Создаём мини-репо для подмодуля
    cd "$TMPDIR"
    git init lib-repo >/dev/null 2>&1
    cd lib-repo
    git config user.name "Тест"
    git config user.email "test@test.com"
    echo "lib content" > lib.txt
    git add .
    git commit -m "init lib" >/dev/null 2>&1

    cd "$TMPDIR/test-repo"
    test_case "submodule-add добавляет подмодуль" \
        bash "$ROUTER" submodule-add "$TMPDIR/lib-repo" libs/lib

    test_case_grep "submodule-list показывает подмодуль" "lib" \
        bash "$ROUTER" submodule-list

    test_case "submodule-update обновляет подмодули" \
        bash "$ROUTER" submodule-update

    test_case "submodule-remove удаляет подмодуль" \
        env AUTO_CONFIRM=yes bash "$ROUTER" submodule-remove libs/lib

    # --- Группа 18: Неизвестная команда ---
    group "Обработка ошибок"

    test_case_fail "Неизвестная команда — ошибка" \
        bash "$ROUTER" nonexistent-command-xyz

    test_case_fail "init без имени — ошибка" \
        bash "$ROUTER" init

    test_case_fail "clone без URL — ошибка" \
        bash "$ROUTER" clone

    test_case_fail "commit без индекса — справка" \
        bash "$ROUTER" commit ""

    # --- Группа 19: Все команды из требований ---
    group "Покрытие команд из ТЗ"

    # Проверяем, что все ключевые команды определены в скрипте
    local commands=(
        "config" "init" "clone" "remote-add" "add" "unstage"
        "commit" "push" "pull" "fetch" "status"
        "undo-last" "undo-hard" "revert" "restore-file" "file-at-date"
        "branch-create" "branch-switch" "branch-list" "branch-delete" "branch-rename"
        "merge" "merge-abort" "rebase" "rebase-abort" "rebase-interactive"
        "resolve-conflict"
        "stash" "cherry-pick" "tag" "tag-list"
        "log" "log-detailed" "diff" "blame" "reflog"
        "bisect-start" "bisect-reset"
        "pr-create" "pr-list" "pr-merge" "pr-close" "pr-review" "pr-checkout"
        "issue-create" "issue-list" "issue-close"
        "release-create"
        "worktree-add" "worktree-list" "worktree-remove"
        "submodule-add" "submodule-update" "submodule-list" "submodule-remove"
        "patch-create" "patch-apply"
        "gc" "fsck" "archive" "bundle" "sparse-set" "notes-add"
        "help" "version"
    )

    for cmd in "${commands[@]}"; do
        TOTAL=$((TOTAL + 1))
        if grep -q "cmd_$(echo "$cmd" | tr '-' '_' | sed 's/_[0-9]*//')" "$ROUTER" 2>/dev/null \
           || grep -q "$cmd)" "$ROUTER" 2>/dev/null; then
            echo -e "  [TEST] Команда '$cmd' определена ... ${GREEN}PASS${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "  [TEST] Команда '$cmd' определена ... ${RED}FAIL${NC}"
            FAILED=$((FAILED + 1))
        fi
    done

    # ============================================================================
    #  ИТОГИ
    # ============================================================================
    echo ""
    echo -e "${BOLD}=============================================================================${NC}"
    echo -e "${BOLD}  ИТОГИ ТЕСТИРОВАНИЯ${NC}"
    echo -e "${BOLD}=============================================================================${NC}"
    echo "  Всего тестов:  $TOTAL"
    echo -e "  ${GREEN}Пройдено:       $PASSED${NC}"
    echo -e "  ${RED}Провалено:      $FAILED${NC}"
    echo ""

    if [ "$FAILED" -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ${NC}"
        SCORE=10
    else
        local pct=$((PASSED * 100 / TOTAL))
        echo -e "  ${YELLOW}Процент прохождения: ${pct}%${NC}"

        if [ "$pct" -ge 95 ]; then
            SCORE=9
        elif [ "$pct" -ge 90 ]; then
            SCORE=8
        elif [ "$pct" -ge 80 ]; then
            SCORE=7
        else
            SCORE=6
        fi
    fi

    echo ""
    echo -e "  ${BOLD}Оценка Маршрутизатора: $SCORE / 10${NC}"
    echo ""

    return "$FAILED"
}

main "$@"
