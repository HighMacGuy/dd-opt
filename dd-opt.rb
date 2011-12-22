if ARGV.length < 1
  abort("No dd infile specified.")
elsif ARGV.length < 2
  abort("No dd outfile specified.")
elsif ARGV.length > 4
  abort("Too many arguments.")
elsif ARGV.length == 2
  ddbsmax = "4k"
  iterations = "3"
elsif ARGV.length == 3
  ddbsmax = ARGV[2]
  iterations = "3"
elsif ARGV.length == 4
  ddbsmax = ARGV[2]
  iterations = ARGV[3]
end
 
ddif = ARGV[0]
ddof = ARGV[1]

# Validate ddof, ddif

if !FileTest.blockdev?(ddif)
  abort(ddif + " is not a block device.")
elsif !FileTest.blockdev?(ddof)
  abort(ddof + " is not a block device.")
end

# Validate ddbsmax

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

ddbs = 1
until ddbs > ddbsmax_bytes
  ddbs = ddbs * 2
end
effective_ddbsmax_bytes = ddbs / 2

ddif_info = `diskutil info #{ddif}`
ddif_bytes = ddif_info.scan(/Total Size.*\((\d*) Bytes\)/)[0][0].to_i
if effective_ddbsmax_bytes > ddif_bytes
  abort("bs cannot be larger than dd infile")
end

ddof_info = `diskutil info #{ddof}`
ddof_bytes = ddof_info.scan(/Total Size.*\((\d*) Bytes\)/)[0][0].to_i
if effective_ddbsmax_bytes > ddof_bytes
  abort("bs cannot be larger than dd outfile")
end

# Validate iterations

iterations_array =  iterations.scan(/(\D*)(\d*)(\D*)/)[0]
if iterations_array[0] != "" || iterations_array[2] != ""
  abort("'" + iterations + "' is not a valid number of iterations. Must be an integer.")
else
  iterations = iterations.to_i
end

# Determine whether ddif and ddof are large enough that it's unnecessary
# to clear the write and read caches for every single iteration/ddbs combination.

ddif_bs = ddif_info.scan(/Total Size.*?(\d*)-Byte-Blocks\)/)[0][0].to_i
ddof_bs = ddof_info.scan(/Total Size.*?(\d*)-Byte-Blocks\)/)[0][0].to_i
dd_bs_max = [ddif_bs, ddof_bs].max

ddbs = 1
iseek = 0
oseek = 0
until ddbs == effective_ddbsmax_bytes 
  count = effective_ddbsmax_bytes / ddbs
    ##### Near-duplicate code lines below should be abstracted into a method. #####
    if effective_ddbsmax_bytes % ddif_bs != 0
      ddif_remainder = 1
    else
      ddif_remainder = 0
    end
    ddif_blocks_used = (effective_ddbsmax_bytes / ddif_bs) + ddif_remainder
    iseek = iseek + ddif_blocks_used
    if effective_ddbsmax_bytes % ddof_bs != 0
      ddof_remainder = 1
    else
      ddof_remainder = 0
    end
    ddof_blocks_used = (effective_ddbsmax_bytes / ddof_bs) + ddof_remainder
    oseek = oseek + ddof_blocks_used
  ddbs = ddbs * 2
end
if (iseek * ddif_bs) > ddif_bytes || (oseek * ddof_bs) > ddof_bytes
  fast_mode = false
else
  fast_mode = true
end


#########
# Iterate
#########

z = 0
results = Array.new()
until z == iterations
  ddbs = 1
  iseek = 0
  oseek = 0
  ddif_total_used = 0
  ddof_total_used = 0
  until ddbs > ddbsmax_bytes
    count = effective_ddbsmax_bytes / ddbs
    if fast_mode == false || ddbs == 1
      iseek = 0
      oseek = 0
      if !system("sync")
        abort("Command 'sync' failed.")
      elsif !system("purge")
        abort("Command 'purge' failed.")
      end
    end

    stdout = `dd if=#{ddif} of=#{ddof} bs=#{ddbs} count=#{count} iseek=#{iseek} oseek=#{oseek} 2>&1`
    # puts stdout

    bytes_per_sec = stdout.scan(/\((\d*) bytes\/sec\)/)[0][0]
    padding = ddbsmax_bytes_length - ddbs.to_s.length + 2
    iteration_padding = iterations.to_s.length - z.to_s.length + 2
    puts "Iteration: " + z.to_s + " " * iteration_padding + "bs: " + ddbs.to_s + " " * padding + "Bytes/sec: " + bytes_per_sec + " iseek: " + iseek.to_s + " oseek: " + oseek.to_s
    results = results + [[ddbs, bytes_per_sec.to_i]]

def get_seek_offset(bs_just_used, disk_bs, effective_ddbsmax_bytes)
    if effective_ddbsmax_bytes % disk_bs != 0
      remainder = 1
    else
      remainder = 0
    end
    next_bs_dd_blocks_used = (effective_ddbsmax_bytes / dd_bs) + remainder
    iseek = iseek + ddif_blocks_used
end 

    ##### Near-duplicate code lines below should be abstracted into a method. #####
    if effective_ddbsmax_bytes % ddif_bs != 0
      ddif_remainder = 1
    else
      ddif_remainder = 0
    end
    ddif_blocks_used = (effective_ddbsmax_bytes / ddif_bs) + ddif_remainder
    iseek = iseek + ddif_blocks_used
    if effective_ddbsmax_bytes % ddof_bs != 0
      ddof_remainder = 1
    else
      ddof_remainder = 0
    end
    ddof_blocks_used = (effective_ddbsmax_bytes / ddof_bs) + ddof_remainder
    oseek = oseek + ddof_blocks_used

    ddbs = ddbs * 2
  end
  z = z + 1
end
avg_array = Array.new()
grouped = results.group_by { |s| s[0] }
# p grouped
grouped.each do |group|
  avg = 0
  group[1].each do |test|
    avg = avg + test[1]
  end
  avg = avg / group[1].length.to_f
  avg_array = avg_array + [[group[0], avg]]
end
conclusion_array = avg_array.sort{|x,y| y[1] <=> x[1] }[0]
puts "Optimum bs value: " + conclusion_array[0].to_s
puts "Mean transfer rate with bs=" + conclusion_array[0].to_s + ": " + conclusion_array[1].to_s + " bytes/sec"
