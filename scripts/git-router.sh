#!/usr/bin/env bash
# ============================================================================
#  git-router.sh — Маршрутизатор команд Git / GitHub / GitLab
# ============================================================================
#  Версия: 1.0.0
#  Язык:   Bash 4+ (Windows: Git Bash)
#  Автор:  Буффи (Buffy) — для Симморы
#
#  ОПИСАНИЕ
#    Диспетчер-скрипт, принимающий задачу на естественном языке и выполняющий
#    соответствующую последовательность git / gh / glab команд с проверками
#    безопасности. Деструктивные операции требуют подтверждения.
#
#  ИСПОЛЬЗОВАНИЕ
#    bash git-router.sh <команда> [аргументы...]
#    bash git-router.sh help                           # список всех команд
#    bash git-router.sh help <команда>                 # справка по команде
#
#  ПРИМЕРЫ
#    bash git-router.sh config "Иван Иванов" ivan@example.com
#    bash git-router.sh init my-project
#    bash git-router.sh clone https://github.com/user/repo.git
#    bash git-router.sh commit "feat: добавлена авторизация"
#    bash git-router.sh undo-last
#    bash git-router.sh stash save "WIP: эксперимент"
#    bash git-router.sh pr-create --title "Feature" --base main
#    bash git-router.sh bisect-start
#
#  БЕЗОПАСНОСТЬ
#    Команды, которые могут привести к потере данных (reset --hard, push --force,
#    clean -fd, merge --abort, branch -D), требуют явного подтверждения (y/N).
#    Для обхода в неинтерактивном режиме: установите переменную AUTO_CONFIRM=yes
#
#  ЗАВИСИМОСТИ
#    git >= 2.40, gh (GitHub CLI), glab (GitLab CLI) — опционально
# ============================================================================

set -euo pipefail

# ============================================================================
#  Глобальные переменные
# ============================================================================
ROUTER_VERSION="1.0.0"
AUTO_CONFIRM="${AUTO_CONFIRM:-no}"

# Цвета (отключаются если не терминал)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

# ============================================================================
#  Вспомогательные функции
# ============================================================================

# Вывод инфо-сообщения
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Вывод успешного действия
success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

# Вывод предупреждения
warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Вывод ошибки
error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Проверка нахождения в git-репозитории
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        error "Текущая директория не является git-репозиторием."
        error "Выполните 'git init' или перейдите в существующий репозиторий."
        exit 1
    fi
}

# Проверка установленного инструмента
check_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        error "Инструмент '$tool' не найден. Установите его или добавьте в PATH."
        exit 1
    fi
}

# Запрос подтверждения у пользователя
# Использование: confirm "Удалить ветку feature? (это необратимо)"
confirm() {
    local prompt="$1"

    if [ "$AUTO_CONFIRM" = "yes" ]; then
        warn "AUTO_CONFIRM=yes — подтверждаю автоматически: $prompt"
        return 0
    fi

    echo -en "${YELLOW}[ВНИМАНИЕ]${NC} $prompt ${BOLD}(y/N)${NC} "
    local answer=""
    read -r answer 2>/dev/null || true
    case "$answer" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            warn "Операция отменена пользователем."
            return 1
            ;;
    esac
}

# Определение платформы удалённого репозитория
# Выводит: github, gitlab, или unknown
detect_remote_platform() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if echo "$remote_url" | grep -qi "github.com"; then
        echo "github"
    elif echo "$remote_url" | grep -qi "gitlab.com\|gitlab\."; then
        echo "gitlab"
    else
        echo "unknown"
    fi
}

# Генерация сообщения коммита в формате Conventional Commits
# Использование: generate_commit_message "type" "scope" "description"
generate_commit_message() {
    local type="${1:-feat}"
    local scope="${2:-}"
    local description="${3:-обновление}"

    if [ -n "$scope" ]; then
        echo "${type}(${scope}): ${description}"
    else
        echo "${type}: ${description}"
    fi
}

# ============================================================================
#  КОМАНДЫ: Настройка и инициализация
# ============================================================================

cmd_config() {
    # Настройка git: имя и email
    local name="${1:-}"
    local email="${2:-}"

    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "Использование: git-router.sh config <Имя> <email>"
        echo "Пример:        git-router.sh config \"Иван Иванов\" ivan@example.com"
        echo ""
        echo "Дополнительно настраивает:"
        echo "  - init.defaultBranch = main"
        echo "  - pull.rebase = true"
        echo "  - credential.helper = store"
        echo "  - alias.lg (красивый лог)"
        exit 1
    fi

    info "Настройка git глобально..."
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global push.autoSetupRemote true
    git config --global credential.helper store
    git config --global alias.lg "log --graph --oneline --decorate --all"

    success "Git настроен:"
    echo "  Имя:   $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"
    echo "  Ветка: $(git config --global init.defaultBranch)"
}

cmd_init() {
    # Создание локального репозитория (+ опционально удалённого)
    local project_name="${1:-}"
    local visibility="${2:-public}" # public | private
    local platform="${3:-github}"   # github | gitlab

    if [ -z "$project_name" ]; then
        echo "Использование: git-router.sh init <имя-проекта> [public|private] [github|gitlab]"
        echo "Пример:        git-router.sh init my-project public github"
        exit 1
    fi

    # Создание локального репо
    info "Создание локального репозитория: $project_name"
    mkdir -p "$project_name"
    cd "$project_name"
    git init
    git symbolic-ref HEAD refs/heads/main

    # Базовые файлы
    if [ ! -f README.md ]; then
        echo "# $project_name" > README.md
    fi
    if [ ! -f .gitignore ]; then
        echo "# Базовый .gitignore" > .gitignore
        echo "*.log\ntmp/\nnode_modules/\n.env" >> .gitignore
    fi

    git add .
    git commit -m "chore: начальная структура проекта"

    success "Локальный репозиторий создан: $project_name"

    # Создание удалённого репо
    if [ "$platform" = "github" ]; then
        check_tool gh
        info "Создание удалённого репо на GitHub ($visibility)..."
        if gh repo create "$project_name" --"$visibility" --source=. --push 2>/dev/null; then
            success "Удалённый репо создан на GitHub"
        else
            warn "Не удалось создать удалённый репо на GitHub. Возможно, не авторизованы."
            warn "Выполните: gh auth login"
        fi
    elif [ "$platform" = "gitlab" ]; then
        check_tool glab
        info "Создание удалённого репо на GitLab ($visibility)..."
        if glab repo create "$project_name" --"$visibility" --source=. --push 2>/dev/null; then
            success "Удалённый репо создан на GitLab"
        else
            warn "Не удалось создать удалённый репо на GitLab. Возможно, не авторизованы."
            warn "Выполните: glab auth login"
        fi
    fi
}

