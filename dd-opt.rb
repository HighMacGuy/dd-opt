require "./os.rb"

class BlockDevice
  attr_reader :path
  attr_reader :mounted
  attr_reader :total_bytes
  attr_reader :free_bytes

  def initialize(path)
    if !FileTest.chardev?(path) && !FileTest.blockdev?(path)
      abort(path + " is not a block device, raw device or character device.")
    else
      @path = path

      ## Initialise other BlockDevice attributes.
      if OS::mac?

        ## Get BlockDevice info string
        @info = `diskutil info #{@path}`

        ## Initialise @mounted attribute
        if    @info.scan(/Mounted:\s*(\w*)/)[0] == nil then
                abort("Error!" + @path + " might be a device of a kind dd-opt is"\
                        " not (yet!) equipped to handle, e.g. a pseudo-device."\
                        " See https://github.com/sampablokuper/dd-opt/issues/4")
        elsif @info.scan(/Mounted:\s*(\w*)/)[0][0] == "Yes" then @mounted = true
        elsif @info.scan(/Mounted:\s*(\w*)/)[0][0] == "No"  then @mounted = false
        else  abort("Could not determine whether " + @path + " is mounted.")
        end

        ## Initialise @total_bytes attribute
        @total_bytes = @info.scan(/Total Size.*\((\d*) Bytes\)/)[0][0].to_i

        ## Initialise @free_bytes attribute
        # Mac OS X diskutil will not report the free space on an unmounted
        # block device so we must mount this BlockDevice temporarily to find its
        # free space and then immediately unmount it again to restore its state
        # unless it was already mounted.
        if !@mounted
          if !system("diskutil mount " + @path)
            abort ("Could not mount " + @path)
          end
          @free_bytes = @info.scan(/Volume Free Space.*\((\d*) Bytes\)/)[0][0].to_i
          if !system("diskutil unmount " + @path)
            abort ("Could not unmount " + @path)
          end
        else
          @free_bytes = @info.scan(/Volume Free Space.*\((\d*) Bytes\)/)[0][0].to_i
        end

      else
        abort("dd-opt does not yet work on operating systems besides Mac OS X. Help out by forking https://github.com/sampablokuper/dd-opt")
      end
    end
  end
end

##
# Parse options and arguments
##

help = "\nUsage: dd-opt.rb dd-infile dd-outfile [MAXBS] [ITERATIONS]

        Example 1: dd-opt.rb /dev/disk4s1 /dev/disk5s1 16m 3

        Or, using raw devices for faster speed:

        Example 2: dd-opt.rb /dev/rdisk4s1 /dev/rdisk5s1 16m 3

        *** Important note: dd-outfile will be partially or wholly overwritten. ***  

        '-h', '--help', Display this screen.
        MAXBS		Maximum value of dd command's 'bs' parameter to try, e.g. 512 or
                          4k. Valid suffixes: k, m, g, t, p, e, z, y.
        ITERATIONS	Number of times to iterate over all values of bs
                          incrementing in powers of 2 upto MAXBS.\n\n"

if ARGV.length < 1
  abort("No dd infile specified.")
elsif ARGV.length < 2
  if ARGV[0] == "-h" || ARGV[0] == "--help"
    puts help; exit
  else
    abort("No dd outfile specified.")
  end
elsif ARGV.length > 4
  abort("Too many arguments.")
elsif ARGV.length == 2
  ddbsmax = "4k"   # Make MAXBS default to 4k. (Why 4k? Cos it usually works for me.)
  iterations = "3" # Make ITERATIONS default to 3 (Why 3? Cultural: "best of three".)
elsif ARGV.length == 3
  ddbsmax = ARGV[2]
  iterations = "3" # Make ITERATIONS default to 3 (Why 3? Cultural: "best of three".)
elsif ARGV.length == 4
  ddbsmax = ARGV[2]
  iterations = ARGV[3]
end
 
ddif = BlockDevice.new(ARGV[0])
ddof = BlockDevice.new(ARGV[1])

##
# Validate ddbsmax
##

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

if    effective_ddbsmax_bytes > ddif.total_bytes
  abort("bs cannot be larger than dd infile")
elsif effective_ddbsmax_bytes > ddof.total_bytes
  abort("bs cannot be larger than dd outfile")
end

# Validate "iterations" parameter

iterations_array =  iterations.scan(/(\D*)(\d*)(\D*)/)[0]
if iterations_array[0] != "" || iterations_array[2] != ""
  abort("'" + iterations + "' is not a valid number of iterations. Must be an integer.")
else
  iterations = iterations.to_i
end

# Check ddif used space is less than or equal to ddof total space

if !((ddif.total_bytes - ddif.free_bytes) <= ddof.total_bytes)
  abort(ddof.path + " is too small to accommodate the contents of " + ddif.path)
end


#########
# Iterate
#########

puts "Starting tests..."

z = 0
results = Array.new()
until z == iterations
  ddbs = 1
  until ddbs > ddbsmax_bytes
    if !system("sync")
      abort("Command 'sync' failed.")
    elsif !system("purge")
      abort("Command 'purge' failed.")
    end
    count = effective_ddbsmax_bytes / ddbs
    stdout = `dd if=#{ddif.path} of=#{ddof.path} bs=#{ddbs} count=#{count} 2>&1`
    if stdout.scan(/\((\d*) bytes\/sec\)/)[0] == nil
      abort("Error: unexpected failure of `dd`.\n" + stdout)
    else
      bytes_per_sec = stdout.scan(/\((\d*) bytes\/sec\)/)[0][0]
    end
    padding = ddbsmax_bytes_length - ddbs.to_s.length + 2
    iteration_padding = iterations.to_s.length - z.to_s.length + 2
    puts "Iteration: " + z.to_s + " " * iteration_padding + "bs: " + ddbs.to_s + " " * padding + "Bytes/sec: " + bytes_per_sec
    results = results + [[ddbs, bytes_per_sec.to_i]]
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
