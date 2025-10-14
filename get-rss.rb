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
    .gsub(/\n *<atom:link .*? \/>/, "")
    .gsub(/#m(?=<\/)/, "")
    .gsub(/\n *<description>.*?<\/description>/m, "")
    .gsub(/\n *<image>.*?<\/image>/m, "")
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

if __FILE__ == $0
  html_body = ""

  users = get_users()
  users.each do |item|
    # RSSフィードをダウンロード
    if download("http://#{Address}/#{item}/rss", "dist/#{item}.rss")
      html_body << "<h2><a href=\"./#{item}.rss\">#{item}</a></h2>\n"
    end
  end

  # 完全なHTMLドキュメントを作成
  html_output = <<~HTML
    <!DOCTYPE html>
    <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <title>RSS Feeds</title>
    </head>
    <body>
    #{html_body}</body>
    </html>
  HTML

  FileUtils.mkdir_p("dist") unless Dir.exist?("dist")
  File.write("dist/index.html", html_output)
end
