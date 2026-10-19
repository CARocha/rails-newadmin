require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  track_files "{app,lib}/**/*.rb"
  add_filter "/test/"
  add_filter "/vendor/"
  minimum_coverage line: 90
end
