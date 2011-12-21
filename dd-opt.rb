if ARGV.length < 1
  abort("No dd infile specified.")
elsif ARGV.length < 2
  abort("No dd outfile specified.")
elsif ARGV.length > 3
  abort("Too many arguments.")
elsif ARGV.length == 2
  ddbsmax = "4k"
elsif ARGV.length == 3
  ddbsmax = ARGV[2]
end
 
ddif = ARGV[0]
ddof = ARGV[1]

if !FileTest.exist?(ddif)
  abort(ddif + " does not exist on the filesystem.")
elsif !FileTest.exist?(ddof)
  abort(ddof + " does not exist on the filesystem.")
end

ddbsmax_array =  ddbsmax.scan(/(\D*)(\d*)(.*)/)[0]
if ddbsmax_array[0] != ""
  abort("'" + ddbsmax + "' is not a valid maximum block size")
end

ddbsmax_n = ddbsmax_array[1].to_i
ddbsmax_suffix = ddbsmax_array[2]

if ddbsmax_suffix == "b" || ddbsmax_suffix == ""
  power =  0
elsif ddbsmax_suffix == "k"
  power = 10
elsif ddbsmax_suffix == "m"
  power = 20
elsif ddbsmax_suffix == "g"
  power = 30
elsif ddbsmax_suffix == "t"
  power = 40
elsif ddbsmax_suffix == "p"
  power = 50
elsif ddbsmax_suffix == "e"
  power = 60
elsif ddbsmax_suffix == "z"
  power = 70
elsif ddbsmax_suffix == "y"
  power = 80
else
  abort("Invalid block size suffix.")
end

ddbsmax_bytes = ddbsmax_n * 2 ** power

puts "ddbsmax_n: " + ddbsmax_n.to_s
puts "ddbsmax_suffix: " + ddbsmax_suffix
puts ddbsmax_bytes

stdout = `dd if=/dev/disk6s1 of=/dev/disk7s1 bs=256k count=1 2>&1`
puts "foo"
puts stdout

bytes_per_sec = stdout.scan(/\((\d*) bytes\/sec\)/)[0][0]
puts "Bytes/sec: " + bytes_per_sec
puts "Bytes/sec x 2: " + (2 * bytes_per_sec.to_i).to_s
