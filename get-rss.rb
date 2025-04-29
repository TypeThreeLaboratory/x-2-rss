require "json"
require "open-uri"
require "fileutils"

Address = "localhost"

def get_users
  File.open("users.json", "r") do |f|
    JSON.load(f)
  end
rescue Errno::ENOENT
  puts "Error: users.json not found."
  return []
rescue JSON::ParserError
  puts "Error: Invalid JSON format in users.json."
  return []
end

def replace(text)
  text
    .gsub("http://", "https://")
    .gsub(/#m(?=<\/)/, "")
    .gsub(/\n *<description>.*?<\/description>/m, "")
    .gsub(/\n *<image>.*?<\/image>/m, "")
    .gsub(/\n *<title>.*?<\/title>/m, "")
    .gsub(/\n *<dc:creator>.*?<\/dc:creator>/m, "")
end

def download(url, path)
  FileUtils.mkdir_p(File.dirname(path))
  begin
    content = URI.open(url).read
    File.open(path, "w") do |local_file|
      local_file.write(replace(content))
    end
    puts "Successfully downloaded: #{url} to #{path}"
    return true
  rescue OpenURI::HTTPError => e
    puts "Error downloading #{url}: HTTP error - #{e.message}"
    return false
  rescue SocketError => e
    puts "Error downloading #{url}: Network error - #{e.message}"
    return false
  rescue StandardError => e
    puts "Error downloading #{url}: An unexpected error occurred - #{e.message}"
    return false
  end
end

def saveREADME(path, text)
  File.open(path, "w") do |file|
    file.puts(text)
  end
  puts "README.md saved to #{path}"
end

if __FILE__ == $0
  usersText = ""
  users = get_users()

  users.each do |item|
    if download("http://#{Address}/#{item}/rss", "dist/#{item}.rss")
      usersText << "## [#{item}](./#{item}.rss)\n"
    end
  end

  FileUtils.mkdir_p("dist") unless Dir.exist?("dist")
  saveREADME("dist/README.md", usersText)
end
