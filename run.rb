require 'yaml'
require_relative 'comparator'

config = YAML.load(File.open 'config.yml')

cmp = Comparator.new config
result = cmp.run
puts result