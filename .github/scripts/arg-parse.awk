@include "getopt.awk"

BEGIN {
    Opterr = 1;
    Optind = 1;
    results["a"]="";delete results;
}
{
    for(i = 1;i <= NF;i += 1) {
        F[i] = $i;
    }
    parsed_option = getopt(NF, F, short_options, long_options);
    do {
        if (parsed_option == "?") {
            printf("::debug::Warning! Unknown command line option!\n") > "/dev/stderr";
            printf("::debug::option = <%s>, value = <%s>\n", parsed_option, Optarg) > "/dev/stderr";
        } else {
            gsub(/-/, "_", parsed_option)
            if (!Optreq && Optarg == "") {
                if (Optinv) {
                    Optarg = "false";
                } else {
                    Optarg = "true";
                }
            } else if (Optreq && Optarg == "") {
                printf("::error::Failed to parse command line option!\n") > "/dev/stderr";
                printf("::error::Bad option \"%s\" (value required)!\n", Optopt) > "/dev/stderr";
                exit 1;
            }
            results[toupper(parsed_option)]=(Optarg);
        }
        parsed_option = getopt(NF, F, options, long_options);
    } while (parsed_option != -1);
    exit 0;
}
END {
    for(key in results) {
        printf("%s=\"%s\"\n", key, results[key]);
    }
}
