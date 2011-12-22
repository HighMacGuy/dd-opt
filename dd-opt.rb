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

if !FileTest.blockdev?(ddif)
  abort(ddif + " is not a block device.")
elsif !FileTest.blockdev?(ddof)
  abort(ddof + " is not a block device.")
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
ddbsmax_bytes_length = ddbsmax_bytes.to_s.length 

n = 1
until n > ddbsmax_bytes
  n = n * 2
end
effective_ddbsmax_bytes = n / 2

stdout = `diskutil info #{ddif}`
ddif_bytes = stdout.scan(/Total Size.*\((\d*) Bytes\)/)[0][0].to_i
if effective_ddbsmax_bytes > ddif_bytes
  abort("bs cannot be larger than dd infile")
end

stdout = `diskutil info #{ddof}`
ddof_bytes = stdout.scan(/Total Size.*\((\d*) Bytes\)/)[0][0].to_i
if effective_ddbsmax_bytes > ddof_bytes
  abort("bs cannot be larger than dd outfile")
end

z = 0
results = Array.new()
until z == 2
  n = 1
  until n > ddbsmax_bytes
    if !system("sync")
      abort("Command 'sync' failed.")
    elsif !system("purge")
      abort("Command 'purge' failed.")
    end
    count = effective_ddbsmax_bytes / n
    stdout = `dd if=#{ddif} of=#{ddof} bs=#{n} count=#{count} 2>&1`
    # puts stdout
    bytes_per_sec = stdout.scan(/\((\d*) bytes\/sec\)/)[0][0]
    padding = ddbsmax_bytes_length - n.to_s.length + 1
    puts "bs: " + n.to_s + " " * padding + "Bytes/sec: " + bytes_per_sec
    results = results + [[n, bytes_per_sec.to_i]]
    n = n * 2
  end
  z = z + 1
end
avg_array = Array.new()
grouped = results.group_by { |s| s[0] }
p grouped
grouped.each do |group|
  avg = 0
  group[1].each do |test|
    avg = avg + test[1]
  end
  avg = avg / group[1].length.to_f
  avg_array = avg_array + [[group[0], avg]]
end
p avg_array
