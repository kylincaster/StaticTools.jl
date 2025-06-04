## --- File pointers

    fp = stdoutp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stdoutp() == fp != 0
    fp = stderrp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stderrp() == fp != 0
    fp = stdinp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stdinp() == fp != 0

    fp = fopen(c"testfile.txt", c"w")
    @test isa(fp, Ptr{StaticTools.FILE})
    @test fp != 0
    @test fclose(fp) == 0

## -- Test low-level printing functions on a variety of arguments

    @test puts("1") == 0
    @test printf("2") >= 0
    @test putchar('\n') == 0
    @test printf("%s\n", "3") >= 0
    @test printf(4) == 0
    @test printf(5.0) == 0
    @test printf(10.0f0) == 0
    @test printf(0x01) == 0
    @test printf(0x0001) == 0
    @test printf(0x00000001) == 0
    @test printf(0x0000000000000001) == 0
    @test printf(Ptr{UInt64}(0)) == 0
    @test printf((c"\nThe value of x is currently ", 1.0, c"\n")) == 0
    tpl = (c"1", c": ", c"Sphinx ", c"of ", c"black ", c"quartz, ", c"judge ", c"my ", c"vow!", c"\n")
    for n ∈ 1:length(tpl)-1
        @test printf(tpl[[1:n..., length(tpl)]]) == 0
    end

## -- low-level printing to file

    fp = fopen("testfile.txt", "w")
    @test isa(fp, Ptr{StaticTools.FILE})
    @test fp != 0

    @test puts(fp, "1") == 0
    @test printf(fp, c"2") == 1
    @test putchar(fp, '\n') == 0
    @test printf(fp, "%s\n", "3") == 2 broken=(Sys.ARCH===:aarch64)
    @test printf(fp, 4) == 0
    @test printf(fp, 5.0) == 0
    @test printf(fp, 10.0f0) == 0
    @test printf(fp, 0x01) == 0
    @test printf(fp, 0x0001) == 0
    @test printf(fp, 0x00000001) == 0
    @test printf(fp, 0x0000000000000001) == 0
    @test printf(fp, Ptr{UInt64}(0)) == 0
    @test printf(fp, (c"\nThe value of x is currently ", 1.0, c"\n")) == 0
    tpl = (c"1", c": ", c"Sphinx ", c"of ", c"black ", c"quartz, ", c"judge ", c"my ", c"vow!", c"\n")
    for n ∈ 1:length(tpl)-1
        @test printf(fp, tpl[[1:n..., length(tpl)]]) == 0
    end

