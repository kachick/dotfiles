# require 'open3'

shortner = -> str {
  limit = 70
  length = str.size
  str.slice(...limit).gsub("\n", ' ') + (length > limit ? '...' : '')
}

puts(ENV.sort.map { |k, v| "#{k}=#{shortner.(v)}" })

# o, e, s = Open3.capture3("echo a; sort >&2", :stdin_data=>"foo\nbar\nbaz\n")
# p o #=> "a\n"
# p e #=> "bar\nbaz\nfoo\n"
# p s #=> #<Process::Status: pid 32682 exit 0>

# Open3.capture3("echo a; sort >&2", :stdin_data=>"foo\nbar\nbaz\n")
