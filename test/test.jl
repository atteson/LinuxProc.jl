using LinuxProc
using Mmap

n = 10_000_000

file = tempname()
x = rand( n )
write( file, x )

y = Mmap.mmap( file, Vector{Float64}, n, 0 )

pages0 = LinuxProc.numresidentpages( getpid(), file )
@assert( pages0.pages == Int(ceil( n*8/LinuxProc.pagesize )) )

@assert( 0.0 <= pages0.resident/pages0.pages <= 0.01 )

sum = 0.0
for i = 1:n
    global sum += y[i]
end

pages1 = LinuxProc.numresidentpages( getpid(), file )

@assert( pages1.pages == pages0.pages )

@assert( pages1.resident == pages1.pages )

rm( file )


