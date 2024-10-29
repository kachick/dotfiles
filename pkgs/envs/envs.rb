require 'open3'

shortner = -> str {
  limit = 70
  length = str.size
  str.slice(...limit).gsub("\n", ' ') + (length > limit ? '...' : '')
}

envs = ENV.sort.map { |k, v| "#{k}=#{shortner.(v)}" }

fzf_query = ARGV.first

Open3.pipeline_w(
  %Q!fzf --delimiter '=' --nth '1' --query "#{fzf_query}"!
) do |first_stdin, _wait_thrs|
  first_stdin.puts envs
end
