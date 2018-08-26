module LinuxProc

const pagesize = parse(UInt, read(`getconf PAGESIZE`, String))
const pagebits = UInt( log2( pagesize ) )

const residentbit = UInt(1) << 63

function record( pid, curraddress )
    maps = readlines( "/proc/$pid/maps" )
    parts = [split( map, r" +" ) for map in maps]
    @assert( length(unique(length.(parts))) == 1 )

    namedtuples = NamedTuple[]
    for i = 1:length(parts)
        (startaddress, endaddress) = parse.( UInt, "0x".*split( parts[i][1], "-" ) )
        if startaddress <= curraddress < endaddress
            push!( namedtuples, (startaddress=startaddress, endaddress=endaddress) )
        end
    end
    @assert( length(namedtuples) == 1 )
    
    return namedtuples[1]
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
