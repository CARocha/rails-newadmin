require "zlib"
require "json"
root = File.expand_path("..", __dir__)
files = %w[application.css application.js appearance.js]
compressed = files.to_h do |name|
  [ name, Zlib.gzip(File.binread(File.join(root, "app/assets/builds/rails_newadmin", name)), level: 9).bytesize ]
end
total = compressed.values.sum
raise "Base CSS/JS exceeds 150 KiB gzip: #{total} bytes" if total > 150 * 1024
puts JSON.generate(base_gzip_bytes: total, budget_bytes: 150 * 1024, files: compressed,
  optional_chart_gzip_bytes: Zlib.gzip(File.binread(File.join(root, "app/assets/builds/rails_newadmin/charts.js")), level: 9).bytesize)