cmd_clone() {
    # Клонирование репозитория
    local url="${1:-}"

    if [ -z "$url" ]; then
        echo "Использование: git-router.sh clone <URL>"
        echo "Пример:        git-router.sh clone https://github.com/user/repo.git"
        echo "               git-router.sh clone git@github.com:user/repo.git"
        exit 1
    fi

    info "Клонирование: $url"
    git clone "$url"
    success "Репозиторий клонирован"
}

cmd_remote_add() {
    # Добавление удалённого репозитория
    local name="${1:-origin}"
    local url="${2:-}"

    if [ -z "$url" ]; then
        echo "Использование: git-router.sh remote-add [name] <URL>"
        echo "Пример:        git-router.sh remote-add origin https://github.com/user/repo.git"
        exit 1
    fi

    git remote add "$name" "$url"
    success "Remote '$name' добавлен: $url"
}

# ============================================================================
#  КОМАНДЫ: Базовый рабочий цикл (add, commit, push, pull)
# ============================================================================

cmd_add() {
    # Добавление файлов в индекс
    local files="${*:-.}"

    check_git_repo
    git add $files
    success "Файлы добавлены в индекс: $files"
    git status --short
}

cmd_unstage() {
    # Убрать файлы из индекса (без отмены изменений)
    local files="${*:-.}"

    check_git_repo
    git restore --staged $files
    success "Файлы убраны из индекса: $files"
    git status --short
}

cmd_commit() {
    # Коммит изменений с проверкой сообщения
    local message="${1:-}"

    if [ -z "$message" ]; then
        echo "Использование: git-router.sh commit <сообщение>"
        echo "Пример:        git-router.sh commit \"feat: добавлена авторизация\""
        echo ""
        echo "Формат: type(scope): description"
        echo "Типы:   feat, fix, docs, style, refactor, test, chore, ci, build, perf, revert"
        exit 1
    fi

    check_git_repo

    # Проверка на пустой индекс
    if [ -z "$(git diff --cached --name-only)" ]; then
        warn "Индекс пуст. Сначала выполните: git-router.sh add <файлы>"
        exit 1
    fi

    # Проверка формата Conventional Commits
    if ! echo "$message" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)(\(.+\))?: .{1,}'; then
        warn "Сообщение не соответствует Conventional Commits."
        warn "Рекомендуемый формат: type(scope): description"
        warn "Тем не менее, коммичу как есть..."
    fi

    git commit -m "$message"
    success "Изменения закоммичены: $message"
    echo ""
    git log --oneline -1
}

cmd_push() {
    # Push на удалённый репозиторий
    local force="${1:-}"

    check_git_repo

    if [ "$force" = "--force" ] || [ "$force" = "-f" ]; then
        confirm "Force push перезапишет удалённую историю. Продолжить?" || exit 1
        git push --force-with-lease
        success "Force push выполнен (с --force-with-lease)"
    else
        git push
        success "Изменения отправлены на remote"
    fi
}

cmd_pull() {
    # Pull с удалённого репозитория
    local rebase="${1:-}"

    check_git_repo

    if [ "$rebase" = "--rebase" ] || [ "$rebase" = "-r" ]; then
        git pull --rebase
        success "Pull с rebase выполнен"
    else
        git pull
        success "Pull выполнен"
    fi
}

cmd_fetch() {
    # Fetch без merge
    check_git_repo
    git fetch --all --prune
    success "Fetch выполнен (все remote, prune включён)"
}

cmd_status() {
    # Показать статус
    check_git_repo
    git status -sb
}

# ============================================================================
#  КОМАНДЫ: Восстановление и отмена
# ============================================================================

cmd_undo_last() {
    # Отмена последнего коммита (soft — изменения остаются в индексе)
    check_git_repo

    local last_msg
    last_msg=$(git log -1 --format=%s)
    confirm "Отменить последний коммит (soft — изменения сохранятся)? [$last_msg]" || exit 1

    git reset --soft HEAD~1
    success "Последний коммит отменён (soft). Изменения в индексе."
    git status --short
}

cmd_undo_hard() {
    # Отмена последнего коммита (hard — изменения теряются)
    check_git_repo

    local last_msg
    last_msg=$(git log -1 --format=%s)
    echo -e "${RED}[ОПАСНО]${NC} Hard reset удалит все изменения последнего коммита безвозвратно!"
    confirm "Hard reset HEAD~1? [$last_msg]" || exit 1

    git reset --hard HEAD~1
    success "Hard reset выполнен. Изменения потеряны."
}

cmd_revert() {
    # Безопасная отмена коммита (создаёт новый коммит отмены)
    local commit="${1:-HEAD}"

    check_git_repo

    info "Revert коммита: $commit"
    git revert --no-edit "$commit"
    success "Revert выполнен. Создан новый коммит отмены."
    git log --oneline -3
}

cmd_restore_file() {
    # Восстановление файла из последнего коммита
    local file="${1:-}"

    if [ -z "$file" ]; then
        echo "Использование: git-router.sh restore <файл>"
        exit 1
    fi

    check_git_repo
    confirm "Восстановить '$file' из HEAD (локальные изменения будут потеряны)?" || exit 1
    git restore "$file"
    success "Файл восстановлен: $file"
}

cmd_file_at_date() {
    # Получить версию файла на дату
    local date="${1:-}"
    local file="${2:-}"

    if [ -z "$date" ] || [ -z "$file" ]; then
        echo "Использование: git-router.sh file-at-date <дата> <файл>"
        echo "Пример:        git-router.sh file-at-date 2025-06-15 src/config.ts"
        echo "               git-router.sh file-at-date '2 weeks ago' src/config.ts"
        exit 1
    fi

    check_git_repo

    local hash
    hash=$(git log --before="$date" -1 --format=%H -- "$file")

    if [ -z "$hash" ]; then
        error "Не найден коммит для файла '$file' до даты '$date'"
        exit 1
    fi

    info "Последний коммит до $date: $hash"
    echo "---"
    git show "$hash:$file"
    echo "---"
    success "Версия файла '$file' на дату '$date' показана выше"
}