## -- High-level printing

    # Print AbstractVector
    @test printf(1:5) == 0
    @test printf((1:5...,)) == 0
    @test printf(fp, 1:5) == 0
    @test printf(fp, (1:5...,)) == 0
    a = MallocVector{Float64}(undef, 2); fill!(a, 2)
    @test print(a) == 0
    @test println(a) == 0
    @test print(fp, a) == 0
    @test println(fp, a) == 0
    @test free(a) == 0

    # Print AbstractArray
    @test printf((1:5)') == 0
    @test printf(rand(4,4)) == 0
    @test printf(fp, (1:5)') == 0
    @test printf(fp, rand(4,4)) == 0
    a = MallocMatrix{Float64}(undef, 1,2); fill!(a, 2)
    @test print(a) == 0
    @test println(a) == 0
    @test print(fp, a) == 0
    @test println(fp, a) == 0
    @test free(a) == 0

    # Print MallocString
    str = m"Hello, world! 🌍"
    @test print(str) === Int32(strlen(str))
    @test println(str) === Int32(0)
    @test print(fp, str) === Int32(strlen(str))
    @test println(fp, str) === Int32(0)
    @test printf(str) == Int32(strlen(str))
    @test printf(fp, str) == Int32(strlen(str))
    @test puts(str) == 0
    @test printf(m"%s \n", str) >= 0
    show(str)

    # Print StaticString
    str = c"Hello, world! 🌍"
    @test print(str) === Int32(strlen(str))
    @test println(str) === Int32(0)
    @test print(fp, str) === Int32(strlen(str))
    @test println(fp, str) === Int32(0)
    @test printf(str) === Int32(strlen(str))
    @test printf(fp, str) === Int32(strlen(str))
    @test puts(str) == 0
    @test printf(m"%s \n", str) >= 0
    show(str)

    # Print StringView
    sview = str[1:5]
    @test puts(sview) === Int32(0)
    @test puts(fp, sview) === Int32(0)
    @test printf(sview) === Int32(5)
    @test printf(fp, sview) === Int32(5)
    @test print(sview) === Int32(5)
    @test println(sview) === Int32(0)
    @test print(fp, sview) === Int32(5)
    @test println(fp, sview) === Int32(0)
    show(sview)

## --- Printing errors

    @test error(c"This is a test\n") == 0
    @test StaticTools.warn(c"This is a test\n") == 0
    msg = m"This is a test\n"
    @test error(msg) == 0
    @test StaticTools.warn(msg) == 0
    free(msg)

## --- Libc functions that just happen to print

    msg = m"pwd"
    @test StaticTools.system(msg) == 0
    @test StaticTools.system(c"pwd") == 0
    free(msg)

## ---  Wrap up

    @test newline() == 0
    @test newline(fp) == 0
    @test StaticTools.system(c"echo Enough printing for now!") == 0
    @test fclose(fp) == 0

## -- Reading from files

    name, mode = m"testfile.txt", m"r"
    fp = fopen(name, mode)
    @test isa(fp, Ptr{StaticTools.FILE})
    @test ftell(fp) === 0
    @test fp != 0
    str = MallocString(undef, 100)
    @test gets!(str, fp) != C_NULL
    @test strlen(str) == 2
    @test ftell(fp) === 2
    @test str[1] == UInt8('1')

    @test frewind(fp) == 0
    @test readline!(str, fp) != C_NULL
    @test strlen(str) == 2
    @test str[1] == UInt8('1')

    @test fseek(fp, -2, SEEK_CUR) == 0
    @test gets!(str, fp) != C_NULL
    @test strlen(str) == 2
    @test str[1] == UInt8('1')
    @test free(str) == 0

    @test frewind(fp) == 0
    @test getc(fp) === Int32('1')
    @test getc(fp) === Int32('\n')
    @test read(fp, UInt8) === UInt8('2')

    @test frewind(fp) == 0
    str = readline(fp)
    @test isa(str, MallocString)
    @test str[1] == UInt8('1')
    @test free(str) == 0

    @test fclose(fp) == 0
    # @static if fp != 0 && Sys.isbsd()
    #     @test getchar(fp) === UInt8('1')
    #     @test getchar(fp) === UInt8('\n')
    #     @test fclose(fp) == 0
    # end

    # Read entire file to string
    str = read(c"testfile.txt", MallocString)
    @test isa(str, MallocString)
    @test str[1] == UInt8('1')
    @test length(str) > 500
    strc = StaticString(str)
    @test fread!(str, c"testfile.txt") == strc
    @test free(str) == 0

    @test free(name) == 0
    @test free(mode) == 0

## -- Reading and writing binary data to file

    m = (1:10)*(1:10)'
    fp = fopen(c"testfile.b", c"wb")
    @test fwrite(fp, m) == 100
    @test fclose(fp) == 0

    fp = fopen(c"testfile.b", c"rb")
    @test fread!(szeros(Int, 10,10), fp) == m
    @test fclose(fp) == 0

    rm("testfile.b")
    @test write(c"testfile.b", StackArray(m)) == 100
    a = read(c"testfile.b", MallocArray{Int64})
    @test isa(a, MallocArray)
    @test reshape(a, 10,10) == m
    @test free(a) == 0


## --- clean up

    rm("testfile.txt")
    rm("testfile.b")
