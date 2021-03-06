module LinuxProc

const pagesize = parse(UInt, read(`getconf PAGESIZE`, String))
const pagebits = UInt( log2( pagesize ) )

const residentbit = UInt(1) << 63

function maps( pid )
    records = (startaddress=UInt[], endaddress=UInt[], file=String[],)
    lengths = Int[]
    for line in readlines( "/proc/$pid/maps" )
        parts = split( line, r" +" )
        if isempty(lengths)
            push!( lengths, length(parts) )
        else
            @assert( length(parts) == lengths[1] )
        end
        addresses = split( parts[1], "-" )
        push!( records.startaddress, parse( UInt, "0x"*addresses[1] ) )
        push!( records.endaddress, parse( UInt, "0x"*addresses[2] ) )
        push!( records.file, parts[end] )
    end
    return records
end

function record( pid, curraddress )
    maps = LinuxProc.maps(pid)
    records = filter( i -> maps.startaddress[i] <= curraddress < maps.endaddress[i], 1:length(maps.file) )
    @assert( length(records) == 1 )

    return (
        startaddress = maps.startaddress[records[1]],
        endaddress = maps.endaddress[records[1]],
        file = maps.file[records[1]],
    )
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