# ============================================================================
#  КОМАНДЫ: Ветки
# ============================================================================

cmd_branch_create() {
    # Создать ветку и переключиться
    local branch="${1:-}"

    if [ -z "$branch" ]; then
        echo "Использование: git-router.sh branch-create <имя-ветки>"
        exit 1
    fi

    check_git_repo
    git switch -c "$branch"
    success "Ветка создана и активна: $branch"
}

cmd_branch_switch() {
    # Переключиться на ветку
    local branch="${1:-}"

    if [ -z "$branch" ]; then
        echo "Использование: git-router.sh branch-switch <имя-ветки>"
        exit 1
    fi

    check_git_repo
    git switch "$branch"
    success "Переключено на ветку: $branch"
}

cmd_branch_list() {
    # Список веток
    check_git_repo
    git branch -vv
}

cmd_branch_delete() {
    # Удалить ветку
    local branch="${1:-}"
    local force="${2:-}"

    if [ -z "$branch" ]; then
        echo "Использование: git-router.sh branch-delete <имя-ветки> [--force]"
        exit 1
    fi

    check_git_repo

    if [ "$force" = "--force" ] || [ "$force" = "-f" ]; then
        confirm "Принудительно удалить локальную ветку '$branch' (без проверки слияния)?" || exit 1
        git branch -D "$branch"
    else
        git branch -d "$branch"
    fi

    # Предложение удалить удалённую ветку
    if git ls-remote --exit-code origin "$branch" >/dev/null 2>&1; then
        confirm "Удалить также удалённую ветку '$branch' на remote?" || exit 1
        git push origin --delete "$branch"
        success "Удалённая ветка удалена: $branch"
    fi

    success "Ветка удалена: $branch"
}

cmd_branch_rename() {
    # Переименовать ветку
    local old_name="${1:-}"
    local new_name="${2:-}"

    if [ -z "$old_name" ] || [ -z "$new_name" ]; then
        echo "Использование: git-router.sh branch-rename <старое-имя> <новое-имя>"
        exit 1
    fi

    check_git_repo
    git branch -m "$old_name" "$new_name"
    success "Ветка переименована: $old_name → $new_name"
}

# ============================================================================
#  КОМАНДЫ: Слияние и rebase
# ============================================================================

cmd_merge() {
    # Слияние веток
    local branch="${1:-}"
    local strategy="${2:---no-ff}"

    if [ -z "$branch" ]; then
        echo "Использование: git-router.sh merge <ветка> [--no-ff|--ff-only|--squash]"
        echo "Стратегии:"
        echo "  --no-ff     всегда создавать merge commit (по умолчанию)"
        echo "  --ff-only   только fast-forward (ошибка если невозможно)"
        echo "  --squash    объединить все коммиты в один"
        exit 1
    fi

    check_git_repo

    info "Слияние ветки '$branch' в текущую (стратегия: $strategy)"
    git merge "$strategy" "$branch"
    success "Слияние выполнено"
}

cmd_merge_abort() {
    # Отмена незавершённого слияния
    check_git_repo
    confirm "Отменить незавершённое слияние (изменения будут потеряны)?" || exit 1
    git merge --abort
    success "Слияние отменено"
}

cmd_rebase() {
    # Rebase текущей ветки
    local base="${1:-main}"

    check_git_repo

    info "Rebase текущей ветки поверх '$base'"
    git rebase --autostash "$base"
    success "Rebase выполнен"

    warn "Если были конфликты, разрешите их и выполните:"
    warn "  git add . && git rebase --continue"
    warn "Для отмены: git rebase --abort"
}

cmd_rebase_abort() {
    check_git_repo
    git rebase --abort 2>/dev/null || true
    success "Rebase отменён"
}

cmd_rebase_interactive() {
    # Интерактивный rebase
    local count="${1:-5}"

    check_git_repo

    info "Запуск интерактивного rebase последних $count коммитов"
    warn "Откроется редактор. Команды: pick, squash, fixup, reword, drop, edit"
    git rebase -i "HEAD~$count"
}

cmd_resolve_conflict() {
    # Помощь при разрешении конфликтов
    check_git_repo

    local conflicted
    conflicted=$(git diff --name-only --diff-filter=U)

    if [ -z "$conflicted" ]; then
        success "Конфликтов нет."
        exit 0
    fi

    warn "Конфликтующие файлы:"
    echo "$conflicted"
    echo ""
    info "Для разрешения:"
    echo "  1. Отредактируйте файлы, удалив маркеры <<<<<<<, =======, >>>>>>>"
    echo "  2. git add <разрешённые-файлы>"
    echo "  3. git merge --continue  (или git rebase --continue)"
    echo ""
    echo "  Быстрые варианты:"
    echo "  - Взять нашу версию:   git checkout --ours <файл>"
    echo "  - Взять их версию:    git checkout --theirs <файл>"
    echo "  - Визуально:          git mergetool"
}

# ============================================================================
#  КОМАНДЫ: Stash
# ============================================================================

cmd_stash() {
    # Операции со stash
    local action="${1:-list}"

    check_git_repo

    case "$action" in
        save|push)
            local message="${2:-WIP}"
            git stash push -u -m "$message"
            success "Изменения спрятаны: $message"
            ;;
        pop)
            git stash pop
            success "Stash применён и удалён"
            ;;
        apply)
            local index="${2:-0}"
            git stash apply "stash@{$index}"
            success "Stash stash@{$index} применён (не удалён из списка)"
            ;;
        list)
            echo "Список stash:"
            git stash list
            if [ -z "$(git stash list)" ]; then
                info "Stash пуст."
            fi
            ;;
        drop)
            local index="${2:-0}"
            confirm "Удалить stash@{$index}?" || exit 1
            git stash drop "stash@{$index}"
            success "stash@{$index} удалён"
            ;;
        clear)
            confirm "Удалить ВСЕ stash-записи?" || exit 1
            git stash clear
            success "Все stash удалены"
            ;;
        show)
            local index="${2:-0}"
            git stash show -p "stash@{$index}"
            ;;
        *)
            echo "Использование: git-router.sh stash [save|pop|apply|list|drop|clear|show]"
            exit 1
            ;;
    esac
}

