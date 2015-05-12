require 'yaml'
require_relative 'comparator'

# config = YAML.load(File.open 'config.yml')
config = {
  'test_db'      => ARGV[0],
  'reference_db' => ARGV[1],
  'table'        => ARGV[2],
  'compare_key'  => ARGV[3]
}

cmp = Comparator.new config
result = cmp.run
puts result
Dir.mkdir('log') unless File.exists?('log')
File.open('log/result.txt', 'w') { |f| f << result }
puts 'Comparation log stored in log/result.txt.'
