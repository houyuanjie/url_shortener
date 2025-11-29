# frozen_string_literal: true

require 'fileutils'
require 'sqlite3'

DEFAULT_DB_FILE = File.expand_path('../db/urls.db', __dir__)

# 短链接生成器
class UrlShortener
  ALPHABET = ['0'..'9', 'a'..'z', 'A'..'Z'].flat_map(&:to_a).freeze
  BASE = ALPHABET.length

  def initialize(db_file = DEFAULT_DB_FILE)
    FileUtils.mkdir_p(File.dirname(db_file))

    @db = SQLite3::Database.new(db_file)
    @db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS urls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_url TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  # 生成短链接
  def shorten(url)
    @db.execute(<<~SQL, [url])
      INSERT INTO urls (original_url)
      VALUES (?);
    SQL

    id = @db.last_insert_row_id

    encode(id)
  end

  # 还原原始链接
  def expand(short_code)
    id = decode(short_code)

    @db.get_first_value(<<~SQL, [id])
      SELECT original_url
      FROM urls
      WHERE id = ?;
    SQL
  end

  private

  # 数据库 ID 转 BASE 字符串
  def encode(id)
    return ALPHABET[0] if id.zero?

    short_code = ''

    while id.positive?
      index = id % BASE
      short_code = "#{ALPHABET[index]}#{short_code}"
      id /= BASE
    end

    short_code
  end

  # BASE 字符串转数据库 ID
  def decode(short_code)
    id = 0

    short_code.each_char do |c|
      id *= BASE
      id += ALPHABET.index(c)
    end

    id
  end
end