# ============================================================================
#  КОМАНДЫ: Cherry-pick и Tag
# ============================================================================

cmd_cherry_pick() {
    # Cherry-pick коммита
    local commit="${1:-}"

    if [ -z "$commit" ]; then
        echo "Использование: git-router.sh cherry-pick <хеш-коммита>"
        echo "Пример:        git-router.sh cherry-pick abc1234"
        exit 1
    fi

    check_git_repo
    info "Cherry-pick коммита: $commit"
    git cherry-pick "$commit"
    success "Cherry-pick выполнен"
}

cmd_tag() {
    # Создание аннотированного тега
    local tag_name="${1:-}"
    local message="${2:-Релиз $1}"

    if [ -z "$tag_name" ]; then
        echo "Использование: git-router.sh tag <имя-тега> [сообщение]"
        echo "Пример:        git-router.sh tag v1.0.0 \"Релиз версии 1.0.0\""
        exit 1
    fi

    check_git_repo
    git tag -a "$tag_name" -m "$message"
    success "Аннотированный тег создан: $tag_name"

    # Предложение запушить тег
    confirm "Запушить тег '$tag_name' на remote?" && {
        git push origin "$tag_name" 2>/dev/null || warn "Не удалось запушить тег (нет remote?)"
    } || true
}

cmd_tag_list() {
    check_git_repo
    git tag -l --sort=-v:refname
}

# ============================================================================
#  КОМАНДЫ: Лог и Diff
# ============================================================================

cmd_log() {
    # Показать лог
    local count="${1:-20}"

    check_git_repo
    git log --graph --oneline --decorate -"$count"
}

cmd_log_detailed() {
    check_git_repo
    git log --graph --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %C(bold blue)%an%C(reset) %s" --date=short
}

cmd_diff() {
    # Показать diff
    local target="${1:-}"

    check_git_repo

    if [ -z "$target" ]; then
        git diff
    elif [ "$target" = "--cached" ] || [ "$target" = "--staged" ]; then
        git diff --cached
    else
        git diff "$target"
    fi
}

cmd_blame() {
    # Кто и когда изменил строки
    local file="${1:-}"

    if [ -z "$file" ]; then
        echo "Использование: git-router.sh blame <файл>"
        exit 1
    fi

    check_git_repo
    git blame --date=short "$file" | head -50
    info "Показаны первые 50 строк. Для полного вывода: git blame $file"
}

cmd_reflog() {
    # Журнал перемещений HEAD
    check_git_repo
    git reflog --date=iso | head -30
    info "Для восстановления потерянного коммита:"
    info "  git branch <имя> <хеш-из-reflog>"
}

# ============================================================================
#  КОМАНДЫ: Bisect
# ============================================================================

cmd_bisect_start() {
    # Начать бинарный поиск бага
    check_git_repo
    info "Запуск git bisect. Укажите good и bad коммиты."
    git bisect start
    echo ""
    echo "Дальнейшие шаги:"
    echo "  git bisect bad <хеш-или-HEAD>    # коммит где баг есть"
    echo "  git bisect good <хеш-или-тег>     # коммит где бага нет"
    echo "  # Git автоматически чекаутит средний коммит"
    echo "  git bisect good  # или git bisect bad"
    echo "  # Повторять пока не найдёте виновника"
    echo "  git bisect reset # завершить"
    echo ""
    echo "Автоматический режим:"
    echo "  git bisect run <команда-проверки>"
}

cmd_bisect_reset() {
    check_git_repo
    git bisect reset
    success "Bisect завершён"
}

# ============================================================================
#  КОМАНДЫ: Pull Requests (через gh/glab)
# ============================================================================

cmd_pr_create() {
    # Создание PR/MR
    local title=""
    local base="main"
    local draft="no"
    local body=""

    # Парсинг аргументов
    while [ $# -gt 0 ]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            --base) base="$2"; shift 2 ;;
            --body) body="$2"; shift 2 ;;
            --draft) draft="yes"; shift ;;
            *) shift ;;
        esac
    done

    check_git_repo

    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            local args=(pr create --base "$base")
            [ -n "$title" ] && args+=(--title "$title")
            [ -n "$body" ] && args+=(--body "$body")
            [ "$draft" = "yes" ] && args+=(--draft)
            [ -z "$title" ] && args+=(--fill)

            info "Создание PR на GitHub..."
            gh "${args[@]}"
            success "PR создан"
            ;;
        gitlab)
            check_tool glab
            local args=(mr create --target-branch "$base")
            [ -n "$title" ] && args+=(--title "$title")
            [ -n "$body" ] && args+=(--description "$body")
            [ "$draft" = "yes" ] && args+=(--draft)

            info "Создание MR на GitLab..."
            glab "${args[@]}"
            success "MR создан"
            ;;
        *)
            error "Не удалось определить платформу (github/gitlab)."
            error "Проверьте, что remote 'origin' настроен."
            exit 1
            ;;
    esac
}

cmd_pr_list() {
    # Список PR/MR
    check_git_repo

    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            gh pr list
            ;;
        gitlab)
            check_tool glab
            glab mr list
            ;;
        *)
            error "Платформа не определена."
            exit 1
            ;;
    esac
}

cmd_pr_merge() {
    # Слияние PR/MR
    local number="${1:-}"
    local strategy="${2:---squash}"

    if [ -z "$number" ]; then
        echo "Использование: git-router.sh pr-merge <номер> [--squash|--merge|--rebase]"
        exit 1
    fi

    check_git_repo

    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            gh pr merge "$number" "$strategy" --delete-branch
            success "PR #$number слит ($strategy)"
            ;;
        gitlab)
            check_tool glab
            glab mr merge "$number" --remove-source-branch
            success "MR !$number слит"
            ;;
        *)
            error "Платформа не определена."
            exit 1
            ;;
    esac
}

cmd_pr_close() {
    # Закрытие PR/MR
    local number="${1:-}"

    if [ -z "$number" ]; then
        echo "Использование: git-router.sh pr-close <номер>"
        exit 1
    fi

    check_git_repo

    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github) check_tool gh; gh pr close "$number" ;;
        gitlab) check_tool glab; glab mr close "$number" ;;
        *) error "Платформа не определена."; exit 1 ;;
    esac
    success "PR/MR #$number закрыт"
}

