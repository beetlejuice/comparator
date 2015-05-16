class Comparator
  require 'sqlite3'
  require 'hashdiff'

  # Keys with values that may vary for identical data sets
  MUTABLE_KEYS = ['Z_PK', 'Z_ENT', 'Z_OPT', 'ZSPECIALTY', 'ZCOMPETITORCOMMENTS', 'ZRECOMMENDATIONCOMMENTS']
  LINKS = {'ZCAMPAIGNACTIONATTRIBUTE' => 
              {'ZPRODUCTFORMULARY' => 'ZPRODUCTFORMULARY', 
               'ZGROUPOFATTRIBUTES' => 'ZCAMPAIGNACTIONATTRIBUTESGROUP'},
           'ZCAMPAIGNACTIONATTRIBUTESGROUP' =>
              {'ZCAMPAIGNACTION' => 'ZCAMPAIGNACTION'},
           'ZVISIT' =>
              {'ZCONTACT' => 'ZCONTACT', 
               'ZORGANIZATION' => 'ZORGANIZATION'}
          }

  def initialize config
    @test_db = SQLite3::Database.open config['test_db']
    @reference_db = SQLite3::Database.open config['reference_db']
    @table_to_compare = config['table']
    @compare_key = config['compare_key'] || 'ZENTITYID'
  end

  def get_data_from_table db, table
    db.prepare("select * from #{table}").execute
  end

  def get_tables db
    tables_data = db.prepare("select name from sqlite_master where type = 'table'").execute
    tables_array = []
    tables_data.each_hash { |record| tables_array << record['name'] }
  end

  def remove_mutable_keys record, keys
    keys.each { |key| record.delete key }
    record
  end

  def provide_links table
    LINKS[table]
  end

  def restore_links record, table
    links = provide_links table
    links.each do |k, v|
      if !record[k].nil?
        test_id = @test_db.prepare("select ZENTITYID from #{v} where Z_PK = '#{record[k]}'").execute.next[0]
        ref_value = @reference_db.prepare("select Z_PK from #{v} where ZENTITYID = '#{test_id}'").execute.next[0]
        record[k] = ref_value
      end
    end
    record
  end

  def hashify_data table_data, hash_key, *options
    table, is_test = options
    data_hash = {}
    table_data.each_hash do |record|
      hash_key_value = record[hash_key]
      key = hash_key_value.to_sym
      record = remove_mutable_keys record, MUTABLE_KEYS
      record = restore_links record, table if is_test && LINKS.keys.include?(table)
      data_hash[key] = data_hash[key].nil? ? record : [*data_hash[key]] << record
    end
    data_hash
  end

  def compare table
    test_data = get_data_from_table @test_db, table
    ref_data = get_data_from_table @reference_db, table

    test_data_hash = hashify_data test_data, @compare_key, table, true
    ref_data_hash = hashify_data ref_data, @compare_key

    size_diff = test_data_hash.size - ref_data_hash.size
    if size_diff == 0
      puts "Tables have identical sizes.\n\n"
    elsif size_diff < 0
      puts "Test data set is smaller than reference by #{size_diff.abs} records.\n\n"
    else
      puts "Test data set is larger than reference by #{size_diff} records.\n\n"
    end 

    HashDiff.diff(test_data_hash, ref_data_hash, similarity: 1.0)
  end

  def compare_all
    db_result = {}
    tables_array = get_tables @test_db
    tables_array.each do |table|
      table_result = compare table
      db_result["#{table}"] = table_result
    end
    db_result
  end

  def run
    @table_to_compare.casecmp('all') == 0 ? compare_all : compare(@table_to_compare)
  end
end	
