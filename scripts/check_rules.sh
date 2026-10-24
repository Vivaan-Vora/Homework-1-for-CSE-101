#!/usr/bin/env bash
# Checks the assignment rules. Run automatically by `make`.
#
#   scripts/check_rules.sh            check source files (before compiling)
#   scripts/check_rules.sh --binary   check the compiled LinkedList program
#
# Exit status 0 means every rule passed.

cd "$(dirname "$0")/.." || exit 1

RED=""; GREEN=""; RESET=""
if [ -t 1 ]; then RED=$'\033[31m'; GREEN=$'\033[32m'; RESET=$'\033[0m'; fi

status=0
fail() { echo "${RED}RULE CHECK FAILED:${RESET} $1"; status=1; }

STUDENT_FILES="main.cpp movies.cpp"
ALLOWED_HEADERS="string iostream fstream sstream cstring cstdlib"
CONTAINERS="vector list forward_list deque array map multimap set multiset \
unordered_map unordered_set priority_queue stack queue"
LIBRARY_SORTS="sort stable_sort partial_sort nth_element"
REQUIRED_FUNCTIONS="appendNode comesBefore sortList removeDuplicates printList printFiltered clearList"

# Fingerprint of the provided header. It must not be changed.
HEADER_SHA256="65abfc9362addf41c9284d3272735c0404bc03375ee5aa510c21c5b6f21b51ba"

# ---------------------------------------------------------------- binary check
if [ "$1" = "--binary" ]; then
    # On Windows the compiler names the program LinkedList.exe.
    program=LinkedList
    [ -f "$program" ] || program=LinkedList.exe
    if command -v nm >/dev/null 2>&1 && [ -f "$program" ]; then
        # __cxx11:: appears in GCC's names and __1:: in the Mac compiler's (libc++).
        if nm -C "$program" 2>/dev/null | grep -Eq \
            'std::(__cxx11::|__1::)?(vector|list|deque|map|set|multimap|multiset|unordered_map|unordered_set|forward_list|array)<|std::(__1::)?(sort|stable_sort|__sort|__introsort_loop)\b|[^a-z_]qsort'; then
            fail "LinkedList contains standard containers or library sort functions."
        fi
    fi
    exit $status
fi

# ---------------------------------------------------------------- source checks
# 1. Required files
for f in main.cpp movies.h movies.cpp; do
    [ -f "$f" ] || fail "required file '$f' is missing."
done
[ $status -eq 0 ] || exit 1

# 2. The provided header must be unchanged
# Older Macs have shasum but not sha256sum.
if command -v sha256sum >/dev/null 2>&1; then
    actual="$(tr -d '\r' < movies.h | sha256sum | cut -d' ' -f1)"
else
    actual="$(tr -d '\r' < movies.h | shasum -a 256 | cut -d' ' -f1)"
fi
if [ "$actual" != "$HEADER_SHA256" ]; then
    fail "movies.h has been modified. Do not add helper declarations there: declare and define helpers as static functions in main.cpp or movies.cpp instead. Restore the header with:  git checkout -- movies.h"
fi

# 3. No other source files (only main.cpp and movies.cpp are compiled)
extra="$(find . -maxdepth 1 -type f \( -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' \
         -o -name '*.c' -o -name '*.h' -o -name '*.hpp' \) \
         ! -name main.cpp ! -name movies.cpp ! -name movies.h | sed 's|^\./||' | sort)"
if [ -n "$extra" ]; then
    fail "extra source files found: $(echo $extra). Put all of your code in main.cpp and movies.cpp."
fi

# Remove comments and string literals so they are not mistaken for code.
strip_code() {
    sed -e 's://.*$::' "$1" |
    perl -0777 -pe 's{/\*.*?\*/}{}gs; s{"(?:\\.|[^"\\])*"}{""}g'
}

for file in $STUDENT_FILES; do
    code="$(strip_code "$file")"
    raw_includes="$(sed -e 's://.*$::' "$file" | perl -0777 -pe 's{/\*.*?\*/}{}gs' |
                    grep -E '^[[:space:]]*#[[:space:]]*include')"

    # 4. Includes must be on the allowed list
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if [[ "$line" =~ \<([^>]+)\> ]]; then
            hdr="${BASH_REMATCH[1]}"
            case " $ALLOWED_HEADERS " in
                *" $hdr "*) ;;
                *) fail "$file includes <$hdr>, which is not allowed." ;;
            esac
        elif [[ "$line" =~ \"([^\"]+)\" ]]; then
            [ "${BASH_REMATCH[1]}" = "movies.h" ] || \
                fail "$file includes \"${BASH_REMATCH[1]}\"; only \"movies.h\" may be included."
        else
            fail "$file uses an #include form that is not allowed: $line"
        fi
    done <<< "$raw_includes"

    # 5. No standard containers or library sorting
    for name in $CONTAINERS; do
        if grep -Eq "\b(std::)?$name[[:space:]]*<" <<< "$code"; then
            fail "$file uses the standard container '$name'. Build your own linked list."
        fi
    done
    for name in $LIBRARY_SORTS; do
        if grep -Eq "std::$name\b" <<< "$code"; then
            fail "$file uses std::$name. Write your own sort."
        fi
    done
    if grep -Eq '\bqsort[[:space:]]*\(' <<< "$code"; then
        fail "$file uses qsort. Write your own sort."
    fi
done

# 6. main() is in main.cpp, and every required function is defined in movies.cpp
if ! grep -Eq '\bint[[:space:]]+main[[:space:]]*\(' <<< "$(strip_code main.cpp)"; then
    fail "main.cpp does not define main()."
fi
movies_code="$(strip_code movies.cpp)"
for fn in $REQUIRED_FUNCTIONS; do
    if ! grep -Eq "\b$fn[[:space:]]*\(" <<< "$movies_code"; then
        fail "movies.cpp does not define $fn(). Keep the exact name and parameters from movies.h."
    fi
done

if [ $status -eq 0 ]; then
    echo "${GREEN}Rule check passed.${RESET}"
else
    echo "Allowed headers: $ALLOWED_HEADERS, and \"movies.h\"."
fi
exit $status