cmd_pr_review() {
    # Review PR/MR
    local number="${1:-}"
    local action="${2:-approve}" # approve | request-changes | comment
    local body="${3:--}"

    if [ -z "$number" ]; then
        echo "Использование: git-router.sh pr-review <номер> [approve|request-changes|comment] [сообщение]"
        exit 1
    fi

    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            case "$action" in
                approve)          gh pr review "$number" --approve --body "$body" ;;
                request-changes) gh pr review "$number" --request-changes --body "$body" ;;
                comment)          gh pr review "$number" --comment --body "$body" ;;
            esac
            ;;
        gitlab)
            check_tool glab
            case "$action" in
                approve)          glab mr review "$number" --approve ;;
                request-changes) glab mr review "$number" --request-changes --comment "$body" ;;
                comment)          glab mr note "$number" --message "$body" ;;
            esac
            ;;
    esac
    success "Review отправлен"
}

cmd_pr_checkout() {
    # Checkout ветки PR/MR локально
    local number="${1:-}"

    if [ -z "$number" ]; then
        echo "Использование: git-router.sh pr-checkout <номер>"
        exit 1
    fi

    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github) check_tool gh; gh pr checkout "$number" ;;
        gitlab) check_tool glab; glab mr checkout "$number" ;;
    esac
    success "Ветка PR/MR #$number переключена локально"
}

# ============================================================================
#  КОМАНДЫ: Issues
# ============================================================================

cmd_issue_create() {
    local title="${1:-}"
    local body="${2:-}"

    if [ -z "$title" ]; then
        echo "Использование: git-router.sh issue-create <заголовок> [описание]"
        exit 1
    fi

    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            local args=(issue create --title "$title")
            [ -n "$body" ] && args+=(--body "$body")
            gh "${args[@]}"
            ;;
        gitlab)
            check_tool glab
            local args=(issue create --title "$title")
            [ -n "$body" ] && args+=(--description "$body")
            glab "${args[@]}"
            ;;
    esac
    success "Issue создан: $title"
}

cmd_issue_list() {
    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github) check_tool gh; gh issue list ;;
        gitlab) check_tool glab; glab issue list ;;
    esac
}

cmd_issue_close() {
    local number="${1:-}"
    if [ -z "$number" ]; then
        echo "Использование: git-router.sh issue-close <номер>"
        exit 1
    fi

    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github) check_tool gh; gh issue close "$number" ;;
        gitlab) check_tool glab; glab issue close "$number" ;;
    esac
    success "Issue #$number закрыт"
}

# ============================================================================
#  КОМАНДЫ: Release
# ============================================================================

cmd_release_create() {
    local tag="${1:-}"
    local name="${2:-}"
    local notes="${3:-}"

    if [ -z "$tag" ]; then
        echo "Использование: git-router.sh release-create <тег> [название] [описание]"
        echo "Пример:        git-router.sh release-create v1.0.0 \"Релиз 1.0.0\" \"Описание\""
        exit 1
    fi

    check_git_repo
    local platform
    platform=$(detect_remote_platform)

    case "$platform" in
        github)
            check_tool gh
            local args=(release create "$tag")
            [ -n "$name" ] && args+=(--title "$name")
            [ -n "$notes" ] && args+=(--notes "$notes")
            gh "${args[@]}"
            ;;
        gitlab)
            check_tool glab
            local args=(release create "$tag")
            [ -n "$name" ] && args+=(--name "$name")
            [ -n "$notes" ] && args+=(--notes "$notes")
            glab "${args[@]}"
            ;;
    esac
    success "Release $tag создан"
}

# ============================================================================
#  КОМАНДЫ: Worktree
# ============================================================================

cmd_worktree_add() {
    local path="${1:-}"
    local branch="${2:-}"

    if [ -z "$path" ] || [ -z "$branch" ]; then
        echo "Использование: git-router.sh worktree-add <путь> <ветка>"
        echo "Пример:        git-router.sh worktree-add ../project-hotfix hotfix-branch"
        exit 1
    fi

    check_git_repo
    git worktree add "$path" "$branch"
    success "Worktree создан: $path (ветка: $branch)"
}

cmd_worktree_list() {
    check_git_repo
    git worktree list
}

cmd_worktree_remove() {
    local path="${1:-}"
    if [ -z "$path" ]; then
        echo "Использование: git-router.sh worktree-remove <путь>"
        exit 1
    fi

    check_git_repo
    confirm "Удалить worktree: $path?" || exit 1
    git worktree remove "$path"
    success "Worktree удалён: $path"
}

# ============================================================================
#  КОМАНДЫ: Submodule
# ============================================================================

cmd_submodule_add() {
    local url="${1:-}"
    local path="${2:-}"

    if [ -z "$url" ]; then
        echo "Использование: git-router.sh submodule-add <URL> [путь]"
        exit 1
    fi

    check_git_repo

    # Конвертация локального пути для совместимости с Windows/Git Bash
    # Если URL не содержит протокола (://) и не является SSH (git@),
    # и директория существует — конвертируем в абсолютный путь
    local is_local=0
    if [[ "$url" != *"://"* ]] && [[ "$url" != "git@"* ]]; then
        if [ -d "$url" ]; then
            is_local=1
            url=$(cd "$url" && pwd -W 2>/dev/null || pwd)
        fi
    fi

    # Для локальных путей — разрешаем file-протокол (заблокирован в Git 2.38+)
    local git_cmd="git"
    if [ "$is_local" = "1" ]; then
        git_cmd="git -c protocol.file.allow=always"
    fi

    if [ -n "$path" ]; then
        $git_cmd submodule add "$url" "$path"
    else
        $git_cmd submodule add "$url"
    fi
    success "Подмодуль добавлен: $url"
}

cmd_submodule_update() {
    check_git_repo
    git -c protocol.file.allow=always submodule update --init --recursive
    success "Подмодули обновлены"
}

cmd_submodule_list() {
    check_git_repo
    git submodule status
}

cmd_submodule_remove() {
    local path="${1:-}"
    if [ -z "$path" ]; then
        echo "Использование: git-router.sh submodule-remove <путь>"
        exit 1
    fi

    check_git_repo
    confirm "Удалить подмодуль: $path?" || exit 1
    git -c protocol.file.allow=always submodule deinit -f "$path"
    rm -rf ".git/modules/$path"
    git rm -f "$path"
    success "Подмодуль удалён: $path"
}

# ============================================================================
#  КОМАНДЫ: Обслуживание
# ============================================================================

