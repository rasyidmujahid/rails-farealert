require 'rubygems'
# require 'rufus-scheduler'
require 'typhoeus'
require 'json'
require 'rest-client'

class FareAlert

  def self.mail(subject, content, url)
    content = content << url
    RestClient.post "https://api:key-ea97485c76bc0e36001cdee9e1c3e39b"\
      "@api.mailgun.net/v2/sandboxb9a901866608419ba19bd15fa02bb04b.mailgun.org/messages",
      :from => "Fare Alert <postmaster@sandboxb9a901866608419ba19bd15fa02bb04b.mailgun.org>",
      :to => "Abdurrasyid Mujahid <rasyidmujahid@gmail.com>",
      :subject => subject,
      :text => content
  end

  def self.push_over(subject, content, url)
    RestClient.post "https://api.pushover.net/1/messages.json",
      :token => 'aa4yHQaBDD7qDGbFpXcCe73t1gAZLi',
      :user => 'uL8TXDctEPWM5XTLf8p6R6Lu7Dpsi3',
      :message => content,
      :title => subject,
      :url => url
  end

  def self.get_kimono(departure)
    kimoni = 'https://www.kimonolabs.com/api/c7g15x2y?apikey=5f75d647c47709b5398f763bedab0e86'
    url = "#{kimoni}&dt=#{departure}.NA"
    p url

    request = Typhoeus::Request.new(url, :followlocation => true)

    request.on_complete do |response|
      if response.success?
        data = JSON.parse(response.response_body)
        title    = data['name']
        lastdate = data['lastsuccess']

        data['results']['collection1'].each_with_index do |fare, index|
          unless fare['maskapai'].empty?
            yield "#{index+1}. #{fare['maskapai']} #{fare['waktu'].join('-')} #{fare['harga'].join}"
          end
        end
      elsif response.timed_out?
        yield 'Response timed out'
      elsif response.code == 0
        yield "Could not get an http response: #{response.return_message}"
      else
        yield "HTTP request failed: #{response.code.to_s}"
      end
    end

    request.run
  end

  def self.perform
    %w(14-07-2015 15-07-2015 16-07-2015).each do |departure|
      url = "http://www.traveloka.com/fullsearch?ap=CGK.SUB&dt=#{departure}.NA&ps=1.0.0"
      title   = "#{departure} CGK-SUB Alert #{DateTime.now.strftime '%d-%m-%Y %H:%M:%S'}"

      content = []
      get_kimono(departure) { |price| content << price }
      push_over(title, content, url)
    end
  end

  def self.start!
    scheduler = Rufus::Scheduler.new
    scheduler.every '2h' do
      perform
    end
    scheduler.in '2s' do
      perform
    end
    # join the scheduler to the main thread
    scheduler.join
  end

end
