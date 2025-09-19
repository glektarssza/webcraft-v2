# getopt.awk --- Do C library getopt(3) function in awk
#                Also supports long options.
#
# Arnold Robbins, arnold@skeeve.com, Public Domain
#
# Initial version: March, 1991
# Revised: May, 1993
# Long options added by Greg Minshall, January 2020

# External variables:
#    Optind -- index in ARGV of first nonoption argument
#    Optarg -- string value of argument to current option
#    Opterr -- if nonzero, print our own diagnostic
#    Optopt -- current option letter
#    Optreq -- current option requires input
#    Optinv -- current option is inverted

# Returns:
#    -1     at end of options
#    "?"    for unrecognized option
#    <s>    a string representing the current option

# Private Data:
#    _opti  -- index in multiflag option, e.g., -abc
#    _optsq -- whether the current option is single quoted
#    _optdq -- whether the current option is double quoted
function getopt(argc, argv, options, longopts, thisopt, i, j)
{
    if (length(options) == 0 && length(longopts) == 0)
        return -1                # no options given
    if (argv[Optind] == "--") {  # all done
        Optind++
        _opti = 0
        return -1
    } else if (argv[Optind] !~ /^-[^:[:space:]]/) {
        _opti = 0
        return -1
    }
    if (argv[Optind] !~ /^--/) {        # if this is a short option
        if (_opti == 0)
            _opti = 2
        thisopt = substr(argv[Optind], _opti, 1)
        Optopt = thisopt
        Optinv = 0
        i = index(options, thisopt)
        if (i == 0) {
            if (Opterr) {
                printf("%c -- invalid option\n", thisopt) > "/dev/stderr"
            }
            if (_opti >= length(argv[Optind])) {
                Optind++
                _opti = 0
            } else
                _opti++
            return "?"
        }
        if (substr(options, i + 1, 1) == ":") {
            Optreq = 1
            # get option argument
            if (length(substr(argv[Optind], _opti + 1)) > 0)
                Optarg = substr(argv[Optind], _opti + 1)
            else
                Optarg = argv[++Optind]
            _opti = 0
        } else if (substr(options, i + 1, 1) == "!") {
            # get option argument
            if (length(substr(argv[Optind], _opti + 1)) > 0)
                Optarg = substr(argv[Optind], _opti + 1)
            else
                Optarg = argv[++Optind]
            if (match(Optarg, /^no-/)) {
                Optarg = substr(Optarg, 4)
            }
            _opti = 0
        } else {
            Optreq = 0
            Optarg = ""
        }
        if (_opti == 0 || _opti >= length(argv[Optind])) {
            Optind++
            _opti = 0
        } else
            _opti++
        return thisopt
    } else {
        j = index(argv[Optind], "=")
        if (j > 0)
            thisopt = substr(argv[Optind], 3, j - 3)
        else
            thisopt = substr(argv[Optind], 3)
        Optopt = thisopt
        i = match(longopts, "(^|,)" thisopt "($|[,:!])")
        if (i == 0 && match(thisopt, /^no-/)) {
            thisopt = substr(thisopt, 4)
            Optopt = thisopt
            i = match(longopts, "(^|,)" thisopt "($|[,:!])")
            Optinv = 1
        }
        if (i == 0) {
            if (Opterr)
                 printf("%s -- invalid option\n", thisopt) > "/dev/stderr"
            Optind++
            return "?"
        }
        if (substr(longopts, i-1+RLENGTH, 1) == ":") {
            Optreq = 1
            if (j > 0)
                Optarg = substr(argv[Optind], j + 1)
            else
                Optarg = argv[++Optind]
        } else {
            Optreq = 0
            Optarg = ""
        }
        if (index(Optarg, "'") == 1) {
            Optarg = substr(Optarg, 2)
            _optsq = 1
        } else if (index(Optarg, "\"") == 1) {
            Optarg = substr(Optarg, 2)
            _optdq = 1
        }
        if ((_optsq && index(Optarg, "'") == length(Optarg)) || (_optdq && index(Optarg, "\"") == length(Optarg))) {
            _optsq = 0
            _optdq = 0
        }
        while ((_optsq || _optdq) && Optind < length(argv)) {
            Optarg = Optarg " " argv[++Optind]
            if ((_optsq && index(Optarg, "'") == length(Optarg)) || (_optdq && index(Optarg, "\"") == length(Optarg))) {
                _optsq = 0
                _optdq = 0
            }
        }
        Optarg = substr(Optarg, 1, length(Optarg))
        Optind++
        return thisopt
    }
}
BEGIN {
    Opterr = 1    # default is to diagnose
    Optind = 1    # skip ARGV[0]

    # test program
    if (_getopt_test) {
        _myshortopts = "ab:cd"
        _mylongopts = "longa,longb:,otherc,otherd"

        while ((_go_c = getopt(ARGC, ARGV, _myshortopts, _mylongopts)) != -1)
            printf("c = <%s>, Optarg = <%s>\n", _go_c, Optarg)
        printf("non-option arguments:\n")
        for (; Optind < ARGC; Optind++)
            printf("\tARGV[%d] = <%s>\n", Optind, ARGV[Optind])
    }
}