cmd_gc() {
    check_git_repo
    info "Сборка мусора и сжатие объектов..."
    git gc --prune=now
    success "Сборка мусора выполнена"
}

cmd_fsck() {
    check_git_repo
    info "Проверка целостности репозитория..."
    git fsck 2>/dev/null
    success "Проверка завершена"
}

cmd_archive() {
    local format="${1:-tar}"
    local output="${2:-snapshot.tar}"

    check_git_repo
    info "Создание архива ($format) → $output"
    git archive --format="$format" --output="$output" HEAD
    success "Архив создан: $output"
}

cmd_bundle() {
    local output="${1:-repo.bundle}"

    check_git_repo
    info "Создание bundle: $output"
    git bundle create "$output" --all
    success "Bundle создан: $output"
}

cmd_sparse_set() {
    local dirs="${*:-}"
    if [ -z "$dirs" ]; then
        echo "Использование: git-router.sh sparse-set <директория1> <директория2> ..."
        exit 1
    fi

    check_git_repo
    git sparse-checkout init
    git sparse-checkout set $dirs
    success "Sparse checkout настроен на: $dirs"
}

cmd_notes_add() {
    local message="${1:-}"
    local commit="${2:-HEAD}"

    if [ -z "$message" ]; then
        echo "Использование: git-router.sh notes-add <сообщение> [хеш-коммита]"
        exit 1
    fi

    check_git_repo
    git notes add -m "$message" "$commit"
    success "Заметка добавлена к коммиту $commit"
}

# ============================================================================
#  КОМАНДЫ: Патчи
# ============================================================================

cmd_patch_create() {
    local count="${1:-1}"

    check_git_repo
    info "Создание патчей для последних $count коммитов..."
    git format-patch "-$count" -o /tmp/patches/ 2>/dev/null || {
        mkdir -p /tmp/patches
        git format-patch "-$count" -o /tmp/patches/
    }
    success "Патчи созданы в /tmp/patches/"
}

cmd_patch_apply() {
    local patch_file="${1:-}"

    if [ -z "$patch_file" ]; then
        echo "Использование: git-router.sh patch-apply <файл.patch>"
        exit 1
    fi

    check_git_repo
    git apply --check "$patch_file" && {
        git am "$patch_file"
        success "Патч применён как коммит: $patch_file"
    } || {
        warn "Проверка не прошла. Попытка простого применения..."
        git apply "$patch_file" || {
            error "Не удалось применить патч."
            exit 1
        }
        success "Патч применён (без коммита)"
    }
}

# ============================================================================
#  КОМАНДА: Версия
# ============================================================================

cmd_version() {
    echo "git-router.sh $ROUTER_VERSION"
}

# ============================================================================
#  Справка (HELP)
# ============================================================================

show_help() {
    local cmd="${1:-}"

    if [ -n "$cmd" ]; then
        case "$cmd" in
            config)        echo "Настройка git: имя, email и базовые параметры"; echo "Использование: config <Имя> <email>" ;;
            init)          echo "Создание локального и удалённого репозитория"; echo "Использование: init <имя> [public|private] [github|gitlab]" ;;
            clone)         echo "Клонирование репозитория"; echo "Использование: clone <URL>" ;;
            remote-add)    echo "Добавление remote"; echo "Использование: remote-add [name] <URL>" ;;
            add)           echo "Добавление файлов в индекс"; echo "Использование: add [файлы...]" ;;
            unstage)       echo "Убрать файлы из индекса"; echo "Использование: unstage [файлы...]" ;;
            commit)        echo "Коммит изменений"; echo "Использование: commit <сообщение>" ;;
            push)          echo "Push на remote"; echo "Использование: push [--force]" ;;
            pull)          echo "Pull с remote"; echo "Использование: pull [--rebase]" ;;
            fetch)         echo "Fetch всех remote"; echo "Использование: fetch" ;;
            status)        echo "Показать статус"; echo "Использование: status" ;;
            undo-last)     echo "Отмена последнего коммита (soft)"; echo "Использование: undo-last" ;;
            undo-hard)     echo "Отмена последнего коммита (hard, необратимо)"; echo "Использование: undo-hard" ;;
            revert)        echo "Безопасная отмена коммита (новый коммит)"; echo "Использование: revert [хеш]" ;;
            restore-file)  echo "Восстановление файла из HEAD"; echo "Использование: restore-file <файл>" ;;
            file-at-date)  echo "Версия файла на дату"; echo "Использование: file-at-date <дата> <файл>" ;;
            branch-create) echo "Создать ветку"; echo "Использование: branch-create <имя>" ;;
            branch-switch) echo "Переключиться на ветку"; echo "Использование: branch-switch <имя>" ;;
            branch-list)   echo "Список веток"; echo "Использование: branch-list" ;;
            branch-delete) echo "Удалить ветку"; echo "Использование: branch-delete <имя> [--force]" ;;
            branch-rename) echo "Переименовать ветку"; echo "Использование: branch-rename <старое> <новое>" ;;
            merge)         echo "Слияние веток"; echo "Использование: merge <ветка> [--no-ff|--ff-only|--squash]" ;;
            merge-abort)   echo "Отмена слияния"; echo "Использование: merge-abort" ;;
            rebase)        echo "Rebase текущей ветки"; echo "Использование: rebase [база]" ;;
            rebase-abort)  echo "Отмена rebase"; echo "Использование: rebase-abort" ;;
            rebase-interactive) echo "Интерактивный rebase"; echo "Использование: rebase-interactive [количество]" ;;
            resolve-conflict) echo "Помощь при конфликтах"; echo "Использование: resolve-conflict" ;;
            stash)         echo "Операции со stash"; echo "Использование: stash [save|pop|apply|list|drop|clear|show]" ;;
            cherry-pick)   echo "Cherry-pick коммита"; echo "Использование: cherry-pick <хеш>" ;;
            tag)           echo "Создание аннотированного тега"; echo "Использование: tag <имя> [сообщение]" ;;
            tag-list)      echo "Список тегов"; echo "Использование: tag-list" ;;
            log)           echo "Показать лог"; echo "Использование: log [количество]" ;;
            log-detailed)  echo "Подробный лог с авторами и датами"; echo "Использование: log-detailed" ;;
            diff)          echo "Показать diff"; echo "Использование: diff [target|--cached]" ;;
            blame)         echo "Кто изменил строки"; echo "Использование: blame <файл>" ;;
            reflog)        echo "Журнал перемещений HEAD"; echo "Использование: reflog" ;;
            bisect-start)  echo "Начать bisect"; echo "Использование: bisect-start" ;;
            bisect-reset)  echo "Завершить bisect"; echo "Использование: bisect-reset" ;;
            pr-create)     echo "Создать PR/MR"; echo "Использование: pr-create --title <заголовок> --base <ветка> [--draft]" ;;
            pr-list)       echo "Список PR/MR"; echo "Использование: pr-list" ;;
            pr-merge)      echo "Слить PR/MR"; echo "Использование: pr-merge <номер> [--squash|--merge|--rebase]" ;;
            pr-close)      echo "Закрыть PR/MR"; echo "Использование: pr-close <номер>" ;;
            pr-review)      echo "Review PR/MR"; echo "Использование: pr-review <номер> [approve|request-changes|comment]" ;;
            pr-checkout)   echo "Checkout ветки PR/MR"; echo "Использование: pr-checkout <номер>" ;;
            issue-create)  echo "Создать issue"; echo "Использование: issue-create <заголовок> [описание]" ;;
            issue-list)    echo "Список issues"; echo "Использование: issue-list" ;;
            issue-close)   echo "Закрыть issue"; echo "Использование: issue-close <номер>" ;;
            release-create) echo "Создать release"; echo "Использование: release-create <тег> [название] [описание]" ;;
            worktree-add)  echo "Создать worktree"; echo "Использование: worktree-add <путь> <ветка>" ;;
            worktree-list) echo "Список worktrees"; echo "Использование: worktree-list" ;;
            worktree-remove) echo "Удалить worktree"; echo "Использование: worktree-remove <путь>" ;;
            submodule-add) echo "Добавить подмодуль"; echo "Использование: submodule-add <URL> [путь]" ;;
            submodule-update) echo "Обновить подмодули"; echo "Использование: submodule-update" ;;
            submodule-list) echo "Список подмодулей"; echo "Использование: submodule-list" ;;
            submodule-remove) echo "Удалить подмодуль"; echo "Использование: submodule-remove <путь>" ;;
            gc)            echo "Сборка мусора"; echo "Использование: gc" ;;
            fsck)          echo "Проверка целостности"; echo "Использование: fsck" ;;
            archive)       echo "Создать архив"; echo "Использование: archive [tar|zip] [имя-файла]" ;;
            bundle)        echo "Создать bundle"; echo "Использование: bundle [имя-файла]" ;;
            sparse-set)    echo "Настроить sparse checkout"; echo "Использование: sparse-set <дир1> <дир2>..." ;;
            notes-add)     echo "Добавить заметку к коммиту"; echo "Использование: notes-add <сообщение> [хеш]" ;;
            patch-create)  echo "Создать патчи"; echo "Использование: patch-create [количество]" ;;
            patch-apply)   echo "Применить патч"; echo "Использование: patch-apply <файл.patch>" ;;
            help)          echo "Показать справку"; echo "Использование: help [команда]" ;;
            *)             echo "Неизвестная команда: $cmd. Выполните: help" ;;
        esac
        exit 0
    fi

    cat << 'HELP_EOF'
