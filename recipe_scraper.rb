require 'nokogiri'
require 'open-uri'
require 'csv'
require_relative 'exceptions'
require_relative 'query_parameter'

class RecipeScraper
  include QueryParameter
  include Exceptions

  BASE_URL = 'https://www.kyounoryouri.jp'.freeze
  URL_FRAGMENT = '/search/recipe?'.freeze
  FILE_PATH = './stocked_ingredients.csv'.freeze

  def self.usage
    <<~USAGE
      コマンドライン引数に検索条件を渡すと、条件に合う上位人気5番目までのレシピのタイトル、材料、ページurlを返します。
      また、'./stocked_ingredients.csv'に所持している食材を記述しておくと買い足しが必要な材料を抽出できます。
      検索条件は以下から1つ以上選んでください。
      カロリー{(100 500 800 上限なし)のいずれか1つ。重複不可}
      所要時間{(15分以内 30分以内 1時間以内 1時間以上)のいずれか1つ。重複不可}
      料理ジャンル{(和食 洋食 中国料理 韓国料理 エスニック料理 イタリア料理 フランス料理 その他の料理)からいくつでも選択可能}
      カテゴリ{(主菜 副菜 丼 スープ デザート 保存食 麺 弁当)からいくつでも選択可能}
      フリーワード{(豚肉 簡単 あっさり)などの上記以外のフリーキーワードで検索することもできます}
    USAGE
  end

  def initialize(search_words)
    @search_words = search_words
    @scraped_recipe = { titles: [], ingredients: [], urls: [] }
  end

  def run
    scrape_recipe_detail
    display_formatted_recipe
  end

  def scrape_recipe_detail
    generate_recipe_detail_urls.each do |recipe_detail_url|
      sleep 2
      html = Nokogiri::HTML(URI.parse(recipe_detail_url).open)
      @scraped_recipe[:titles].push(html.xpath('normalize-space(//h1/text())'))
      @scraped_recipe[:urls].push(html.xpath('//link[@rel="canonical"]/@href').text)
      @scraped_recipe[:ingredients]
        .push(
          html
          .xpath('//div[@id= "ingredients_list"]//dt/a/text()|//span[@class="ingredient"]/text()')
          .text
        )
    end
  end

  def display_formatted_recipe
    @scraped_recipe[:titles].each_index do |index|
      puts <<~TEXT
        -----------------------------------------------------------------------
        レシピ名: #{@scraped_recipe[:titles][index]}
        必要な食材: #{format_recipe_ingredients[index].join('、')}
        \e[31m足りない食材: #{filter_out_of_stock_ingredients[index].join('、')}\e[0m
        詳細url: #{@scraped_recipe[:urls][index]}
        -----------------------------------------------------------------------
      TEXT
    end
  end

  private

  def generate_recipe_detail_urls
    scrape_recipe_detail_urls.map do |recipe_detail_url|
      BASE_URL +
        recipe_detail_url.to_s.match(%r{(.+recipe/\d+_).+html})[1] +
        URI.encode_www_form_component(recipe_detail_url.to_s.match(%r{.+recipe/\d+_(.+).html})[1])
    end
  end

  def scrape_recipe_detail_urls
    Nokogiri::HTML(URI.parse(generate_recipe_list_url).open)
      .xpath('//div[@class="mk-tab-contents"]/div[position()<6]//div[@class="recipe-name"]//@href')
  rescue OpenURI::HTTPError
    raise SearchWordError, '検索条件に一致するレシピが見つかりません'
  end

  def generate_recipe_list_url
    BASE_URL +
      URL_FRAGMENT +
      generate_query_parameter_of_not_free_words.join +
      generate_query_parameter_of_free_words
  end

  def generate_query_parameter_of_not_free_words
    (@search_words & SEARCH_WORD_TO_QUERY_PARAMETER.keys).map do |not_free_word|
      SEARCH_WORD_TO_QUERY_PARAMETER[not_free_word]
    end
  end

  def generate_query_parameter_of_free_words
    "&keyword=#{encode_free_words.join(' ')}"
  end

  def encode_free_words
    (@search_words - SEARCH_WORD_TO_QUERY_PARAMETER.keys).map do |free_word|
      URI.encode_www_form_component(free_word)
    end
  end

  def filter_out_of_stock_ingredients
    format_recipe_ingredients.map { |ingredients| ingredients - CSV.read(FILE_PATH).first }
  end

  def format_recipe_ingredients
    @scraped_recipe[:ingredients].map { |ingredients| ingredients.split('・').reject(&:empty?) }
  end
end

if __FILE__ == $PROGRAM_NAME
  raise Exceptions::CommandError, '検索条件を一つ以上指定してください。詳細はhelpコマンドを参照してください。' if ARGV[0].nil?
  return puts RecipeScraper.usage if ARGV[0] == 'help'

  recipe_scraper = RecipeScraper.new(ARGV)
  recipe_scraper.run
end
