require 'nokogiri'
require 'json'
require 'rest_client'
require 'iconv'
require 'ruby-progressbar'
require_relative 'course.rb'

ic = Iconv.new("utf-8//translit//IGNORE","big5")
start_url = "https://nol.ntu.edu.tw/nol/coursesearch/search_result.php?alltime=yes&allproced=yes&cstype=1&csname=&current_sem=103-2&op=stu&startrec=0"
search_url = "https://nol.ntu.edu.tw/nol/coursesearch/search_result.php"
base_url = "https://nol.ntu.edu.tw/nol/coursesearch/"

r = RestClient.get start_url
doc = Nokogiri::HTML(ic.iconv(r.to_s))
pages = doc.css('select[name="jump"]')[0].css('option').map {|l| l['value']}

courses = []

progress = ProgressBar.create(:title => "Crawling", :total => pages.length)
pages.each_with_index do |page_link, index|
  progress.increment
  r = RestClient.get "#{search_url}#{page_link}"
  doc = Nokogiri::HTML(ic.iconv(r.to_s))
  courses_table = doc.css('table[border="1"]').last
  rows = courses_table.css('tr:not(:first-child)')

  rows.each_with_index do |row, i|
    serial_number = row.css('td')[0].text.strip # 流水號
    target = row.css('td')[1].text.strip # 授課對象
    course_number = row.css('td')[2].text.strip # 課號
    # 班次的英文到底怎麼說，然後班次到底是啥...
    order = row.css('td')[3].text.strip
    course_name = row.css('td')[4].text.strip
    detail_url = row.css('td')[4].css('a')[0]['href']
    begin
      credits = Integer row.css('td')[5].text.strip
    rescue Exception => e
      credits = row.css('td')[5].text.strip
    end
      
    course_id = row.css('td')[6].text.strip # 課程識別碼
    full_semester = row.css('td')[7].text.strip == '全年'
    required = row.css('td')[8].text.strip == '必修'
    lecturer = row.css('td')[9].text.strip
    take_option = row.css('td')[10].text.strip

    time_loc = {}
    match = row.css('td')[11].text.strip.scan(/[一二三四五六][\dABCD@]+/)
    locs = row.css('td')[11].text.strip.scan(/\((?<loc>[^\(\)]+)\)/)
    locs_link = !row.css('td')[11].css('a').empty? ? row.css('td')[11].css('a').map {|k| k['href']} : Array.new(match.length) { nil }
    (0..match.length-1).each do |i|
      begin
        time_loc.merge!({
          "#{match[i][0]}" => [match[i][1..-1].split(''), locs[i].first, locs_link[i]]
        })
      rescue
        time_loc = row.css('td')[11].text.strip
      end
    end

    limitations = row.css('td')[12].text.strip
    notes = row.css('td')[13].text.strip
    course_website = !row.css('td')[15].css('a').empty? ? row.css('td')[15].css('a')[0]['href'] : nil

    courses << Course.new({
      :serial_number => serial_number,
      :target => target,
      :number => course_number,
      :order => order,
      :url => detail_url,
      :credits => credits,
      :id => course_id,
      :full_semester => full_semester,
      :required => required,
      :lecturer => lecturer,
      :take_option => take_option,
      :time_location => time_loc,
      :limitations => limitations,
      :note => notes,
      :website => course_website,
      :title => course_name
    }).to_hash

  end
end

File.open('courses.json', 'w') {|f| f.write(JSON.pretty_generate(courses))}
