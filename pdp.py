#!/usr/bin/env python3

def label(x):
    for l in x.split():
        print(l)

def directive(x, *args):
    argstr = ', '.join(str(x) for x in args)
    if argstr: argstr = '\t' + argstr
    if argstr and len(x) < 4: argstr = '\t' + argstr
    print('\t\t' + x + argstr)

def equ(k, v):
    print(str(k) + '\tequ\t' + str(v))

def cmt(*args):
    print(';', *args)

def r(x):
    return 'r' + str(x)

def v(x):
    return 'v' + str(x)

def f(x):
    return 'f' + str(x)

def normlshift(x):
    while x < 0: x += 32
    while x > 31: x -= 32
    return x


def sequence_aligned_loadstores(n, ralign):
    """
    How do I load/store n bytes, with their RHS aligned to an 8-boundary
    modulo ralign, while using only naturally aligned instructions?

    Return a string like this: '8', '4', '22', '121'
    """
    # (assumes some cheeky cleverness!)
    remaining = n
    s = ''
    while remaining:
        ofs = ralign - remaining
        if ofs & 1:
            g = 1
        elif ofs & 2:
            g = 2
        elif ofs & 4:
            g = 4
        else:
            g = 8
        while g > remaining:
            g >>= 1
        s += str(g)
        remaining -= g
    return s


def permutations_of_aligned_loadstores():
    """
    Get a set containing every permutation of sequence_aligned_loadstores for
    n of 1, 2, 3 ... 8 and ralign of 0, 1, 2 ... 7.
    """
    x = set()
    for length in range(1,9):
        for rhsalign in range(8):
            x.add(sequence_aligned_loadstores(length, rhsalign))
    return x

PERMUTATIONS_OF_ALIGNED_LOADSTORES = permutations_of_aligned_loadstores()


def list_perms_ending_with(x):
    """
    Recursive function tuned to help with final_loadstore_list
    """
    yield x
    subset = set()
    for e in PERMUTATIONS_OF_ALIGNED_LOADSTORES:
        if e.endswith(x) and len(e) > len(x):
            subset.add(e[-len(x)-1])
    for nextlet in sorted(subset):
        yield from list_perms_ending_with(nextlet + x)


SPECIAL_LOADSTORE_RETURN_PATHS = ['2', '22']

def final_loadstore_list():
    """
    Big waterfall of loads/stores!
    """
    the_list = []

    for ender in '8421':
        for x in list_perms_ending_with(ender):
            if x not in SPECIAL_LOADSTORE_RETURN_PATHS:
                the_list.append(x)

    return list(reversed(the_list))

FINAL_LOADSTORE_LIST = final_loadstore_list()


################################################################
# serious-er part of file. codegen functions only!
################################################################

def MRAlignDispatchTable():
    """
    Going through this dispatch table (which an int handler does) is the
    only route to access MRAlignLoads
    """
    directive('align', 10)
    label('MRAlignDispatchTable')

    hwtab_sizes = ['vector', 1, 2, 3, 4, 5, 6, 7, 8]

    for howlong in hwtab_sizes:
        cmt(howlong, 'stores/loads')
        for ldst in 'sl':
            for ralign in range(8):
                if howlong == 'vector':
                    if ldst == 's':
                        target = 'MRStoreVector'
                    elif ldst == 'l':
                        target = 'MRLoadVector'
     
                else: # integer load/store
                    if ldst == 's':
                        target = 'MRStore'
                    elif ldst == 'l':
                        target = 'MRLoad'

                    target += sequence_aligned_loadstores(howlong, ralign)

                directive('dc.w', '%s - FDP - (* - MRAlignDispatchTable)' % target)


# The table at the very end of the FDP, full of vector instructions!
# called from FDP_0554, which itself comes from the halfwit table, which seems to serve major_0x02ccc
def MRVectorAlignDispatchTable():
    pairs = [
        ('lvx',    'MRExecuted'),
        ('lvebx',  'FDP_0DA0'),
        ('lvehx',  'FDP_0DA0'),
        ('lvewx',  'FDP_0DA0'),
        ('stvx',   'MRExecuted'),
        ('stvebx', 'FDP_104C'),
        ('stvehx', 'FDP_1058'),
        ('stvewx', 'FDP_1064'),
    ]

    for firstinst_opcode, secondinst_dest in pairs:
        label(firstint_opcode.upper()+'Array')
        for i in range(32):
            directive(firstinst_opcode, v(i), 0, 'r23')
            directive('b', secondinst_dest)


def MRAlignLoads():
    waterfall = FINAL_LOADSTORE_LIST

    for wi in range(len(waterfall)):
        thisone = waterfall[wi]

        label('MRLoad' + thisone)

        size_list = [int(x) for x in thisone]
        this_size = size_list[0]
        total_size = sum(size_list)
        remain_size = sum(size_list[1:])

        if thisone == '8': # 2 x lwz
            directive('lwz', 'mrLow', '-8(mrBase)')
            directive('lwz', 'mrHigh', '-4(mrBase)')

        elif thisone == '44': # just do a straight load of the first 4, no scratch
            directive('lwz', 'mrHigh', '-%d(mrBase)' % total_size)
            directive('subi', 'mrCtr', 'mrCtr', 2 * this_size)

        elif thisone == '4': # special case: emulate lwarx if asked
            directive('bc', 'BO_IF', 23, '@atomic')
            directive('lwz', 'mrLow', '-4(mrBase)')
            directive('b', 'MRExecuted')
            label('@atomic')
            directive('li', 'mrScratch', -4)
            directive('lwarx', 'mrScratch', 'mrBase')

        else: # use an intermediate scratch register then bit-hack onwards
            inst = {1: 'lbz', 2: 'lhz', 4: 'lwz'}[this_size]

            directive(inst, 'mrScratch', '-%d(mrBase)' % total_size)
            if len(thisone) > 1: directive('subi', 'mrCtr', 'mrCtr', 2 * this_size)

            for regexponent, regname in [(4,'mrHigh'), (0,'mrLow')]:
                thisexponent = remain_size
                if regexponent >= thisexponent + this_size: continue
                if thisexponent >= regexponent + 4: continue

                lshift = (regexponent - thisexponent) * 8

                mask = 0
                for i in range(thisexponent, thisexponent + this_size):
                    i -= regexponent
                    if not 0 <= i < 4: continue
                    mask |= 0xFF << (8 * i)

                directive('rlwimi', regname, 'mrScratch', normlshift(lshift), '0x%08X' % mask)

        # We've done our load. Now jump to the proc that does the rest of them!

        if thisone[1:] == '4': # special case... inline an lwz!
            directive('lwz', 'mrLow', '-4(mrBase)')
            directive('b', 'MRExecuted')

        elif remain_size == 0:
            directive('b', 'MRExecuted')

        elif wi + 1 < len(waterfall) and waterfall[wi+1] == thisone[1:]:
            pass # fall through

        else:
            directive('b', 'MRLoad' + thisone[1:])

        print()



MRAlignLoads()
