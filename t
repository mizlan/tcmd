#!/bin/bash

main() {
    target="$(command ls -1tp -- *.{cpp,py,java,c} 2>/dev/null | command sed 1q)"
    printf -- "| using target %s\n" "${target}"
    base="${target%.*}"
    printf -- "| using base %s\n" "${base}"
    extension="${target##*.}"
    printf -- "| using extension %s\n" "${extension}"

    check "$@"
    run
}

check() {
    local OPTIND opt
    while getopts ":i:" opt; do
        case "$opt" in
            i)
                printf "| input file %s\n" "$opt"
                inputfile="$OPTARG"
                ;;
            \?)
                print_help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
    if [ "$inputfile" = "" ]; then
        printf -- '| no input file given\n'
    elif [ ! -f "$inputfile" ]; then
        printf -- '| %s does not exist, resorting to stdin\n' "$inputfile"
        inputfile=""
    else
        printf -- "| inputfile is %s\n" "${inputfile}"
    fi
}

run() {
    case "$extension" in
        c)
            # gcc "$target" && ./a.out
            ;;
        cpp)
            g++-10 -DFEAST_LOCAL -std=c++11 "$target" || exit $?
            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;
        java)
            javac "$target" && java "$base"
            ;;
        py)
            python "$target"
            ;;
        *)
            printf -- "no good procedure found\n"
            ;;
    esac
}

print_help() {
    printf -- '-i <input file>\n'
}

main "$@"