=============================================================================
  git-router.sh — Маршрутизатор команд Git / GitHub / GitLab
  Версия: 1.0.0
=============================================================================

ИСПОЛЬЗОВАНИЕ:
  bash git-router.sh <команда> [аргументы...]
  bash git-router.sh help <команда>          # справка по команде

КОМАНДЫ:

  --- Настройка и инициализация ---
  config <Имя> <email>                       Настроить git (имя, email, алиасы)
  init <имя> [public|private] [github|gitlab] Создать локальный + удалённый репо
  clone <URL>                                 Клонировать репозиторий
  remote-add [name] <URL>                     Добавить remote

  --- Базовый рабочий цикл ---
  add [файлы...]                              Добавить в индекс
  unstage [файлы...]                          Убрать из индекса
  commit <сообщение>                          Закоммитить (Conventional Commits)
  push [--force]                              Push на remote
  pull [--rebase]                             Pull с remote
  fetch                                       Fetch всех remote с prune
  status                                      Показать статус

  --- Восстановление и отмена ---
  undo-last                                   Отменить последний коммит (soft)
  undo-hard                                   Отменить последний коммит (hard, ОПАСНО)
  revert [хеш]                                Безопасная отмена (новый коммит)
  restore-file <файл>                         Восстановить файл из HEAD
  file-at-date <дата> <файл>                  Версия файла на дату

  --- Ветки ---
  branch-create <имя>                         Создать и переключиться
  branch-switch <имя>                         Переключиться
  branch-list                                 Список веток
  branch-delete <имя> [--force]               Удалить ветку
  branch-rename <старое> <новое>              Переименовать ветку

  --- Слияние и rebase ---
  merge <ветка> [--no-ff|--ff-only|--squash]  Слить ветку
  merge-abort                                 Отменить слияние
  rebase [база]                               Rebase текущей ветки
  rebase-abort                                Отменить rebase
  rebase-interactive [количество]             Интерактивный rebase
  resolve-conflict                            Помощь при конфликтах

  --- Stash ---
  stash [save|pop|apply|list|drop|clear|show] Операции со stash

  --- Точечные операции ---
  cherry-pick <хеш>                           Cherry-pick коммита
  tag <имя> [сообщение]                       Создать аннотированный тег
  tag-list                                    Список тегов

  --- Лог и расследование ---
  log [количество]                            Компактный лог
  log-detailed                                Подробный лог
  diff [target|--cached]                      Показать diff
  blame <файл>                                Кто и когда изменил строки
  reflog                                      Журнал перемещений HEAD
  bisect-start                                Начать бинарный поиск бага
  bisect-reset                                Завершить bisect

  --- Pull Requests / Merge Requests ---
  pr-create --title <заголовок> --base <ветка> [--draft]
  pr-list                                     Список PR/MR
  pr-merge <номер> [--squash|--merge|--rebase]
  pr-close <номер>                            Закрыть PR/MR
  pr-review <номер> [approve|request-changes|comment]
  pr-checkout <номер>                         Checkout ветки PR/MR

  --- Issues ---
  issue-create <заголовок> [описание]
  issue-list                                  Список issues
  issue-close <номер>                         Закрыть issue

  --- Releases ---
  release-create <тег> [название] [описание]

  --- Worktree ---
  worktree-add <путь> <ветка>
  worktree-list                                Список worktrees
  worktree-remove <путь>

  --- Submodule ---
  submodule-add <URL> [путь]
  submodule-update                            Обновить все подмодули
  submodule-list                              Список подмодулей
  submodule-remove <путь>

  --- Патчи и архивы ---
  patch-create [количество]                   Создать патчи для N коммитов
  patch-apply <файл.patch>                    Применить патч

  --- Обслуживание ---
  gc                                          Сборка мусора
  fsck                                        Проверка целостности
  archive [tar|zip] [имя]                     Создать архив
  bundle [имя]                                Создать bundle
  sparse-set <дир1> <дир2>...                 Sparse checkout
  notes-add <сообщение> [хеш]                 Заметка к коммиту

  --- Справка ---
  help [команда]                              Эта справка

ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ:
  AUTO_CONFIRM=yes     Подтверждать деструктивные операции автоматически

