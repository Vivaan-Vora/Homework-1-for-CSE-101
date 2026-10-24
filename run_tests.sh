#!/usr/bin/env bash
# Local test runner for CSE 101 Programming Assignment 1.
#
#   ./run_tests.sh              build, then run every test
#   ./run_tests.sh 05           run only tests whose name contains "05"
#   ./run_tests.sh filter       run only tests whose name contains "filter"
#   ./run_tests.sh --list       list all tests without running them
#
# Each test is a folder in tests/ containing:
#   input.txt       the input file (left out when the test checks a missing file)
#   cmd             the arguments passed to ./LinkedList
#   expected.txt    the exact expected standard output
#   expected_exit   (optional) the expected exit status; 0 if missing
#   expected_stderr (optional) the exact expected standard error; not checked if missing
#   description     what the test checks
#
# Your program's output for each test is saved in test_output/<test>.txt,
# and its standard error in test_output/<test>.stderr.txt.
# These are the visible tests only. Gradescope also runs hidden tests.
#
# Works in a Codespace, on macOS (including its built-in bash 3.2), and on
# Windows in WSL or Git Bash.

cd "$(dirname "$0")" || exit 1

TIME_LIMIT=5
MAX_DIFF_LINES=40

# Stop a test that runs too long. macOS has no `timeout` command, so fall back
# to gtimeout (Homebrew coreutils) or perl, which every Mac and Git Bash has.
if command -v timeout >/dev/null 2>&1; then
    LIMIT="timeout $TIME_LIMIT"; TIMEOUT_CODE=124
elif command -v gtimeout >/dev/null 2>&1; then
    LIMIT="gtimeout $TIME_LIMIT"; TIMEOUT_CODE=124
elif command -v perl >/dev/null 2>&1; then
    LIMIT="perl -e 'alarm shift; exec @ARGV' $TIME_LIMIT"; TIMEOUT_CODE=142
else
    LIMIT=""; TIMEOUT_CODE=124
    echo "Note: no timeout command found, so tests run without a time limit."
fi

if [ -t 1 ]; then
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

tests=()
for dir in tests/*/; do
    tests+=("$(basename "$dir")")
done

if [ "$1" = "--list" ]; then
    for t in "${tests[@]}"; do
        printf "%-28s %s\n" "$t" "$(cat "tests/$t/description" 2>/dev/null)"
    done
    exit 0
fi

filter="$1"

echo "${BOLD}Building...${RESET}"
if ! make --no-print-directory all; then
    echo
    echo "${RED}Build failed. Fix the errors above, then run the tests again.${RESET}"
    exit 1
fi
echo

mkdir -p test_output
passed=0; failed=0; ran=0
# Per-part totals, kept in parallel arrays (bash 3.2 has no associative arrays).
part_names=(); part_pass=(); part_total=()

for t in "${tests[@]}"; do
    if [ -n "$filter" ] && [[ "$t" != *"$filter"* ]]; then continue; fi
    dir="tests/$t"
    ran=$((ran + 1))

    part="$(tr -d '\r' < "$dir/part" 2>/dev/null)"
    [ -n "$part" ] || part="Other"
    pi=0
    while [ $pi -lt ${#part_names[@]} ] && [ "${part_names[$pi]}" != "$part" ]; do
        pi=$((pi + 1))
    done
    if [ $pi -eq ${#part_names[@]} ]; then
        part_names[$pi]="$part"; part_pass[$pi]=0; part_total[$pi]=0
    fi
    part_total[$pi]=$((part_total[$pi] + 1))

    args="$(tr -d '\r\n' < "$dir/cmd")"
    expected_exit="$(cat "$dir/expected_exit" 2>/dev/null || echo 0)"
    out="test_output/$t.txt"
    err="test_output/$t.stderr.txt"

    # Run from inside the test folder so "input.txt" refers to that test's file.
    (cd "$dir" && eval "$LIMIT ../../LinkedList $args") > "$out" 2> "$err"
    code=$?

    problem=""
    if [ -n "$LIMIT" ] && [ $code -eq $TIMEOUT_CODE ]; then
        problem="timed out after ${TIME_LIMIT}s (infinite loop?)"
    elif [ $code -ge 128 ]; then
        problem="crashed (signal $((code - 128)); often a null or deleted pointer)"
    elif [ "$code" != "$expected_exit" ]; then
        problem="exit status $code, expected $expected_exit"
    elif ! diff -q --strip-trailing-cr "$dir/expected.txt" "$out" >/dev/null; then
        problem="output differs from expected"
    elif [ -f "$dir/expected_stderr" ] && \
         ! diff -q --strip-trailing-cr "$dir/expected_stderr" "$err" >/dev/null; then
        problem="standard error differs from expected"
    fi

    if [ -z "$problem" ]; then
        passed=$((passed + 1))
        part_pass[$pi]=$((part_pass[$pi] + 1))
        echo "${GREEN}PASS${RESET}  $t"
    else
        failed=$((failed + 1))
        echo "${RED}FAIL${RESET}  $t: $problem"
        echo "      $(cat "$dir/description" 2>/dev/null)"
        echo "      command: ./LinkedList $args"
        if [ "$problem" = "output differs from expected" ]; then
            echo "      ${YELLOW}--- lines starting with - are expected, + are your output${RESET}"
            diff -u --strip-trailing-cr --label "expected" --label "your output" \
                "$dir/expected.txt" "$out" | head -n $MAX_DIFF_LINES | sed 's/^/      /'
        elif [ "$problem" = "standard error differs from expected" ]; then
            echo "      ${YELLOW}--- lines starting with - are expected, + are what your program printed to std::cerr${RESET}"
            diff -u --strip-trailing-cr --label "expected" --label "your standard error" \
                "$dir/expected_stderr" "$err" | head -n $MAX_DIFF_LINES | sed 's/^/      /'
        fi
        echo
    fi
done

if [ $ran -eq 0 ]; then
    echo "No tests match \"$filter\". Use ./run_tests.sh --list to see test names."
    exit 1
fi

echo
echo "${BOLD}Summary${RESET}"
pi=0
while [ $pi -lt ${#part_names[@]} ]; do
    printf "  %-22s %d/%d passed\n" "${part_names[$pi]}" "${part_pass[$pi]}" "${part_total[$pi]}"
    pi=$((pi + 1))
done
echo "  ----------------------------------"
printf "  %-22s %d/%d passed\n" "Total" "$passed" "$ran"
echo
if [ $failed -eq 0 ]; then
    if [ -n "$filter" ]; then
        echo "${GREEN}${BOLD}All $ran selected tests passed.${RESET} Run ./run_tests.sh with no arguments to run every test."
    else
        echo "${GREEN}${BOLD}All $ran tests passed!${RESET}"
        echo "Before submitting: remove any debug prints, fill in citations.md, and push your work."
    fi
else
    echo "${RED}${BOLD}$failed of $ran tests failed.${RESET} Scroll up to see the differences for each failed test."
fi
echo "Your outputs are saved in test_output/. Gradescope also runs hidden tests."

[ $failed -eq 0 ]
