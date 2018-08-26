module LinuxProc

const pagesize = parse(UInt, read(`getconf PAGESIZE`, String))
const pagebits = UInt( log2( pagesize ) )

const residentbit = UInt(1) << 63

function parsepagemapline( line )
    parts = split( line, " " )
    addresses = split( parts[1], "-" )
    return (
        startaddress = parse( UInt, "0x"*addresses[1] ),
        endaddress = parse( UInt, "0x"*addresses[2] ),
        file = parts[end],
    )
end

function record( pid, curraddress )
    records = NamedTuple[]
    for line in readlines( "/proc/$pid/maps" )
        record = parsepagemapline( line )
        if record.startaddress <= curraddress < record.endaddress
            push!( records, record )
        end
    end
    @assert( length(records) == 1 )
    
    return records[1]
end

page( address ) = address >> pagebits

address( page ) = page << pagebits

function numresidentpages( pid, curraddress )
    currrecord = record( pid, curraddress )

    currpage = page( currrecord.startaddress )
    @assert( currrecord.startaddress & (pagesize - 1) == 0 )
    pages = 0
    resident = 0

    pagemap = open( "/proc/$pid/pagemap", "r" )
    seek( pagemap, currpage << 3 )
    while address( currpage ) < currrecord.endaddress
        flags = read( pagemap, UInt )
        resident += (residentbit & flags) != 0
        pages += 1
        currpage += 1
    end
    close( pagemap )
    
    return (pages=pages, resident=resident)
end

end # module
