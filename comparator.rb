class Comparator
  require 'sqlite3'
  require 'hashdiff'

  def initialize config
    @test_db = SQLite3::Database.open config['test_db']
    @reference_db = SQLite3::Database.open config['reference_db']
    @table_to_compare = config['table']
    @compare_key = config['compare_key']
  end

  def get_data db, table
    db.prepare("select * from #{table}").execute
  end

  def hashify_data table_data, hash_key
    data_hash = {}
    table_data.each_hash do |record|
      hash_key_value = record[hash_key]
      key = hash_key_value.to_sym
      record.delete 'Z_PK' # removing mutable columns 
      data_hash[key] = data_hash[key].nil? ? record : [*data_hash[key]] << record
    end
    data_hash
  end

  def compare table
    test_data = get_data @test_db, table
    ref_data = get_data @reference_db, table

    test_data_hash = hashify_data test_data, @compare_key
    ref_data_hash = hashify_data ref_data, @compare_key

    size_diff = test_data_hash.size - ref_data_hash.size
    if size_diff == 0
      puts "Tables have identical sizes.\n\n"
    elsif size_diff < 0
      puts "Test data set is smaller than reference by #{size_diff.abs} records.\n\n"
    else
      puts "Test data set is larger than reference by #{size_diff} records.\n\n"
    end 

    HashDiff.diff(test_data_hash, ref_data_hash)

    # new_in_test = test_data_hash.to_a - ref_data_hash.to_a
    # missing_in_test = ref_data_hash.to_a - test_data_hash.to_a

    # new_hash = Hash[*new_in_test.flatten]
    # missing_hash = Hash[*missing_in_test.flatten]
    # differs_hash = {}

    # puts "New in test - #{new_hash}\n\n" if new_hash.size > 0
    # puts "Missing in test - #{missing_hash}\n\n" if missing_hash.size > 0
    # puts "Differs in test - #{differs_hash}" if differs_hash.size > 0
  end

  def compare_all
    # comparing all tables here
  end

  def run
    @table_to_compare.casecmp('all') == 0 ? compare_all : compare(@table_to_compare)
  end
end	