ПРИМЕРЫ:
  bash git-router.sh config "Иван Иванов" ivan@example.com
  bash git-router.sh init my-project private github
  bash git-router.sh commit "feat(auth): добавлена регистрация"
  bash git-router.sh undo-last
  bash git-router.sh stash save "WIP: эксперимент"
  bash git-router.sh pr-create --title "Feature auth" --base main --draft
  bash git-router.sh rebase main
  bash git-router.sh file-at-date "2025-06-15" src/config.ts

=============================================================================
HELP_EOF
}

# ============================================================================
#  Главная точка входа (dispatch)
# ============================================================================

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        # Настройка и инициализация
        config)            cmd_config "$@" ;;
        init)              cmd_init "$@" ;;
        clone)             cmd_clone "$@" ;;
        remote-add)       cmd_remote_add "$@" ;;
        remote)           cmd_remote_add "$@" ;;

        # Базовый рабочий цикл
        add)               cmd_add "$@" ;;
        unstage)          cmd_unstage "$@" ;;
        commit)           cmd_commit "$@" ;;
        push)             cmd_push "$@" ;;
        pull)             cmd_pull "$@" ;;
        fetch)            cmd_fetch "$@" ;;
        status)           cmd_status "$@" ;;

        # Восстановление и отмена
        undo-last)        cmd_undo_last "$@" ;;
        undo-hard)        cmd_undo_hard "$@" ;;
        undo)             cmd_undo_last "$@" ;;
        revert)           cmd_revert "$@" ;;
        restore-file)     cmd_restore_file "$@" ;;
        restore)          cmd_restore_file "$@" ;;
        file-at-date)     cmd_file_at_date "$@" ;;

        # Ветки
        branch-create)    cmd_branch_create "$@" ;;
        bc)               cmd_branch_create "$@" ;;
        branch-switch)    cmd_branch_switch "$@" ;;
        bs)               cmd_branch_switch "$@" ;;
        checkout)         cmd_branch_switch "$@" ;;
        branch-list)      cmd_branch_list "$@" ;;
        branches)         cmd_branch_list "$@" ;;
        branch-delete)    cmd_branch_delete "$@" ;;
        branch-rename)    cmd_branch_rename "$@" ;;

        # Слияние и rebase
        merge)            cmd_merge "$@" ;;
        merge-abort)      cmd_merge_abort "$@" ;;
        rebase)           cmd_rebase "$@" ;;
        rebase-abort)     cmd_rebase_abort "$@" ;;
        rebase-interactive) cmd_rebase_interactive "$@" ;;
        resolve-conflict) cmd_resolve_conflict "$@" ;;
        conflict)         cmd_resolve_conflict "$@" ;;

        # Stash
        stash)            cmd_stash "$@" ;;

        # Точечные операции
        cherry-pick)      cmd_cherry_pick "$@" ;;
        tag)              cmd_tag "$@" ;;
        tag-list)         cmd_tag_list "$@" ;;
        tags)             cmd_tag_list "$@" ;;

        # Лог и расследование
        log)              cmd_log "$@" ;;
        log-detailed)     cmd_log_detailed "$@" ;;
        diff)             cmd_diff "$@" ;;
        blame)            cmd_blame "$@" ;;
        reflog)           cmd_reflog "$@" ;;
        bisect-start)     cmd_bisect_start "$@" ;;
        bisect-reset)     cmd_bisect_reset "$@" ;;

        # Pull Requests / Merge Requests
        pr-create)        cmd_pr_create "$@" ;;
        pr-list)          cmd_pr_list "$@" ;;
        pr-merge)         cmd_pr_merge "$@" ;;
        pr-close)         cmd_pr_close "$@" ;;
        pr-review)        cmd_pr_review "$@" ;;
        pr-checkout)      cmd_pr_checkout "$@" ;;

        # Issues
        issue-create)     cmd_issue_create "$@" ;;
        issue-list)       cmd_issue_list "$@" ;;
        issue-close)      cmd_issue_close "$@" ;;

        # Releases
        release-create)   cmd_release_create "$@" ;;
        release)          cmd_release_create "$@" ;;

        # Worktree
        worktree-add)     cmd_worktree_add "$@" ;;
        worktree-list)    cmd_worktree_list "$@" ;;
        worktree-remove)  cmd_worktree_remove "$@" ;;

        # Submodule
        submodule-add)    cmd_submodule_add "$@" ;;
        submodule-update) cmd_submodule_update "$@" ;;
        submodule-list)   cmd_submodule_list "$@" ;;
        submodule-remove) cmd_submodule_remove "$@" ;;

        # Патчи и архивы
        patch-create)     cmd_patch_create "$@" ;;
        patch-apply)      cmd_patch_apply "$@" ;;

        # Обслуживание
        gc)               cmd_gc "$@" ;;
        fsck)             cmd_fsck "$@" ;;
        archive)          cmd_archive "$@" ;;
        bundle)           cmd_bundle "$@" ;;
        sparse-set)       cmd_sparse_set "$@" ;;
        notes-add)        cmd_notes_add "$@" ;;

        # Справка
        help|h|--help|-h) show_help "$@" ;;
        version|--version|-V) cmd_version ;;
        *)
            error "Неизвестная команда: $command"
            echo "Выполните: bash git-router.sh help"
            exit 1
            ;;
    esac
}

main "$@"
