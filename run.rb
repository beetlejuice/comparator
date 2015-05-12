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