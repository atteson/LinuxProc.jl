module LinuxProc

const pagesize = parse(UInt, read(`getconf PAGESIZE`, String))
const pagebits = UInt( log2( pagesize ) )

const residentbit = UInt(1) << 63

function record( pid, file )
    maps = readlines( "/proc/$pid/maps" )
    parts = [split( map, r" +" ) for map in maps]
    @assert( length(unique(length.(parts))) == 1 )

    part = filter(row -> row[end]==file, parts )
    @assert( length(part) == 1 )

    (startaddress, endaddress) = parse.( UInt, "0x".*split( part[1][1], "-" ) )
    
    return (startaddress=startaddress, endaddress=endaddress)
end

page( address ) = address >> pagebits

address( page ) = page << pagebits

function numresidentpages( pid, file )
    currrecord = record( pid, file )

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
