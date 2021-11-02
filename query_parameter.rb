module QueryParameter
  SEARCH_WORD_TO_QUERY_PARAMETER = {
    '100' => '&calorie_max=1',
    '500' => '&calorie_min=1&calorie_max=2',
    '800' => '&calorie_min=2&calorie_max=3',
    '上限なし' => 'calorie_min=0&calorie_max=0',
    '15分以内' => '&timeclass=1',
    '30分以内' => '&timeclass=2',
    '1時間以内' => '&timeclass=3',
    '1時間以上' => '&timeclass=4',
    '和食' => '&genre%5B%5D=1',
    '洋食' => '&genre%5B%5D=2',
    '中国料理' => '&genre%5B%5D=3',
    '韓国料理' => '&genre%5B%5D=4',
    'エスニック料理' => '&genre%5B%5D=5',
    'その他の料理' => '&genre%5B%5D=6',
    'イタリア料理' => '&genre%5B%5D=7',
    'フランス料理' => '&genre%5B%5D=8',
    '主菜' => 'cate%5B%5D=2',
    '副菜' => 'cate%5B%5D=3',
    '丼' => 'cate%5B%5D=4',
    'スープ' => 'cate%5B%5D=5',
    'デザート' => 'cate%5B%5D=6',
    '保存食' => 'cate%5B%5D=7',
    '麺' => 'cate%5B%5D=8',
    '弁当' => 'cate%5B%5D=9'
  }.freeze
end
