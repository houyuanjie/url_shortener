# frozen_string_literal: true

require_relative 'lib/url_shortener'
require 'sinatra'

url_shortener = UrlShortener.new

get '/' do
  erb :index
end

post '/shorten' do
  url = params['url'].to_s

  if url.strip.empty?
    @error = '请输入有效的 URL 地址'
    return erb :index
  end

  # 验证用户输入链接的有效性
  begin
    unless url.start_with?('https://', 'http://')
      @error = 'URL 必须以 https:// 或 http:// 开头'
      return erb :index
    end

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
      @error = 'URL 必须是一个有效的 https 或 http 链接'
      return erb :index
    end

    host = uri.host
    unless host && !host.strip.empty?
      @error = 'URL 必须包含有效的主机名'
      return erb :index
    end
  rescue URI::InvalidURIError
    @error = '无效的 URL 格式，请检查后重试'
    return erb :index
  end

  short_code = url_shortener.shorten(url)
  @shorten_url = "#{request.base_url}/#{short_code}"

  erb :result
end

get '/:code' do
  code = params['code'].to_s

  original_url = url_shortener.expand(code)
  unless original_url
    @error = '短链接不存在或已过期'
    status 404
    return erb :index
  end

  redirect original_url, 301
end
