#!/bin/bash

EFF_TCACHE_DIR="${TCACHE_DIR:-$HOME/.tcmd-cache}"
mkdir -p "$EFF_TCACHE_DIR"

main() {
    target="$(command ls -1tp -- *.{cpp,py,java,c,ml} 2>/dev/null | command sed 1q)"
    check "$@"

    verbose_print "| using target %s\n" "${target}"
    base="${target%.*}"
    verbose_print "| using base %s\n" "${base}"
    extension="${target##*.}"
    verbose_print "| using extension %s\n" "${extension}"
    if [ "$inputfile" = "" ]; then
        verbose_print '| no input file given\n'
    elif [ ! -f "$inputfile" ]; then
        verbose_print '| %s does not exist, resorting to stdin\n' "$inputfile"
        inputfile=""
    else
        verbose_print "| inputfile is %s\n" "${inputfile}"
    fi

    run
}

check() {
    local OPTIND opt
    while getopts ":vi:" opt; do
        case "$opt" in
            i)
                printf "| input file %s\n" "$opt"
                inputfile="$OPTARG"
                ;;
            v)
                VERBOSE="verbose"
                ;;
            \?)
                print_help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
}

run() {
    case "$extension" in
        c)
            filehash="$(md5 -q ${target})"
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "| hash is %s\n" "$filehash"
            if [ -e "${exppath}" ]; then
                verbose_print "| found cached @ %s\n" "$exppath"
                cp "$exppath" ./a.out
            else
                gcc "$target" || exit $?
                verbose_print "| caching @ %s\n" "$exppath"
                cp ./a.out "$exppath"
            fi

            verbose_print "| running executable\n"
            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;

        cpp)
            filehash="$(md5 -q ${target})"
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "| hash is %s\n" "$filehash"
            if [ -e "${exppath}" ]; then
                verbose_print "| found cached @ %s\n" "$exppath"
                cp "$exppath" ./a.out
            else
                g++-10 -DFEAST_LOCAL -std=c++11 "$target" || exit $?
                verbose_print "| caching @ %s\n" "$exppath"
                cp ./a.out "$exppath"
            fi

            verbose_print "| running executable\n"
            if [ -n "$inputfile" ]; then
                ./a.out < "$inputfile"
            else
                ./a.out
            fi
            ;;

        java)
            filehash=$(md5sum "${target}" | awk '{ print $1 }')
            exppath="${EFF_TCACHE_DIR}/${filehash}"
            verbose_print "| hash is %s\n" "$filehash"
            if [ -e "${exppath}" ]; then
                verbose_print "| found cached @ %s\n" "$exppath"
                cp "$exppath" "${base}.class"
            else
                javac "$target" || exit $?
                verbose_print "| caching @ %s\n" "$exppath"
                cp "${base}.class" "$exppath"
            fi

            verbose_print "| running executable\n"
            if [ -n "$inputfile" ]; then
                java "$base" < "$inputfile"
            else
                java "$base"
            fi
            ;;

        py)
            # no caching options available
            python "$target"
            ;;

        *)
            printf -- "[!] no good procedure found, or not implemented: extension %s\n" "$extension" 1>&2
            exit 1;
            ;;
    esac
}

print_help() {
    printf -- 'usage:\n'
    printf -- '  -i <input file>\n'
    printf -- '  -v (verbose)\n'
}

verbose_print() {
    if [ -n "$VERBOSE" ]; then
        printf -- "$@"
    fi
}

main "$@"
